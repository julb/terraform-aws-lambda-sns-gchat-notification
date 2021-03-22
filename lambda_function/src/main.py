import os
import boto3
import requests

from base import LambdaFunctionBase


class SnsNotificationSendGChatMessage(LambdaFunctionBase):
    """
    Class sending a SNS notification to GChat.
    """

    # Section specific to the lambda.
    SSM_PATH_WEBHOOK_URL = os.environ['PARAM_SSM_PATH_WEBHOOK_URL']

    def _get_ssm_parameter_value(self, parameter_path):
        """ Returns the value of a SSM parameter. """
        ssm_client = boto3.client('ssm')
        parameter = ssm_client.get_parameter(Name=parameter_path, WithDecryption=True)
        return parameter['Parameter']['Value']

    def _post_gchat_text_message(self, gchat_webhook_url, gchat_message):
        """ Posting GChat message to the webhook. """
        post_request_data = {'text': gchat_message}
        post_request_details = requests.post(gchat_webhook_url, json=post_request_data)
        if post_request_details.ok:
            self.logger.info('>> Message posted succesfully to GChat.')
        else:
            self.logger.error('>> Failed to post GChat Message. Got %s.', post_request_details.content)

    def _check_inputs(self, event):
        """ Check the inputs of the method. """
        # Check that event contains records.
        if 'Records' not in event:
            raise Exception('No ''Records'' field in the received event.')

        # Check that event contains SNS records only.
        for record in event['Records']:
            if 'Sns' not in record or 'Message' not in record['Sns']:
                raise Exception('Received records are not valid SNS notifications.')

    def _execute(self, event, context):  # pylint: disable=W0613
        """ Execute the method. """
        self.logger.info('Starting the operation.')

        # Reading SSM parameter
        self.logger.debug('> Extracting GChat Webhook URL from SSM.')
        gchat_webhook_url = self._get_ssm_parameter_value(self.SSM_PATH_WEBHOOK_URL)

        # Posting messages To the webhook.
        self.logger.debug('> Processing records of event.')
        for record in event['Records']:
            # Trace SNS record ID
            self.logger.debug('>> Processing SNS record with MessageId <%s>.', record['Sns']['MessageId'])

            # GChat message from the record.
            gchat_message = record['Sns']['Message']

            # Post message
            self._post_gchat_text_message(gchat_webhook_url, gchat_message)

        self.logger.info('Operation completed successfully.')

        return self._build_response_ok()


def lambda_handler(event, context):
    """ Function invoked by AWS. """
    return SnsNotificationSendGChatMessage().process_event(event, context)
