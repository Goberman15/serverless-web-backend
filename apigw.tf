resource "aws_apigatewayv2_api" "apigw" {
  name          = "sls_web_api"
  protocol_type = "HTTP"
  tags          = local.tags
}

resource "aws_apigatewayv2_route" "post_order" {
  api_id    = aws_apigatewayv2_api.apigw.id
  route_key = "POST /order"
  target    = "integrations/${aws_apigatewayv2_integration.sqs_integration.id}"
}

resource "aws_apigatewayv2_stage" "dev" {
  api_id = aws_apigatewayv2_api.apigw.id
  name   = "dev"
}

resource "aws_apigatewayv2_integration" "sqs_integration" {
  api_id              = aws_apigatewayv2_api.apigw.id
  integration_type    = "AWS_PROXY"
  integration_subtype = "SQS-SendMessage"
  credentials_arn     = aws_iam_role.api_gw_sqs.arn

  request_parameters = {
    QueueUrl    = aws_sqs_queue.storage_queue.id
    MessageBody = "$request.body"
  }
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id = aws_apigatewayv2_api.apigw.id

  lifecycle {
    create_before_destroy = true
  }
}