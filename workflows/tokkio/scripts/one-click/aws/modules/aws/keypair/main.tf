
resource "aws_key_pair" "this" {
  public_key = var.public_key
  key_name   = var.key_name
}