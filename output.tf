output "remote_state_kms_key_arn" {
  value = "${aws_kms_key.remote_state.arn}"
}

output "remote_state_kms_key_id" {
  value = "${aws_kms_key.remote_state.id}"
}

output "remote_state_s3bucket_id" {
  value = "${module.remote_state.s3_bucket_id}"
}

output "remote_state_dynamodb_table_name" {
  value = "${module.dynamodb-table.aws_dynamodb_table_name}"
}

output "remote_state_dynamodb_table_arn" {
  value = "${module.dynamodb-table.aws_dynamodb_table_arn}"
}
