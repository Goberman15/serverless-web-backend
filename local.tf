locals {
  project_name = "sls-web-backend"
  tags = {
    Project : local.project_name
  }
  sqs_ddb_function_name = "sqs-ddb"
  ddb_streams_sns_function_name = "ddb_stream_sns"
}
