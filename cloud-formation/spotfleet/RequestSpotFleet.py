import json
import logging
import datetime
import boto3
import botocore
ec2 = boto3.client('ec2', 'us-east-1')
logger = logging.getLogger()

TagSpecifications = [
    {
        "ResourceType":"instance",
        "Tags": [
            {
                "Key":"RequestSpotFleetPoc",
                "Value":"999"
            }
        ]
    }
]

request = {
  "AllocationStrategy":"capacityOptimized",  # possible values -> "capacityOptimized" | "lowestPrice" | "diversified"
  "Type": "request", 
  "IamFleetRole": "arn:aws:iam::268425436352:role/aws-ec2-spot-fleet-tagging-role",
  "LaunchSpecifications": []
}

eventParam = {
    "ClientToken": "PocClientToken", # identifier to ensure the idempotency of your listings
    "TargetCapacity": 1,
    "ImageId": "ami-0742b4e673072066f", # Amazon Linux 2
    #"ImageId": "ami-07817f5d0e3866d32", # Windows 2019
    "SecurityGroupId": "sg-073914865c4d9ac48",
    "SubnetId": "subnet-071fa334308d3eab1", # public subnet to connect via ssh
    #"SubnetId": "subnet-03faf608bcdbb05b7,subnet-0f8f70334cd62cd4b", # coma separeted list
    "KeyName": "ec2-default",
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
          "InstanceType": instanceType,
          "KeyName": eventParam["KeyName"],
          "TagSpecifications": TagSpecifications
        })
    print("---RequestFleet---")
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
    