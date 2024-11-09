
resource "aws_s3_bucket" "ui_bucket" {
  bucket        = format("%s-ui", local.name)
  force_destroy = true
}

resource "aws_s3_bucket_ownership_controls" "ui_bucket" {
  bucket = aws_s3_bucket.ui_bucket.id
  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "ui_bucket" {
  bucket                  = aws_s3_bucket.ui_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "ui_bucket_policy" {
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
    resources = [aws_s3_bucket.ui_bucket.arn]
    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values = [
        "false",
      ]
    }
  }
  statement {
    sid    = "AllowCloudFrontPrivateContent"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    principals {
      type = "AWS"
      identifiers = [
        aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn
      ]
    }
    resources = formatlist("arn:aws:s3:::%s/*", aws_s3_bucket.ui_bucket.id)
  }
}

resource "aws_s3_bucket_policy" "ui_bucket_policy" {
  bucket = aws_s3_bucket.ui_bucket.id
  policy = data.aws_iam_policy_document.ui_bucket_policy.json
}

data "aws_iam_policy_document" "ui_bucket_access" {
  statement {
    sid    = "BucketList"
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [aws_s3_bucket.ui_bucket.arn]
  }
  statement {
    sid    = "BucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [format("%s/*", aws_s3_bucket.ui_bucket.arn)]
  }
}

resource "aws_iam_policy" "ui_bucket_access" {
  name   = format("%s-access", aws_s3_bucket.ui_bucket.id)
  policy = data.aws_iam_policy_document.ui_bucket_access.json
}