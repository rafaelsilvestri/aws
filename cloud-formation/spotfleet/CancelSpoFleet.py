import boto3
client = boto3.client('ec2')

def lambda_handler(event, context):
    response = client.cancel_spot_fleet_requests(
        SpotFleetRequestIds=[event['SpotFleetRequestId']],
        TerminateInstances=True)
    return response