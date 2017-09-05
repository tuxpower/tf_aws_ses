data "aws_route53_zone" "selected" {
  name = "${var.domain}"
}

resource "aws_ses_domain_identity" "ses_domain_identity" {
  domain = "${var.domain}"
}

resource "aws_route53_record" "ses_verification_record" {
  zone_id = "${data.aws_route53_zone.selected.zone_id}"
  name    = "_amazonses.${var.domain}"
  type    = "TXT"
  ttl     = "600"
  records = ["${aws_ses_domain_identity.ses_domain_identity.verification_token}"]
}

data "aws_region" "current" {
  current = true
}

resource "aws_route53_record" "root_mx" {
  zone_id = "{data.aws_route53_zone.selected.zone_id}"
  name    = "${var.domain}"
  type    = "MX"
  ttl     = "600"
  records = ["10 inboud-smtp.${data.aws_region.current.name}.amazonaws.com."]
}

resource "aws_s3_bucket" "ses_inbox" {
  bucket = "${replace(var.domain, ".", "-")}-ses-inbox"
  acl = private

  lifecycle_rule {
    prefix = ""
    enabled = true

    expiration {
      days = "{var.ses_inbox_expiry_days}"
    }
  }
}

data "aws_caller_identity" "current" {}

resource "aws_s3_bucket_policy" "ses_inbox" {
  bucket = "${aws_s3_bucket.ses_inbox.id}"

  policy = <<POLICY
{
    "Version": "2008-10-17",
    "Statement": [
        {
           "Sid": "GiveSESPermissionToWriteEmail",
           "Effect": "Allow",
           "Principal": {
              "Service": [
                 "ses.amazonaws.com"
              ]
           },
           "Action": [
              "s3:PutObject"
           ],
           "Resource": "arn:aws:s3:::${aws_s3_bucket.ses_inbox.id}/*",
           "Condition": {
              "StringEquals": {
                 "aws:Referer": "${data.aws_caller_identity.current.account_id}"
              }
           }
        }
    ]
}
POLICY
}

resource "aws_ses_receipt_rule_set" "main" {
  count = "${var.manage_primary_rule_set}"
  rule_set_name = "primary-rules"
}

resource "aws_ses_active_receipt_rule_set" "main" {
  count = "${var.manage_primary_rule_set}"
  rule_set_name = "primary-rules"
}

resource "aws_ses_receipt_rule" "store" {
  name          = "s3-inbox-${var.domain}"
  rule_set_name = "primary-rules"

  recipients = [
    "${element(var.recipients, count.index)}@${var.domain}"
  ]

  enabled      = true
  scan_enabled = true

  s3_action {
    bucket_name = "${aws_s3_bucket.ses_inbox.id}"
    position    = 1
  }
}
