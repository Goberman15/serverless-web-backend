resource "aws_sqs_queue" "storage_queue" {
  name = "StorageQueue"

  visibility_timeout_seconds = 90
  message_retention_seconds  = 86400 // 1 Day
  tags                       = local.tags
}

resource "aws_sqs_queue_policy" "storage_queue_policy" {
  queue_url = aws_sqs_queue.storage_queue.id
  policy    = data.aws_iam_policy_document.sqs_policy.json
}

data "aws_iam_policy_document" "sqs_policy" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:*"
    ]
    resources = [
      aws_sqs_queue.storage_queue.arn
    ]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.me.account_id]
    }
  }

  statement {
    sid = "SenderStatement"
    effect = "Allow"
    actions = [
      "SQS:SendMessage"
    ]
    resources = [
      aws_sqs_queue.storage_queue.arn
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.api_gw_sqs.arn
      ]
    }
  }

  statement {
    sid = "ReceiverStatement"
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [
      aws_sqs_queue.storage_queue.arn
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.lambda_sqs_ddb.arn
      ]
    }
  }
}
