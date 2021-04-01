import json
import logging
import datetime
import boto3
import botocore
ec2 = boto3.client('ec2', 'us-east-1')
logger = logging.getLogger()

request = {
  "AllocationStrategy":"capacityOptimized",  # possible values -> "capacityOptimized" | "lowestPrice" | "diversified"
  "Type": "request", 
  "IamFleetRole": "arn:aws:iam::268425436352:role/aws-ec2-spot-fleet-tagging-role",
  "LaunchSpecifications": []
}

eventParam = {
    "ClientToken": "id-para-rodada-de-testes",
    "TargetCapacity": 3,
    "ImageId": "ami-07817f5d0e3866d32",
    "SecurityGroupId": "sg-062f773330217e4a4",
    "SubnetId": "subnet-0d4a5ba492ad22c1e",
    "MinvCPU": 1,
    "MaxvCPU": 2
}

def lambda_handler(event, context):
    # Create the fleet.
    instancesTypes = GetSpotRequestParam()
    #logger.fatal(instancesTypes)
    try:
        request = ec2.request_spot_fleet(SpotFleetRequestConfig=instancesTypes)
    except botocore.exceptions.ParamValidationError as err:
        logger.fatal('Bad parameters provided, cannot continue: %s', err)
        return
    except botocore.exceptions.ClientError as err:
        logger.fatal('Failed to request spot fleet, cannot continue: %s', err)
        return

    return {
        'statusCode': 200,
        'body': request
    }
    

def GetSpotRequestParam():
    global eventParam
    global request
    request["TargetCapacity"] = eventParam["TargetCapacity"]
    insTypes = GetInstancesTypes(eventParam)
    print("Inatances Types")
    print(insTypes)
    for instanceType in insTypes:
        request["LaunchSpecifications"].append( {
          "SecurityGroups": [{"GroupId": eventParam["SecurityGroupId"]}],
          "ImageId": eventParam["ImageId"],
          "SubnetId": eventParam["SubnetId"],
          "InstanceType": instanceType
        })
    print("RequestFleet")
    print(request)
    return request


def GetInstancesTypes(filter):
    detailList = ec2.describe_instance_types(Filters=GetInstancesTypesFilter(), MaxResults=100);
    insTypes = []
    for instanceT in detailList["InstanceTypes"]:
        if FilterInstanceType(instanceT, filter):
            insTypes.append(instanceT["InstanceType"])
    while "NextToken" in detailList:
        detailList = ec2.describe_instance_types(Filters=GetInstancesTypesFilter(), MaxResults=100, NextToken=detailList["NextToken"]);
        for instanceT in detailList["InstanceTypes"]:
            if FilterInstanceType(instanceT, filter):
                insTypes.append(instanceT["InstanceType"])
    insTypes.sort()
    return insTypes


def FilterInstanceType(instance, filter):
    if instance["VCpuInfo"]["DefaultVCpus"] < filter["MinvCPU"]: return False
    if instance["VCpuInfo"]["DefaultVCpus"] > filter["MaxvCPU"]: return False
    return True
    

def GetInstancesTypesFilter():
    return [
        {
            "Name": "instance-type",
            "Values": ["m*", "t*", "c*" ]
        },
        {
            "Name": "processor-info.supported-architecture",
            "Values": ["x86_64"]
        },
        {
            "Name": "supported-usage-class",
            "Values": ["spot"]
        }
    ]
    