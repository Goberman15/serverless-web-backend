resource "aws_dynamodb_table" "order_table" {
  name         = "Order_Table"
  hash_key     = "orderID"
  billing_mode = "PAY_PER_REQUEST"

  attribute {
    name = "orderID"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  tags = local.tags
}
