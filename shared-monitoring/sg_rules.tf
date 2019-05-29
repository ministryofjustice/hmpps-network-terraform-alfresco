#-------------------------------------------------------------
### Security groups
#-------------------------------------------------------------

locals {
  sg_monitoring_elb    = "${data.terraform_remote_state.security-groups.sg_monitoring_elb}"
  sg_monitoring_inst   = "${data.terraform_remote_state.security-groups.sg_monitoring}"
  sg_elasticsearch     = "${data.terraform_remote_state.security-groups.sg_elasticsearch}"
  sg_monitoring_client = "${data.terraform_remote_state.security-groups.sg_monitoring_client}"
  sg_mon_efs           = "${data.terraform_remote_state.security-groups.sg_mon_efs}"
  sg_mon_jenkins       = "${data.terraform_remote_state.security-groups.sg_mon_jenkins}"
}

# lb
resource "aws_security_group_rule" "sg_monitoring_elb_http_lb_in" {
  from_port                = "9200"
  to_port                  = "9200"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_client}"
  type                     = "ingress"
  security_group_id        = "${local.sg_monitoring_elb}"
  description              = "${var.environment_identifier}-elasticsearch-http"
}

resource "aws_security_group_rule" "sg_monitoring_elb_kibana_lb_in" {
  from_port                = "5601"
  to_port                  = "5601"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_client}"
  type                     = "ingress"
  security_group_id        = "${local.sg_monitoring_elb}"
  description              = "${var.environment_identifier}-elasticsearch-http"
}

resource "aws_security_group_rule" "sg_monitoring_elb_kibana_https_in" {
  from_port         = "443"
  to_port           = "443"
  protocol          = "tcp"
  cidr_blocks       = ["${local.cidr_block}"]
  type              = "ingress"
  security_group_id = "${local.sg_monitoring_elb}"
  description       = "${var.environment_identifier}-elasticsearch-http"
}

resource "aws_security_group_rule" "sg_monitoring_http_lb_out" {
  security_group_id        = "${local.sg_monitoring_elb}"
  type                     = "egress"
  from_port                = "9200"
  to_port                  = "9200"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_elasticsearch}"
  description              = "${var.environment_identifier}-es-http"
}

resource "aws_security_group_rule" "sg_monitoring_elb_logstash_lb_in" {
  from_port                = "2514"
  to_port                  = "2514"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_client}"
  type                     = "ingress"
  security_group_id        = "${local.sg_monitoring_elb}"
  description              = "${var.environment_identifier}-elasticsearch-http"
}

resource "aws_security_group_rule" "sg_monitoring_elb_logstash_alt_lb_in" {
  from_port                = "9600"
  to_port                  = "9600"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_client}"
  type                     = "ingress"
  security_group_id        = "${local.sg_monitoring_elb}"
  description              = "${var.environment_identifier}-elasticsearch-http"
}

resource "aws_security_group_rule" "sg_monitoring_logstash_out" {
  security_group_id        = "${local.sg_monitoring_elb}"
  type                     = "egress"
  from_port                = "2514"
  to_port                  = "2514"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_inst}"
  description              = "${var.environment_identifier}-es-http"
}

resource "aws_security_group_rule" "sg_monitoring_kibana_out" {
  security_group_id        = "${local.sg_monitoring_elb}"
  type                     = "egress"
  from_port                = "5601"
  to_port                  = "5601"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_inst}"
  description              = "${var.environment_identifier}-es-http"
}

resource "aws_security_group_rule" "sg_monitoring_http_lb_out_inst" {
  security_group_id        = "${local.sg_monitoring_elb}"
  type                     = "egress"
  from_port                = "9200"
  to_port                  = "9200"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_inst}"
  description              = "${var.environment_identifier}-es-http"
}

# es instance
resource "aws_security_group_rule" "sg_monitoring_http_from_lb_in" {
  from_port                = "9200"
  to_port                  = "9200"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  type                     = "ingress"
  security_group_id        = "${local.sg_elasticsearch}"
  description              = "${var.environment_identifier}-elasticsearch-http"
}

resource "aws_security_group_rule" "sg_monitoring_inst_in" {
  from_port                = "9200"
  to_port                  = "9200"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_inst}"
  type                     = "ingress"
  security_group_id        = "${local.sg_elasticsearch}"
  description              = "${var.environment_identifier}-elasticsearch-http"
}

resource "aws_security_group_rule" "sg_monitoring_inst_alt_in" {
  from_port                = "9300"
  to_port                  = "9300"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_inst}"
  type                     = "ingress"
  security_group_id        = "${local.sg_elasticsearch}"
  description              = "${var.environment_identifier}-elasticsearch-http"
}

resource "aws_security_group_rule" "elasticsearch_http" {
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = "${local.sg_elasticsearch}"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  count             = "${var.sg_create_outbound_web_rules}"
}

resource "aws_security_group_rule" "elasticsearch_https" {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "${local.sg_elasticsearch}"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  count             = "${var.sg_create_outbound_web_rules}"
}

# monitoring

resource "aws_security_group_rule" "sg_monitoring_http_lb_in_inst" {
  security_group_id        = "${local.sg_monitoring_inst}"
  type                     = "ingress"
  from_port                = "9200"
  to_port                  = "9200"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  description              = "${var.environment_identifier}-es-http"
}

resource "aws_security_group_rule" "sg_monitoring_kibana_in_inst" {
  security_group_id        = "${local.sg_monitoring_inst}"
  type                     = "ingress"
  from_port                = "5601"
  to_port                  = "5601"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  description              = "${var.environment_identifier}-es-http"
}

resource "aws_security_group_rule" "sg_monitoring_logstash_in_inst" {
  security_group_id        = "${local.sg_monitoring_inst}"
  type                     = "ingress"
  from_port                = "2514"
  to_port                  = "2514"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  description              = "${var.environment_identifier}-es-http"
}

resource "aws_security_group_rule" "sg_monitoring_logstash_in_alt" {
  security_group_id        = "${local.sg_monitoring_inst}"
  type                     = "ingress"
  from_port                = "9600"
  to_port                  = "9600"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  description              = "${var.environment_identifier}-es-http"
}

resource "aws_security_group_rule" "monitoring_rsyslog_udp_in" {
  from_port                = 2514
  protocol                 = "udp"
  to_port                  = 2514
  description              = "${var.environment_identifier}-rsyslog-udp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  type                     = "ingress"
  security_group_id        = "${local.sg_monitoring_inst}"
}

resource "aws_security_group_rule" "monitoring_logstash_tcp_in" {
  from_port                = 5000
  protocol                 = "tcp"
  to_port                  = 5000
  description              = "${var.environment_identifier}-logstash-tcp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  type                     = "ingress"
  security_group_id        = "${local.sg_monitoring_inst}"
}

resource "aws_security_group_rule" "monitoring_logstash_udp_in" {
  from_port                = 5000
  protocol                 = "udp"
  to_port                  = 5000
  description              = "${var.environment_identifier}-logstash-udp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  type                     = "ingress"
  security_group_id        = "${local.sg_monitoring_inst}"
}

resource "aws_security_group_rule" "monitoring_sg_es_self_in" {
  from_port         = 0
  protocol          = -1
  security_group_id = "${local.sg_monitoring_inst}"
  to_port           = 0
  type              = "ingress"
  self              = true
}

resource "aws_security_group_rule" "monitoring_sg_es_self_out" {
  from_port         = 0
  protocol          = -1
  security_group_id = "${local.sg_monitoring_inst}"
  to_port           = 0
  type              = "egress"
  self              = true
}

resource "aws_security_group_rule" "monitoring_sg_es_http" {
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = "${local.sg_monitoring_inst}"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  count             = "${var.sg_create_outbound_web_rules}"
}

resource "aws_security_group_rule" "monitoring_sg_es_https" {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "${local.sg_monitoring_inst}"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  count             = "${var.sg_create_outbound_web_rules}"
}

resource "aws_security_group_rule" "elasticsearch_self_in" {
  from_port         = 0
  protocol          = -1
  security_group_id = "${local.sg_elasticsearch}"
  to_port           = 0
  type              = "ingress"
  self              = true
}

resource "aws_security_group_rule" "elasticsearch_self_out" {
  from_port         = 0
  protocol          = -1
  security_group_id = "${local.sg_elasticsearch}"
  to_port           = 0
  type              = "egress"
  self              = true
}

# client
resource "aws_security_group_rule" "monitoring_rsyslog_tcp_out" {
  from_port                = 2514
  protocol                 = "tcp"
  to_port                  = 2514
  description              = "${var.environment_identifier}-rsyslog-tcp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  type                     = "egress"
  security_group_id        = "${local.sg_monitoring_client}"
}

resource "aws_security_group_rule" "monitoring_rsyslog_udp_out" {
  from_port                = 2514
  protocol                 = "udp"
  to_port                  = 2514
  description              = "${var.environment_identifier}-rsyslog-udp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  type                     = "egress"
  security_group_id        = "${local.sg_monitoring_client}"
}

resource "aws_security_group_rule" "monitoring_logstash_tcp_out" {
  from_port                = 5000
  protocol                 = "tcp"
  to_port                  = 5000
  description              = "${var.environment_identifier}-logstash-tcp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  type                     = "egress"
  security_group_id        = "${local.sg_monitoring_client}"
}

resource "aws_security_group_rule" "monitoring_logstash_udp_out" {
  from_port                = 5000
  protocol                 = "udp"
  to_port                  = 5000
  description              = "${var.environment_identifier}-logstash-udp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  type                     = "egress"
  security_group_id        = "${local.sg_monitoring_client}"
}

resource "aws_security_group_rule" "monitoring_kibana_tcp_out" {
  from_port                = "5601"
  to_port                  = "5601"
  protocol                 = "tcp"
  description              = "${var.environment_identifier}-kibana"
  source_security_group_id = "${local.sg_monitoring_elb}"
  type                     = "egress"
  security_group_id        = "${local.sg_monitoring_client}"
}

resource "aws_security_group_rule" "sg_monitoring_logstash_alt_tcp_out" {
  from_port                = "9600"
  to_port                  = "9600"
  protocol                 = "tcp"
  source_security_group_id = "${local.sg_monitoring_elb}"
  type                     = "egress"
  security_group_id        = "${local.sg_monitoring_client}"
  description              = "${var.environment_identifier}-logstash"
}

# efs
resource "aws_security_group_rule" "efs_self_in" {
  from_port         = 0
  protocol          = -1
  security_group_id = "${local.sg_mon_efs}"
  to_port           = 0
  type              = "ingress"
  self              = true
}

resource "aws_security_group_rule" "efs_self_out" {
  from_port         = 0
  protocol          = -1
  security_group_id = "${local.sg_mon_efs}"
  to_port           = 0
  type              = "egress"
  self              = true
}

# jenkins slave acess 
resource "aws_security_group_rule" "sg_monitoring_jenkins_slave_docker_tls" {
  from_port         = "2376"
  to_port           = "2376"
  protocol          = "tcp"
  cidr_blocks       = ["${local.eng_vpc_cidr}"]
  type              = "ingress"
  security_group_id = "${local.sg_mon_jenkins}"
  description       = "${var.environment_identifier}-jenkins_slave_access"
}
