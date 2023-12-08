resource "aws_cloudwatch_log_group" "apigw_dev_log_group" {
  name              = "/aws/apigw/dev/project/${local.project_name}"
  retention_in_days = 3
  skip_destroy      = true
  tags              = local.tags
}

resource "aws_cloudwatch_log_group" "sqs_ddb_log_group" {
  name              = "/aws/lambda/${local.sqs_ddb_function_name}"
  retention_in_days = 3
  skip_destroy      = true
  tags              = local.tags
}