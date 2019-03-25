provider "aws" {
  region = "us-east-1"
  alias  = "aws_cloudfront"
}

# data "aws_acm_certificate" "acm_cert" {
#   domain   = "*.${var.hosted_zone}"
#   provider = "aws.aws_cloudfront"

#   //CloudFront uses certificates from US-EAST-1 region only

#   statuses = [
#     "ISSUED",
#   ]
# }

data "aws_iam_policy_document" "s3_bucket_policy" {
  statement {
    sid = "1"

    actions = [
      "s3:GetObject",
    ]

    resources = [
      "arn:aws:s3:::${var.domain_name}/*",
    ]

    principals {
      type = "AWS"

      identifiers = [
        "${aws_cloudfront_origin_access_identity.origin_access_identity.iam_arn}",
      ]
    }
  }
}

resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.domain_name}"
  acl    = "private"
  region = "${var.aws_region}"

  versioning {
    enabled = true
  }

  policy = "${data.aws_iam_policy_document.s3_bucket_policy.json}"

  tags = "${var.tags}"
}


resource "aws_cloudfront_distribution" "s3_distribution" {
  depends_on = [
    "aws_s3_bucket.s3_bucket",
  ]

  origin {
    domain_name = "${var.domain_name}.s3.amazonaws.com"
    origin_id   = "s3-cloudfront"

    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.origin_access_identity.cloudfront_access_identity_path}"
    }
  }

  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"

  aliases = [ "${merge(var.domain_name,var.domain_aliases)}" ]

  default_cache_behavior {
    allowed_methods = [
      "GET",
      "HEAD",
    ]

    cached_methods = [
      "GET",
      "HEAD",
    ]

    target_origin_id = "s3-cloudfront"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000
  }

  price_class = "PriceClass_All"


  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
  viewer_certificate {
    acm_certificate_arn      = "${var.acm_cert_arn}"
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.1_2016"
  }
  custom_error_response {
    error_code            = 403
    response_code         = 200
    error_caching_min_ttl = 0
    response_page_path    = "/"
  }
  tags = "${var.tags}"
}

resource "aws_cloudfront_origin_access_identity" "origin_access_identity" {
  comment = "access-identity-${var.domain_name}.s3.amazonaws.com"
}
