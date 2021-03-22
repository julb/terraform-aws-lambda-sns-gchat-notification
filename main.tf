# Get actual region
data "aws_region" "this" {}

# Local variables
locals {
  ssm_prefix = var.ssm_prefix == null ? "/lambda/${var.name}" : var.ssm_prefix
}

# Build Lambda archive
resource "null_resource" "package_lambda_code" {
  provisioner "local-exec" {
    command = "make -C ${path.module}/lambda_function build"
  }
}

data "archive_file" "this" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_function/dist/"
  output_path = "${path.module}/dist/lambda-code.zip"

  depends_on = [null_resource.package_lambda_code]
}

# Create a LogGroup for the Lambda
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.name}"
  retention_in_days = 7
  tags              = var.tags
}

# Create a KMS key for SSM parameters
resource "aws_kms_key" "this" {
  count = var.custom_ssm_kms_key_arn == null ? 1 : 0

  description = "The KMS key used to encrypt SSM parameters for the Lambda ${var.name}"
  tags        = var.tags
}

# Create an alias for the KMS key
resource "aws_kms_alias" "this" {
  count         = var.custom_ssm_kms_key_arn == null ? 1 : 0
  name          = "alias/${var.name}"
  target_key_id = aws_kms_key.this[0].key_id
}

# Create SSM parameters for sensitive values.
resource "aws_ssm_parameter" "this_gchat_webhook_url" {
  name        = "${local.ssm_prefix}/gchat-webhook-url"
  description = "The value of the Google Chat Webhook URL for the Lambda ${var.name}"
  type        = "SecureString"
  value       = var.gchat_webhook_url
  key_id      = var.custom_ssm_kms_key_arn == null ? aws_kms_key.this[0].arn : var.custom_ssm_kms_key_arn
  tags        = var.tags
}

# The lambda IAM role.
resource "aws_iam_role_policy" "this_ssm_get_parameter" {
  count = var.custom_iam_role_arn == null ? 1 : 0

  name = "${var.name}GetSsmParameterPolicy"
  role = aws_iam_role.this[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameter",
        ]
        Effect = "Allow"
        Resource = [
          aws_ssm_parameter.this_gchat_webhook_url.arn
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy" "this_logs_put_events" {
  count = var.custom_iam_role_arn == null ? 1 : 0

  name = "${var.name}PushLogsToCloudwatchPolicy"
  role = aws_iam_role.this[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
        ]
        Effect   = "Allow"
        Resource = "${aws_cloudwatch_log_group.this.arn}:*"
      },
    ]
  })
}

# The IAM Role with which the Lambda should be executed.
resource "aws_iam_role" "this" {
  count = var.custom_iam_role_arn == null ? 1 : 0

  name = "${var.name}IamRole"
  tags = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      },
    ]
  })
}

# Create a Grant between IAM role and the KMS key.
resource "aws_kms_grant" "this" {
  name              = var.name
  key_id            = var.custom_ssm_kms_key_arn == null ? aws_kms_key.this[0].arn : var.custom_ssm_kms_key_arn
  grantee_principal = var.custom_iam_role_arn == null ? aws_iam_role.this[0].arn : var.custom_iam_role_arn
  operations        = ["Decrypt"]
}

# The lambda execution.
resource "aws_lambda_function" "this" {
  filename         = data.archive_file.this.output_path
  source_code_hash = data.archive_file.this.output_base64sha256
  function_name    = var.name
  role             = var.custom_iam_role_arn == null ? aws_iam_role.this[0].arn : var.custom_iam_role_arn
  handler          = "main.lambda_handler"
  runtime          = "python3.8"
  memory_size      = 128
  timeout          = 60
  tags             = var.tags

  environment {
    variables = {
      PYTHONPATH                 = "./dist-packages"
      PARAM_SSM_PATH_WEBHOOK_URL = aws_ssm_parameter.this_gchat_webhook_url.name
    }
  }
}