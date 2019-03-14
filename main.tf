terraform {
  backend "s3" {
    region = "eu-west-1"
    bucket = "infrastructure.noodlesandwich.com"
    key    = "terraform/state/noodlesandwich.com"
  }
}

locals {
  domain = "noodlesandwich.com"

  alternative_domain = "samirtalwar.com"
}

provider "aws" {
  region = "eu-west-1"
}

provider "cloudflare" {}

resource "aws_s3_bucket" "site" {
  bucket = "${local.domain}"
}

resource "aws_s3_bucket" "assets" {
  bucket = "assets.${local.domain}"
}

resource "aws_cloudfront_distribution" "site_distribution" {
  enabled             = true
  default_root_object = "index.html"
  aliases             = ["${local.domain}", "www.${local.domain}"]

  origin {
    domain_name = "${aws_s3_bucket.site.bucket_regional_domain_name}"
    origin_id   = "S3-${aws_s3_bucket.site.id}"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.site.id}"

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "aws_cloudfront_distribution" "assets_distribution" {
  enabled = true
  aliases = ["assets.${local.domain}"]

  origin {
    domain_name = "${aws_s3_bucket.assets.bucket_regional_domain_name}"
    origin_id   = "S3-${aws_s3_bucket.assets.id}"
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "S3-${aws_s3_bucket.assets.id}"

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

resource "cloudflare_record" "root" {
  domain  = "${local.domain}"
  name    = "@"
  type    = "CNAME"
  value   = "${aws_cloudfront_distribution.site_distribution.0.domain_name}"
  proxied = true
}

resource "cloudflare_record" "www" {
  domain  = "${local.domain}"
  name    = "www"
  type    = "CNAME"
  value   = "${local.domain}"
  proxied = true
}

resource "cloudflare_record" "assets" {
  domain  = "${local.domain}"
  name    = "assets"
  type    = "CNAME"
  value   = "${aws_cloudfront_distribution.assets_distribution.0.domain_name}"
  proxied = true
}

resource "cloudflare_record" "alternative_root" {
  domain  = "${local.alternative_domain}"
  name    = "@"
  type    = "CNAME"
  value   = "${local.domain}"
  proxied = true
}

resource "cloudflare_record" "alternative_www" {
  domain  = "${local.alternative_domain}"
  name    = "www"
  type    = "CNAME"
  value   = "${local.domain}"
  proxied = true
}

resource "cloudflare_record" "alternative_talks" {
  domain  = "${local.alternative_domain}"
  name    = "talks"
  type    = "CNAME"
  value   = "${local.domain}"
  proxied = true
}

resource "cloudflare_page_rule" "always_use_https" {
  zone     = "${local.domain}"
  target   = "http://*${local.domain}/*"
  priority = 1

  actions = {
    always_use_https = true
  }
}

resource "cloudflare_page_rule" "redirect_www" {
  zone     = "${local.domain}"
  target   = "www.${local.domain}/*"
  priority = 2

  actions = {
    forwarding_url {
      url         = "https://${local.domain}/$1"
      status_code = 301
    }
  }
}

resource "cloudflare_page_rule" "redirect_alternative_root" {
  zone     = "${local.alternative_domain}"
  target   = "${local.alternative_domain}/*"
  priority = 1

  actions = {
    forwarding_url {
      url         = "https://${local.domain}/$1"
      status_code = 301
    }
  }
}

resource "cloudflare_page_rule" "redirect_alternative_www" {
  zone     = "${local.alternative_domain}"
  target   = "www.${local.alternative_domain}/*"
  priority = 2

  actions = {
    forwarding_url {
      url         = "https://${local.domain}/$1"
      status_code = 301
    }
  }
}

resource "cloudflare_page_rule" "redirect_alternative_talks" {
  zone     = "${local.alternative_domain}"
  target   = "talks.${local.alternative_domain}/*"
  priority = 3

  actions = {
    forwarding_url {
      url         = "https://${local.domain}/talks/$1"
      status_code = 301
    }
  }
}

resource "cloudflare_record" "mail" {
  domain = "${local.domain}"
  name   = "mail"
  type   = "CNAME"
  value  = "ghs.googlehosted.com"
}

resource "cloudflare_record" "mx_0" {
  domain   = "${local.domain}"
  name     = "${local.domain}"
  type     = "MX"
  value    = "aspmx.l.google.com"
  priority = 1
}

resource "cloudflare_record" "mx_1" {
  domain   = "${local.domain}"
  name     = "${local.domain}"
  type     = "MX"
  value    = "alt1.aspmx.l.google.com"
  priority = 5
}

resource "cloudflare_record" "mx_2" {
  domain   = "${local.domain}"
  name     = "${local.domain}"
  type     = "MX"
  value    = "alt2.aspmx.l.google.com"
  priority = 5
}

resource "cloudflare_record" "mx_3" {
  domain   = "${local.domain}"
  name     = "${local.domain}"
  type     = "MX"
  value    = "alt3.aspmx.l.google.com"
  priority = 10
}

resource "cloudflare_record" "mx_4" {
  domain   = "${local.domain}"
  name     = "${local.domain}"
  type     = "MX"
  value    = "alt4.aspmx.l.google.com"
  priority = 10
}

resource "cloudflare_record" "keybase_site_verification" {
  domain = "${local.domain}"
  name   = "${local.domain}"
  type   = "TXT"
  value  = "keybase-site-verification=YPF-r-na8c2rGHEe5DxOI0xzGC1sSqr8743dqV4iF2o"
}

resource "cloudflare_record" "alternative_keybase_site_verification" {
  domain = "${local.alternative_domain}"
  name   = "${local.alternative_domain}"
  type   = "TXT"
  value  = "keybase-site-verification=mekOQ5MzFzpNa9ql62LM0IfNgZhcbpW7VSsj5mGOCxk"
}
