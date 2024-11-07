################################################################################
# Monitoring
################################################################################

variable "dynatrace_url" {
  description = "URL of the Dynatrace endpoint."
  type        = string
  default     = "https://*****.live.dynatrace.com"
}

################################################################################
# Tagging
################################################################################

variable "custom_tags" {
  description = "A map of tags to add to all resources."
  type        = map(string)
  default     = {}
}

################################################################################
# Common variables
################################################################################

variable "app_name" {
  description = "Name of the application."
  type        = string
  default     = "demoapp"
}

variable "app_env" {
  description = "Environment name of the application."
  type        = string
  default     = "test"
}

variable "app_owner" {
  description = "Owner of the application."
  type        = string
  default     = "me"
}
