# Input variables. Values are in terraform.tfvars, which is not in git.

variable "notification_email" {
  description = "Email for SNS notifications"
  type        = string
  sensitive   = true
}