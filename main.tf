locals {
  region = data.aws_region.current.name

  app_env   = var.app_env
  app_name  = var.app_name
  app_owner = var.app_owner

  name_prefix = "${local.app_env}-${local.app_name}"

  # Encryption
  local_key_arn = data.aws_ssm_parameter.local_key_arn.value

  # Secrets
  dynatrace_secret_arn = data.aws_ssm_parameter.dynatrace_secret_arn.value
}

data "aws_region" "current" {}

# Already created log group
data "aws_cloudwatch_log_group" "containerinsights" {
  name = "/aws/ecs/containerinsights/${local.name_prefix}-cluster/performance"
}

# Encryption
data "aws_ssm_parameter" "local_key_arn" {
  name = "/org/landing-zone/security/cmk/local-key/arn"
}

# Secrets
data "aws_ssm_parameter" "dynatrace_secret_arn" {
  name = "/app/${local.app_env}/${local.app_name}/security/secret/dynatrace/arn"
}
