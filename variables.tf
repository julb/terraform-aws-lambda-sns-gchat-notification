variable "name" {
  type        = string
  description = "The name of the lambda to create."
}

variable "gchat_webhook_url" {
  type        = string
  description = "The Google Chat Webhook URL."
  sensitive   = true
}

variable "tags" {
  default     = {}
  description = "Tags to associate to the lambda."
  type        = map(string)
}

variable "ssm_prefix" {
  description = "The prefix to prepend in front of created SSM parameters. If not specified, will be /lambda/{name}."
  type        = string
  default     = null
  validation {
    condition     = var.ssm_prefix == null || can(regex("^/.*[^/]$", var.ssm_prefix))
    error_message = "The ssm_prefix value must start with a \"/\" and must not end with a \"/\"."
  }
}

variable "custom_iam_role_arn" {
  description = "A custom IAM role to execute the lambda. If not specified, a role will be created."
  type        = string
  default     = null
}

variable "custom_ssm_kms_key_arn" {
  description = "A custom KMS key to encrypt SSM parameters. If not specified, a custom one will be created."
  type        = string
  default     = null
}