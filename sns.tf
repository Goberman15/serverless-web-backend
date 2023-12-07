resource "aws_sns_topic" "downstream_topic" {
  name = "DownstreamTopic"
}

resource "aws_sns_topic_policy" "downstream_topic_policy" {
  arn    = aws_sns_topic.downstream_topic.arn
  policy = data.aws_iam_policy_document.sns_policy.json
}

data "aws_iam_policy_document" "sns_policy" {
  statement {
    effect = "Allow"
    actions = [
      "SNS:Publish",
      "SNS:RemovePermission",
      "SNS:SetTopicAttributes",
      "SNS:DeleteTopic",
      "SNS:ListSubscriptionsByTopic",
      "SNS:GetTopicAttributes",
      "SNS:AddPermission",
      "SNS:Subscribe"
    ]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.me.account_id]
    }
    resources = [
      aws_sns_topic.downstream_topic.arn
    ]
    condition {
      test     = "StringEquals"
      variable = "AWS:SourceOwner"
      values   = [data.aws_caller_identity.me.account_id]
    }
  }

  statement {
    sid    = "PuliblisherStatement"
    effect = "Allow"
    actions = [
      "sns:Publish"
    ]
    resources = [
      aws_sns_topic.downstream_topic.arn
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_role.lambda_ddb_stream_sns.arn
      ]
    }
  }
}
