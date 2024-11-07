locals {

  mandatory_tags = {
    "app:name" : local.app_name,
    "app:env" : local.app_env,
    "app:owner" : local.app_owner
  }

  tags = merge(
    local.mandatory_tags,
    var.custom_tags
  )

}
