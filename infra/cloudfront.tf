data "aws_acm_certificate" "domain" {
  provider    = "aws.useast1"
  domain      = "${var.website_domain}"
  types       = ["AMAZON_ISSUED"]
  most_recent = true
}

resource "aws_cloudfront_distribution" "distribution" {
  aliases             = ["${var.website_domain}"]
  price_class         = "PriceClass_100"
  retain_on_delete    = "false"
  web_acl_id          = ""
  default_root_object = "index.html"
  enabled             = true
  http_version        = "http2"
  is_ipv6_enabled     = false
  logging_config      = []
  tags                = []

  viewer_certificate {
    acm_certificate_arn            = "${data.aws_acm_certificate.domain.arn}"
    cloudfront_default_certificate = false
    iam_certificate_id             = ""
    minimum_protocol_version       = "TLSv1"
    ssl_support_method             = "sni-only"
  }

  restrictions {
    geo_restriction {
      locations        = []
      restriction_type = "none"
    }
  }

  origin {
    domain_name   = "${aws_api_gateway_rest_api.login.id}.execute-api.${var.aws_region}.amazonaws.com"
    origin_id     = "Login API gateway"
    origin_path   = "/prod"
    custom_header = []

    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_keepalive_timeout = 5
      origin_protocol_policy   = "https-only"
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  origin {
    custom_header        = []
    custom_origin_config = []
    domain_name          = "${aws_s3_bucket.bucket.bucket_domain_name}"
    origin_id            = "S3-${var.s3_bucket_name}"
    origin_path          = ""

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 403
    response_code         = 403
    response_page_path    = "/errors/403.html"
  }

  custom_error_response {
    error_caching_min_ttl = 0
    error_code            = 404
    response_code         = 404
    response_page_path    = "/errors/404.html"
  }

  # Login API endpoint
  # No cache, no auth required
  cache_behavior {
    allowed_methods             = ["GET", "HEAD", "OPTIONS"]
    cached_methods              = ["GET", "HEAD"]
    compress                    = false
    default_ttl                 = 0
    max_ttl                     = 0
    min_ttl                     = 0
    lambda_function_association = []
    path_pattern                = "/api/*"
    smooth_streaming            = false
    target_origin_id            = "Login API gateway"
    trusted_signers             = []
    viewer_protocol_policy      = "https-only"

    forwarded_values {
      headers                 = []
      query_string            = true
      query_string_cache_keys = []

      cookies {
        forward           = "whitelist"
        whitelisted_names = ["Set-Cookie"]
      }
    }
  }

  # Error pages
  # No cache, no auth required
  cache_behavior {
    allowed_methods             = ["HEAD", "GET", "OPTIONS"]
    cached_methods              = ["HEAD", "GET"]
    compress                    = false
    default_ttl                 = 0
    max_ttl                     = 0
    min_ttl                     = 0
    lambda_function_association = []
    path_pattern                = "/errors/*"
    smooth_streaming            = false
    target_origin_id            = "S3-${var.s3_bucket_name}"
    trusted_signers             = []
    viewer_protocol_policy      = "https-only"

    forwarded_values {
      headers                 = []
      query_string            = false
      query_string_cache_keys = []

      cookies {
        forward           = "none"
        whitelisted_names = []
      }
    }
  }

  # Everything else
  # Requires auth (trusted_signers)
  # Cache = 15,552,000 seconds = 6 months
  default_cache_behavior {
    allowed_methods             = ["HEAD", "GET", "OPTIONS"]
    cached_methods              = ["HEAD", "GET"]
    compress                    = true
    default_ttl                 = 15552000
    max_ttl                     = 15552000
    min_ttl                     = 15552000
    smooth_streaming            = false
    target_origin_id            = "S3-${var.s3_bucket_name}"
    trusted_signers             = ["self"]
    lambda_function_association = []
    viewer_protocol_policy      = "redirect-to-https"

    forwarded_values {
      headers                 = []
      query_string            = false
      query_string_cache_keys = []

      cookies {
        forward           = "none"
        whitelisted_names = []
      }
    }
  }
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "CloudFront origin access identity"
}
