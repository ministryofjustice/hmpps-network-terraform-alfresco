############################################
# CREATE LB FOR INGRESS NODE
############################################

# elb

resource "aws_elb" "mon_lb" {
  name            = "${local.common_name}-mon"
  subnets         = ["${local.private_subnet_ids}"]
  security_groups = ["${local.lb_security_groups}"]
  internal        = true

  cross_zone_load_balancing   = "${var.cross_zone_load_balancing}"
  idle_timeout                = "${var.idle_timeout}"
  connection_draining         = "${var.connection_draining}"
  connection_draining_timeout = "${var.connection_draining_timeout}"

  listener {
    instance_port     = 9200
    instance_protocol = "http"
    lb_port           = 9200
    lb_protocol       = "http"
  }

  listener {
    instance_port     = 2514
    instance_protocol = "tcp"
    lb_port           = 2514
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 5601
    instance_protocol = "http"
    lb_port           = 5601
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 5601
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${local.certificate_arn}"
  }

  access_logs = {
    bucket        = "${module.s3_lb_logs_bucket.s3_bucket_name}"
    bucket_prefix = "${local.common_name}-mon"
    interval      = 60
  }

  health_check = [
    {
      target              = "HTTP:9200/_cat/health"
      interval            = 30
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
    },
  ]

  tags = "${merge(local.tags, map("Name", format("%s", "${local.common_name}-mon")))}"
}

############################################
# CREATE LOG GROUPS FOR CONTAINER LOGS
############################################

locals {
  service_type = "monitoring"
  registry_url = "mojdigitalstudio"
  docker_tag   = "latest"
}

module "mon_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${local.common_name}"
  loggroupname             = "${local.service_type}"
  cloudwatch_log_retention = "${var.cloudwatch_log_retention}"
  tags                     = "${local.tags}"
}

module "kibana_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${local.common_name}"
  loggroupname             = "kibana"
  cloudwatch_log_retention = "${var.cloudwatch_log_retention}"
  tags                     = "${local.tags}"
}

module "logstash_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${local.common_name}"
  loggroupname             = "logstash"
  cloudwatch_log_retention = "${var.cloudwatch_log_retention}"
  tags                     = "${local.tags}"
}

module "redis_loggroup" {
  source                   = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//cloudwatch//loggroup"
  log_group_path           = "${local.common_name}"
  loggroupname             = "redis"
  cloudwatch_log_retention = "${var.cloudwatch_log_retention}"
  tags                     = "${local.tags}"
}

############################################
# CREATE ECS TASK DEFINTIONS
############################################

data "aws_ecs_task_definition" "mon_task_definition" {
  task_definition = "${aws_ecs_task_definition.mon_task_definition.family}"
  depends_on      = ["aws_ecs_task_definition.mon_task_definition"]
}

data "template_file" "mon_task_definition" {
  template = "${file("./task_definitions/monitoring.conf")}"

  vars {
    environment       = "${local.environment}"
    image_url         = "${local.image_url}"
    log_group_name    = "${module.mon_loggroup.loggroup_name}"
    kibana_loggroup   = "${module.kibana_loggroup.loggroup_name}"
    logstash_loggroup = "${module.logstash_loggroup.loggroup_name}"
    redis_loggroup    = "${module.redis_loggroup.loggroup_name}"
    log_group_region  = "${local.region}"
    memory            = "${var.es_ecs_memory}"
    cpu_units         = "${var.es_ecs_cpu_units}"
    es_jvm_heap_size  = "${var.es_jvm_heap_size}"
    mem_limit         = "${var.es_ecs_mem_limit}"
    registry_url      = "${local.registry_url}"
    docker_tag        = "${local.docker_tag}"
    efs_mount_path    = "${local.efs_mount_path}"
  }
}

resource "aws_ecs_task_definition" "mon_task_definition" {
  family                = "${local.common_name}-${local.service_type}"
  container_definitions = "${data.template_file.mon_task_definition.rendered}"

  volume {
    name      = "confd"
    host_path = "${local.es_home_dir}/conf.d/elasticsearch.yml.tmpl"
  }

  volume {
    name      = "backup"
    host_path = "${local.efs_mount_path}"
  }

  volume {
    name      = "data"
    host_path = "${local.es_home_dir}/data"
  }
}

############################################
# CREATE ECS SERVICES
############################################

module "mon_service" {
  source                          = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//ecs/ecs_service//withloadbalancer//elb"
  servicename                     = "${local.common_name}-${local.service_type}"
  clustername                     = "${module.ecs_cluster.ecs_cluster_id}"
  ecs_service_role                = "${module.create-iam-ecs-role-int.iamrole_arn}"
  task_definition_family          = "${aws_ecs_task_definition.mon_task_definition.family}"
  task_definition_revision        = "${aws_ecs_task_definition.mon_task_definition.revision}"
  current_task_definition_version = "${data.aws_ecs_task_definition.mon_task_definition.revision}"
  service_desired_count           = "1"
  elb_name                        = "${aws_elb.mon_lb.name}"
  containername                   = "${local.application}"
  containerport                   = "${local.containerport}"
}

#-------------------------------------------------------------
### Create ecs  
#-------------------------------------------------------------

data "template_file" "userdata_mon" {
  template = "${file("./userdata/monitoring.sh")}"

  vars {
    app_name             = "${local.application}"
    bastion_inventory    = "${local.bastion_inventory}"
    env_identifier       = "${local.environment_identifier}"
    short_env_identifier = "${local.short_environment_identifier}"
    environment_name     = "${var.environment_name}"
    private_domain       = "${local.internal_domain}"
    account_id           = "${local.account_id}"
    internal_domain      = "${local.internal_domain}"
    environment          = "${local.environment}"
    common_name          = "${local.common_name}"
    es_cluster_name      = "${local.common_name}"
    ecs_cluster          = "${module.ecs_cluster.ecs_cluster_name}"
    efs_dns_name         = "${module.efs_backups.dns_cname}"
    efs_mount_path       = "${local.efs_mount_path}"
    es_home_dir          = "${local.es_home_dir}"
    es_master_nodes      = "${var.es_master_nodes}"
  }
}

############################################
# CREATE LAUNCH CONFIG FOR EC2 RUNNING SERVICES
############################################

module "mon_launch_cfg" {
  source                      = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//launch_configuration//blockdevice"
  launch_configuration_name   = "${local.common_name}-mon"
  image_id                    = "${data.aws_ami.ecs_ami.id}"
  instance_type               = "${var.es_instance_type}"
  volume_size                 = "30"
  instance_profile            = "${module.create-iam-instance-profile-es.iam_instance_name}"
  key_name                    = "${local.ssh_deployer_key}"
  ebs_device_name             = "/dev/xvdb"
  ebs_encrypted               = "true"
  ebs_volume_size             = "20"
  ebs_volume_type             = "standard"
  associate_public_ip_address = false
  security_groups             = ["${local.instance_security_groups}"]
  user_data                   = "${data.template_file.userdata_mon.rendered}"
}

# ############################################
# # CREATE AUTO SCALING GROUP
# ############################################

#AZ1
module "mon_az1" {
  source               = "git::https://github.com/ministryofjustice/hmpps-terraform-modules.git?ref=master//modules//autoscaling//group//asg_classic_lb"
  asg_name             = "${local.common_name}-mon-az1"
  subnet_ids           = ["${local.private_subnet_ids[0]}"]
  asg_min              = 1
  asg_max              = 1
  asg_desired          = 1
  launch_configuration = "${module.mon_launch_cfg.launch_name}"
  load_balancers       = ["${aws_elb.mon_lb.name}"]
  tags                 = "${local.ecs_tags}"
}

# ############################################
# ROUTE53
# ############################################
resource "aws_route53_record" "internal_monitoring_dns" {
  name    = "${local.server_dns}.${local.internal_domain}"
  type    = "A"
  zone_id = "${local.private_zone_id}"

  alias {
    evaluate_target_health = false
    name                   = "${aws_elb.mon_lb.dns_name}"
    zone_id                = "${aws_elb.mon_lb.zone_id}"
  }
}

resource "aws_route53_record" "external_monitoring_dns" {
  zone_id = "${local.public_zone_id}"
  name    = "${local.server_dns}.${local.external_domain}"
  type    = "A"

  alias {
    evaluate_target_health = false
    name                   = "${aws_elb.mon_lb.dns_name}"
    zone_id                = "${aws_elb.mon_lb.zone_id}"
  }
}
