# terraform-aws-lambda-sns-gchat-notification

A terraform module to set-up a Lambda forwarning SNS notifications to a Google Chat channel.

## Usage

- Set-up a Lambda accepting SNS notification to a GChat channel

```hcl
# Set-up Lambda
module "lambda_sns_gchat_notification" {
  source            = "github.com/julb/terraform-aws-lambda-sns-gchat-notification"
  name              = "SnsToGChatMessage"
  gchat_webhook_url   = "https://[....]"
  tags                = { "custom:tag" : "someValue" }
}

# Create some SNS topic.
resource "aws_sns_topic" "some_sns_topic" {
  name = "SomeSnsTopic"
}

# Allow the lambda to be invoked by this SNS topic
resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_sns_gchat_notification.lambda_arn
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.some_sns_topic.arn
}

# Create a subscription for the lambda to this Topic
resource "aws_sns_topic_subscription" "lambda" {
  topic_arn = aws_sns_topic.some_sns_topic.arn
  protocol  = "lambda"
  endpoint  = module.lambda_sns_gchat_notification.lambda_arn
}
```

## Module Input Variables

| Name                   | Type        | Default    | Description                                                                                                                                                                           |
| ---------------------- | ----------- | ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| name                   | string      |  `Not Set` |  The name of the lambda to create. _Required_.                                                                                                                                        |
| gchat_webhook_url      | string      |  `Not Set` |  The Google Chat Webhook URL. This value is marked as **sensitive**._Required_.                                                                                                       |
| tags                   | map(string) |  `{}`      |  The tags to assign to the created resources.                                                                                                                                         |
| ssm_prefix             | string      |  `Not Set` |  The SSM Parameter prefix to use when creating specific parameters. Must start with `/` and must not end with `/`. If not specified, the prefix `/lambda/{name}` prefix will be used. |
| custom_iam_role_arn    | string      |  `Not Set` |  The IAM role to assign to the Lambda. If not specified, a role with appropriate permissions will be created.                                                                         |
| custom_ssm_kms_key_arn | string      |  `Not Set` |  The KMS Key ARN to use to encrypt/decrypt SSM parameters. If not specified, a KMS key will be created.                                                                               |

## Outputs

| Name                                | Type   | Description                                                                                  |
| ----------------------------------- | ------ | -------------------------------------------------------------------------------------------- |
| lambda_function_name                | string |  The Lambda function name.                                                                   |
| lambda_arn                          | ARN    |  The Lambda Amazon Resource Identifier.                                                      |
| lambda_iam_role_arn                 | ARN    |  The IAM Role Amazon Resource Identifier assigned to the Lambda.                             |
| lambda_log_group_name               | string |  The CloudWatch Log Group name in which the Lambda push logs.                                |
| lambda_log_group_arn                | ARN    |  The CloudWatch Log Group Amazon Resource Identifier assigned in which the Lambda push logs. |
| ssm_kms_key_arn                     | ARN    |  The KMS Key Amazon Resource Identifier used to encrypt/decrypt SSM parameters.              |
| ssm_parameter_gchat_webhook_url_arn | ARN    |  The SSM parameter Amazon Resource Identifier used to hold the GoogleChat WebHook URL.       |

## Contributing

This project is totally open source and contributors are welcome.

When you submit a PR, please ensure that the python code is well formatted and linted.

```
$ make format
$ make lint
$ make test
```
