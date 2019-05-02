#-------------------------------------------------------------
### Security groups
#-------------------------------------------------------------

locals {
  sg_monitoring_elb = "${data.terraform_remote_state.security-groups.sg_monitoring_elb}"
}

resource "aws_security_group_rule" "monitoring_rsyslog_tcp_in" {
  from_port   = 2514
  protocol    = "tcp"
  to_port     = 2514
  description = "${var.environment_identifier}-rsyslog-tcp"

  cidr_blocks = [
    "${local.cidr_block}",
  ]

  type              = "ingress"
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
}

resource "aws_security_group_rule" "monitoring_rsyslog_udp_in" {
  from_port   = 2514
  protocol    = "udp"
  to_port     = 2514
  description = "${var.environment_identifier}-rsyslog-udp"

  cidr_blocks = [
    "${local.cidr_block}",
  ]

  type              = "ingress"
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
}

resource "aws_security_group_rule" "monitoring_logstash_tcp_in" {
  from_port   = 5000
  protocol    = "tcp"
  to_port     = 5000
  description = "${var.environment_identifier}-logstash-tcp"

  cidr_blocks = [
    "${local.cidr_block}",
  ]

  type              = "ingress"
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
}

resource "aws_security_group_rule" "monitoring_logstash_udp_in" {
  from_port   = 5000
  protocol    = "udp"
  to_port     = 5000
  description = "${var.environment_identifier}-logstash-udp"

  cidr_blocks = [
    "${local.cidr_block}",
  ]

  type              = "ingress"
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
}

resource "aws_security_group_rule" "monitoring_kibana_tcp_in" {
  from_port   = "5601"
  to_port     = "5601"
  protocol    = "tcp"
  description = "${var.environment_identifier}-kibana"

  cidr_blocks = [
    "${local.cidr_block}",
  ]

  type              = "ingress"
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
}

resource "aws_security_group_rule" "sg_monitoring_http_in" {
  from_port         = "9200"
  to_port           = "9200"
  protocol          = "tcp"
  cidr_blocks       = ["${local.cidr_block}"]
  type              = "ingress"
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
  description       = "${var.environment_identifier}-elasticsearch-http"
}

resource "aws_security_group_rule" "sg_monitoring_https_in" {
  from_port         = "9300"
  to_port           = "9300"
  protocol          = "tcp"
  cidr_blocks       = ["${local.cidr_block}"]
  type              = "ingress"
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
  description       = "${var.environment_identifier}-elasticsearch-https"
}

resource "aws_security_group_rule" "sg_monitoring_logstash_in" {
  from_port = "9600"
  to_port   = "9600"
  protocol  = "tcp"

  cidr_blocks = [
    "${local.cidr_block}",
  ]

  type              = "ingress"
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
  description       = "${var.environment_identifier}-logstash"
}

resource "aws_security_group_rule" "monitoring_sg_es_self_in" {
  from_port         = 0
  protocol          = -1
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
  to_port           = 0
  type              = "ingress"
  self              = true
}

resource "aws_security_group_rule" "monitoring_sg_es_self_out" {
  from_port         = 0
  protocol          = -1
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
  to_port           = 0
  type              = "egress"
  self              = true
}

resource "aws_security_group_rule" "monitoring_sg_es_http" {
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  count             = "${var.sg_create_outbound_web_rules}"
}

resource "aws_security_group_rule" "monitoring_sg_es_https" {
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  security_group_id = "${data.terraform_remote_state.security-groups.sg_monitoring}"
  type              = "egress"
  cidr_blocks       = ["0.0.0.0/0"]
  count             = "${var.sg_create_outbound_web_rules}"
}
