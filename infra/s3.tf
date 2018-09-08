resource "aws_s3_bucket" "bucket" {
  bucket                    = "${var.s3_bucket_name}"
  region                    = "${var.aws_region}"
  request_payer             = "BucketOwner"
  force_destroy             = true
  replication_configuration = []
  logging                   = []

  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }

  versioning {
    enabled    = false
    mfa_delete = false
  }
}

data "template_file" "login" {
  template = "${file("${path.module}/templates/403.html")}"

  vars {
    redirect_url = "${local.cognito_login_url}"
  }
}

resource "aws_s3_bucket_object" "403" {
  bucket                 = "${var.s3_bucket_name}"
  key                    = "errors/403.html"
  content                = "${data.template_file.login.rendered}"
  content_type           = "text/html"
  server_side_encryption = "AES256"
}

resource "aws_s3_bucket_object" "404" {
  bucket                 = "${var.s3_bucket_name}"
  key                    = "errors/404.html"
  source                 = "templates/404.html"
  content_type           = "text/html"
  server_side_encryption = "AES256"
}

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }

  statement {
    actions   = ["s3:ListBucket"]
    resources = ["${aws_s3_bucket.bucket.arn}"]

    principals {
      type        = "AWS"
      identifiers = ["${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}"]
    }
  }
}

resource "aws_s3_bucket_policy" "my_bucket_policy" {
  bucket = "${var.s3_bucket_name}"
  policy = "${data.aws_iam_policy_document.s3_bucket_policy.json}"
}
