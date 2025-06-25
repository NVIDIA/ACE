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

resource "aws_iam_instance_profile" "instance" {
  name = local.name
  role = aws_iam_role.instance.name
}