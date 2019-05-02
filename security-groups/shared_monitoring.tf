resource "aws_security_group" "monitoring_sg" {
  name        = "${var.environment_identifier}-monitoring-elk"
  description = "security group for ${var.environment_identifier}-monitoring"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  tags = "${merge(data.terraform_remote_state.vpc.tags, map("Name", "${var.environment_identifier}-monitoring-elk"))}"
}

resource "aws_security_group" "monitoring_elb_sg" {
  name        = "${var.environment_identifier}-monitoring-elk-elb"
  description = "security group for ${var.environment_identifier}-monitoring-elk-elb"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"
  tags        = "${merge(data.terraform_remote_state.vpc.tags, map("Name", "${var.environment_identifier}-monitoring-elk-elb"))}"
}

resource "aws_security_group" "monitoring_client_sg" {
  name        = "${var.environment_identifier}-monitoring-elk-client"
  description = "security group for ${var.environment_identifier}-elasticsearch"
  vpc_id      = "${data.terraform_remote_state.vpc.vpc_id}"

  tags = "${merge(data.terraform_remote_state.vpc.tags, map("Name", "${var.environment_identifier}-monitoring-elk-client"))}"
}

# outputs
output "sg_monitoring" {
  value = "${aws_security_group.monitoring_sg.id}"
}

output "sg_monitoring_elb" {
  value = "${aws_security_group.monitoring_elb_sg.id}"
}

output "sg_monitoring_client" {
  value = "${aws_security_group.monitoring_client_sg.id}"
}