resource "aws_lambda_function" "sqs-ddb" {
  filename         = "${path.module}/functions/archive/sqs-ddb.zip"
  function_name    = local.sqs_ddb_function_name
  role             = aws_iam_role.lambda_sqs_ddb.arn
  handler          = "Handler"
  source_code_hash = data.archive_file.sqs-ddb.output_base64sha256
  runtime          = "go1.x"
  timeout          = 90

  environment {
    variables = {
      table_name = aws_dynamodb_table.order_table.id
    }
  }

  depends_on = [aws_cloudwatch_log_group.sqs_ddb_log_group]

  tags = local.tags
}

resource "aws_lambda_function" "ddb_streams_sns" {
  filename         = "${path.module}/functions/archive/ddb_streams_sns.zip"
  function_name    = local.ddb_streams_sns_function_name
  role             = aws_iam_role.lambda_ddb_stream_sns.arn
  handler          = "Handler"
  source_code_hash = data.archive_file.ddb_streams_sns.output_base64sha256
  runtime          = "go1.x"
  timeout          = 90

  environment {
    variables = {
      topic_arn = aws_sns_topic.downstream_topic.arn
    }
  }

  depends_on = [aws_cloudwatch_log_group.ddb_stream_sns_log_group]

  tags = local.tags
}

resource "aws_lambda_event_source_mapping" "sqs_esm" {
  event_source_arn = aws_sqs_queue.storage_queue.arn
  function_name    = aws_lambda_function.sqs-ddb.arn
}

resource "aws_lambda_event_source_mapping" "ddb_streams_esm" {
  event_source_arn  = aws_dynamodb_table.order_table.stream_arn
  function_name     = aws_lambda_function.ddb_streams_sns.arn
  starting_position = "LATEST"
}

data "archive_file" "sqs-ddb" {
  type        = "zip"
  source_file = "${path.module}/functions/go/sqs-ddb/Handler"
  output_path = "${path.module}/functions/archive/sqs-ddb.zip"
}

data "archive_file" "ddb_streams_sns" {
  type        = "zip"
  source_file = "${path.module}/functions/go/ddb-streams-sns/Handler"
  output_path = "${path.module}/functions/archive/ddb_streams_sns.zip"
}
