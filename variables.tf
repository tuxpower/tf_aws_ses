variable "domain" {
  description = "Name of the domain to setup ses for"
  default     = ""
}

variable "manage_primary_rule_set" {
  description = "There is only one active rule set per acount so it should be managed by one env"
  default = "0"
}

variable "ses_inbox_expiry_days" {
  description = "How long to keep emails in the s3 inbox bucket"
  default     = "7"
}

variables "recipients" {
  description = "A list of email addresses"
  default     = []
}
