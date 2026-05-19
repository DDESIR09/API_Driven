import json
import boto3
import os

ec2 = boto3.client(
    'ec2',
    endpoint_url='http://localhost.localstack.cloud:4566',
    region_name='us-east-1',
    aws_access_key_id='test',
    aws_secret_access_key='test'
)

INSTANCE_ID = 'i-afff854eb5fd8f883'

def lambda_handler(event, context):
    params = event.get('queryStringParameters') or {}
    action = params.get('action', 'status')

    try:
        if action == 'start':
            ec2.start_instances(InstanceIds=[INSTANCE_ID])
            message = f"Instance {INSTANCE_ID} demarree"
        elif action == 'stop':
            ec2.stop_instances(InstanceIds=[INSTANCE_ID])
            message = f"Instance {INSTANCE_ID} arretee"
        else:
            response = ec2.describe_instances(InstanceIds=[INSTANCE_ID])
            state = response['Reservations'][0]['Instances'][0]['State']['Name']
            message = f"Instance {INSTANCE_ID} : etat = {state}"

        return {
            'statusCode': 200,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'message': message, 'action': action})
        }
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {'Content-Type': 'application/json'},
            'body': json.dumps({'error': str(e)})
        }
