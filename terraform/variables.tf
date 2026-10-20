variable "notification_email" {
  description = "Email for SNS notifications"
  type        = string
  sensitive   = true
}

variable "account_id" {
  description = "Id of the account"
  type        = string
  sensitive   = true
}