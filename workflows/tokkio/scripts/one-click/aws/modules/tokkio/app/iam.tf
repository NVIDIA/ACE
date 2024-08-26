
data "aws_iam_policy_document" "instance" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "instance" {
  name               = local.name
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.instance.json
}

resource "aws_iam_role_policy_attachment" "instance_config_bucket_access" {
  role       = aws_iam_role.instance.name
  policy_arn = var.base_config.config_access_policy_arn
}

resource "aws_iam_role_policy_attachment" "instance_ui_bucket_access" {
  role       = aws_iam_role.instance.name
  policy_arn = aws_iam_policy.ui_bucket_access.arn
}

resource "aws_iam_instance_profile" "instance" {
  name = local.name
  role = aws_iam_role.instance.name
}