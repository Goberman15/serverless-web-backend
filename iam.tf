resource "aws_iam_policy" "dynamodb_write_policy" {
  name_prefix = "dynamodb_write_policy"
  policy      = data.aws_iam_policy_document.dynamodb_write_policy_document.json
  tags        = local.tags
}

data "aws_iam_policy_document" "dynamodb_write_policy_document" {
  statement {
    sid    = "DynamoDBWritePolicy071223"
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:DescribeTable"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sns_publish_policy" {
  name_prefix = "sns_publish_policy"
  policy      = data.aws_iam_policy_document.sns_publish_policy_document.json
  tags        = local.tags
}

data "aws_iam_policy_document" "sns_publish_policy_document" {
  statement {
    sid    = "SNSPublishPolicy071223"
    effect = "Allow"
    actions = [
      "sns:Publish",
      "sns:GetTopicAttributes",
      "sns:ListTopics"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "ddb_stream_read_policy" {
  name_prefix = "ddb_stream_read_policy"
  policy      = data.aws_iam_policy_document.ddb_stream_read_policy_document.json
  tags        = local.tags

}

data "aws_iam_policy_document" "ddb_stream_read_policy_document" {
  statement {
    sid    = "DynamoDBStreamReadPolicy071223"
    effect = "Allow"
    actions = [
      "dynamodb:GetShardIterator",
      "dynamodb:DescribeStream",
      "dynamodb:ListStreams",
      "dynamodb:GetRecords"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sqs_read_policy" {
  name_prefix = "sqs_read_policy"
  policy      = data.aws_iam_policy_document.sqs_read_policy_document.json
  tags        = local.tags
}

data "aws_iam_policy_document" "sqs_read_policy_document" {
  statement {
    sid    = "SQSReadPolicy071223"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "sqs_send_message_policy" {
  name_prefix = "sqs_send_message_policy"
  policy = data.aws_iam_policy_document.sqs_send_message_policy_document.json
  tags        = local.tags
}

data "aws_iam_policy_document" "sqs_send_message_policy_document" {
  statement {
    sid    = "SQSSendPolicy081223"
    effect = "Allow"
    actions = [
      "SQS:SendMessage"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy" "lambda_basic_execution_role" {
  arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

data "aws_iam_policy" "apigw_push_cw_logs" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_iam_role" "lambda_sqs_ddb" {
  name_prefix        = "lambda_sqs_ddb_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_document.json
  managed_policy_arns = [
    aws_iam_policy.sqs_read_policy.arn,
    aws_iam_policy.dynamodb_write_policy.arn,
    data.aws_iam_policy.lambda_basic_execution_role.arn
  ]
  tags = local.tags
}

resource "aws_iam_role" "lambda_ddb_stream_sns" {
  name_prefix        = "lambda_ddb_stream_sns_role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_document.json
  managed_policy_arns = [
    aws_iam_policy.ddb_stream_read_policy.arn,
    aws_iam_policy.sns_publish_policy.arn,
    data.aws_iam_policy.lambda_basic_execution_role.arn
  ]
  tags = local.tags
}

resource "aws_iam_role" "api_gw_sqs" {
  name_prefix        = "api_gw_sqs_role"
  assume_role_policy = data.aws_iam_policy_document.apigw_assume_role_policy_document.json
  managed_policy_arns = [
    aws_iam_policy.sqs_send_message_policy.arn,
    data.aws_iam_policy.apigw_push_cw_logs.arn
  ]
  tags = local.tags
}

data "aws_iam_policy_document" "lambda_assume_role_policy_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

data "aws_iam_policy_document" "apigw_assume_role_policy_document" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}
