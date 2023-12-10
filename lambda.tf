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

resource "aws_lambda_event_source_mapping" "sqs_esm" {
  event_source_arn = aws_sqs_queue.storage_queue.arn
  function_name    = aws_lambda_function.sqs-ddb.arn
}

data "archive_file" "sqs-ddb" {
  type        = "zip"
  source_file = "${path.module}/functions/go/sqs-ddb/Handler"
  output_path = "${path.module}/functions/archive/sqs-ddb.zip"
}
