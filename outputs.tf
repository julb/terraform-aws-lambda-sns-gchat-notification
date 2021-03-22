output "lambda_function_name" {
  description = "The Lambda Function name."
  value       = aws_lambda_function.this.function_name
}

output "lambda_arn" {
  description = "The Lambda ARN."
  value       = aws_lambda_function.this.arn
}

output "lambda_iam_role_arn" {
  description = "The Lambda IAM role ARN."
  value       = var.custom_iam_role_arn == null ? aws_iam_role.this[0].arn : var.custom_iam_role_arn
}

output "lambda_log_group_name" {
  description = "The name of the Lambda Log Group."
  value       = aws_cloudwatch_log_group.this.name
}

output "lambda_log_group_arn" {
  description = "The Lambda Log Group ARN."
  value       = aws_cloudwatch_log_group.this.arn
}

output "ssm_kms_key_arn" {
  description = "The KMS Key ARN used to encrypt the SSM parameters."
  value       = var.custom_ssm_kms_key_arn == null ? aws_kms_key.this[0].arn : var.custom_ssm_kms_key_arn
}

output "ssm_parameter_gchat_webhook_url_arn" {
  description = "The SSM parameter ARN for the GoogleChat Webhook URL."
  value       = aws_ssm_parameter.this_gchat_webhook_url.arn
}