resource "aws_cloudwatch_log_subscription_filter" "containerinsights" {
  name            = "containerinsights_to_firehose"
  role_arn        = aws_iam_role.cloudwatch_dynatrace_role.arn
  log_group_name  = data.aws_cloudwatch_log_group.containerinsights.name
  filter_pattern  = ""
  destination_arn = aws_kinesis_firehose_delivery_stream.dynatrace_firehose_stream.arn
  distribution    = "Random"
}

resource "aws_iam_role" "cloudwatch_dynatrace_role" {
  name = "${local.name_prefix}-cloudwatch-ingestion-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "logs.amazonaws.com"
        }
      }
    ]
  })
}

data "aws_iam_policy_document" "cloudwatch_dynatrace_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "firehose:PutRecord"
    ]
    resources = [aws_kinesis_firehose_delivery_stream.dynatrace_firehose_stream.arn]
  }
  statement {
    effect    = "Allow"
    actions   = ["kms:GenerateDataKey"]
    resources = [local.local_key_arn]
  }
}
resource "aws_iam_role_policy" "dynatrace_cloudwatch_policy" {
  name   = "${local.name_prefix}-dynatrace-cloudwatch-policy"
  role   = aws_iam_role.cloudwatch_dynatrace_role.id
  policy = data.aws_iam_policy_document.cloudwatch_dynatrace_policy_document.json
}
