
resource "random_string" "random" {
  length  = 6
  special = false
  upper   = false
}

resource "aws_s3_bucket" "config_bucket" {
  bucket = format("%s-%s-config", var.name, random_string.random.result)
}

resource "aws_s3_bucket_ownership_controls" "config_bucket" {
  bucket = aws_s3_bucket.config_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "config_bucket" {
  bucket                  = aws_s3_bucket.config_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "config_bucket_policy" {
  statement {
    sid    = "DenyUnSecureCommunications"
    effect = "Deny"
    actions = [
      "s3:*"
    ]
    principals {
      type = "AWS"
      identifiers = [
        "*"
      ]
    }
    resources = [aws_s3_bucket.config_bucket.arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }
  }
}

resource "aws_s3_bucket_policy" "config_bucket_policy" {
  bucket = aws_s3_bucket.config_bucket.id
  policy = data.aws_iam_policy_document.config_bucket_policy.json
}

data "aws_iam_policy_document" "config_bucket_access" {
  statement {
    sid    = "BucketList"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.config_bucket.arn]
  }
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    resources = [format("%s/*", aws_s3_bucket.config_bucket.arn)]
  }
}

resource "aws_iam_policy" "config_bucket_access" {
  name   = format("%s-access", aws_s3_bucket.config_bucket.id)
  policy = data.aws_iam_policy_document.config_bucket_access.json
}