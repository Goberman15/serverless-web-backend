output "API_GW_ID" {
  value = aws_apigatewayv2_api.apigw.id
}

output "deployment_ID" {
  value = aws_apigatewayv2_deployment.deployment.id
}