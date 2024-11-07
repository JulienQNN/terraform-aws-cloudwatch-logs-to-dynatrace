resource "aws_kinesis_firehose_delivery_stream" "dynatrace_firehose_stream" {
  name = "${local.name_prefix}-dynatrace-firehose-stream"

  destination = "http_endpoint"

  http_endpoint_configuration {
    url                = "${var.dynatrace_url}/api/v2/logs/ingest/aws_firehose"
    name               = "Dynatrace"
    buffering_size     = 1
    buffering_interval = 60
    retry_duration     = 900
    role_arn           = aws_iam_role.dynatrace_firehose_role.arn

    secrets_manager_configuration {
      enabled    = true
      secret_arn = local.dynatrace_secret_arn
      role_arn   = aws_iam_role.dynatrace_firehose_role.arn
    }

    s3_configuration {
      role_arn           = aws_iam_role.dynatrace_firehose_role.arn
      bucket_arn         = aws_s3_bucket.backup_bucket.arn
      prefix             = "dynatrace"
      compression_format = "GZIP"
    }

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.dynatrace_firehose_log_group.name
      log_stream_name = aws_cloudwatch_log_stream.dynatrace_firehose_log_stream.name
    }

    request_configuration {
      common_attributes {
        name  = "dt-url"
        value = var.dynatrace_url
      }
    }
  }

  tags = merge(
    local.tags,
    {
      "app:layer" = "monitoring"
    }
  )
}

resource "aws_cloudwatch_log_group" "dynatrace_firehose_log_group" {
  name       = "/aws/kinesisfirehose/${local.name_prefix}-dynatrace-firehose-stream"
  kms_key_id = local.local_key_arn

  tags = merge(
    local.tags,
    {
      "app:layer" = "monitoring"
    }
  )
}

resource "aws_cloudwatch_log_stream" "dynatrace_firehose_log_stream" {
  name           = "DestinationDelivery"
  log_group_name = aws_cloudwatch_log_group.dynatrace_firehose_log_group.name
}

resource "aws_cloudwatch_log_stream" "firehose_logstream_backup" {
  name           = "BackupDelivery"
  log_group_name = aws_cloudwatch_log_group.dynatrace_firehose_log_group.name
}

resource "aws_iam_role" "dynatrace_firehose_role" {
  name = "${local.name_prefix}-dynatrace-firehose-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = "sts:AssumeRole",
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "dynatrace_firehose_document" {
  statement {
    sid       = "GetSecretValue"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [local.dynatrace_secret_arn]
  }

  statement {
    sid       = "DecryptSecretWithKMSKey"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [local.local_key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["secretsmanager.${local.region}.amazonaws.com"]
    }
  }

  statement {
    sid    = "s3Permissions"
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject"
    ]
    resources = [
      "${aws_s3_bucket.backup_bucket.arn}/*",
      aws_s3_bucket.backup_bucket.arn
    ]
  }

  statement {
    sid       = "cloudWatchLog"
    effect    = "Allow"
    actions   = ["logs:PutLogEvents"]
    resources = [aws_cloudwatch_log_group.dynatrace_firehose_log_group.arn]
  }

  statement {
    sid       = "KDSEncryption"
    effect    = "Allow"
    actions   = ["kms:Decrypt"]
    resources = [local.local_key_arn]
    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["kinesis.${local.region}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "dynatrace_firehose_policy" {
  name   = "${local.name_prefix}-dynatrace-firehose-policy"
  role   = aws_iam_role.dynatrace_firehose_role.id
  policy = data.aws_iam_policy_document.dynatrace_firehose_document.json
}
