import boto3
client = boto3.client('ec2')

def lambda_handler(event, context):
    response = client.describe_spot_fleet_instances(
        SpotFleetRequestId=event['SpotFleetRequestId'], MaxResults=1000) # 100 is the max - if there are more than 1000, user NextToken
    ec2Ids = []
    for instance in response['ActiveInstances']:
        ec2Ids.append(instance['InstanceId'])
    result = client.describe_instances(InstanceIds=ec2Ids)
    print(result['Reservations'][0]['Instances'][0])
    IPs = []
    statuses = []
    for reserv in result['Reservations']:
        for ec2 in reserv['Instances']:
            IPs.append(ec2['PrivateIpAddress'])
            statuses.append(ec2['State']['Name'])
    return ec2Ids,IPs,statuses