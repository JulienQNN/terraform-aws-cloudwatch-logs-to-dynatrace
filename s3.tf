resource "aws_s3_bucket" "backup_bucket" {
  bucket = "${local.name_prefix}-dynatrace-bucket-backup"

  tags = merge(
    local.tags,
    {
      "app:layer" = "storage"
    }
  )
}
