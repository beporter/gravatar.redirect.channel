variable "aws_region" {
  description = "AWS region string"
  type        = string
  default     = "us-east-2"

  validation {
    condition     = can(regex("[a-z][a-z]-[a-z]+-[1-9]", var.string_like_aws_region))
    error_message = "Must be valid AWS Region name"
  }
}

variable "site_domain_name" {
  description = "The full domain name for the S3-hosted website (e.g., www.example.com)"
  type        = string
}

variable "domain_zone" {
  description = "The Route53 hosted zone domain (e.g., example.com)"
  type        = string
}

variable "alert_emails" {
  description = "Email recipient list for budget alert notifications"
  type        = list(string)

  validation {
    condition     = length(var.alert_emails) >= 1
    error_message = "At least one alert email must be set"
  }

  validation {
    condition = alltrue([
      for email in var.alert_emails :
        can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All values must be valid email addresses"
  }
}

variable "monthly_dollar_limit" {
  description = "Decimal limit in USD per month"
  type = number
  default = 5.0
}
