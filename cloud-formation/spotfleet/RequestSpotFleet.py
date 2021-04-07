import json
import logging
import datetime
import base64
import boto3
import botocore

__author__ = "Rafael Silvestri"
__email__ = "rafaelcechinel@gmail.com"

""" 
    Lambda function to process requests from API Gateway and request a Spot Fleet
"""

ec2 = boto3.client('ec2', 'us-east-1')
logger = logging.getLogger()

#UserData = 'echo "Hello" > echo.txt && sudo shutdown -P +5'
UserData = 'ZWNobyAiSGVsbG8iID4gZWNoby50eHQgJiYgc3VkbyBzaHV0ZG93biAtUCArNQ=='

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

# Define the default values for the RequestSpotFleet
request = {
  "AllocationStrategy": "capacityOptimized",  # possible values -> "capacityOptimized" | "lowestPrice" | "diversified"
  "InstanceInterruptionBehavior": "terminate",
  "Type": "request", 
  "IamFleetRole": "arn:aws:iam::268425436352:role/aws-ec2-spot-fleet-tagging-role",
  "LaunchSpecifications": []
}

eventParam = None

def lambda_handler(event, context):
    global eventParam
    path = event['path']

    if 'body' in event and event['body'] is not None:
        eventParam = json.loads(event['body'])
        logger.info(eventParam)
    else:
        logger.fatal('Request body is required.')
        return {
            'statusCode': 500,
            'body': 'Request body is required.'
        }

    # Create the fleet.
    instancesTypes = GetSpotRequestParam()
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
    #global eventParam
    global request
    request["TargetCapacity"] = eventParam["TargetCapacity"]
    request["AllocationStrategy"] = eventParam["AllocationStrategy"]
    request["ClientToken"] = eventParam["ClientToken"]

    insTypes = GetInstancesTypes(eventParam)
    print("Inatances Types")
    print(insTypes)
    for instanceType in insTypes:
        request["LaunchSpecifications"].append( {
          "SecurityGroups": [{"GroupId": "sg-073914865c4d9ac48"}],
          "SubnetId": "subnet-071fa334308d3eab1", # public subnet to connect via ssh
          #"SubnetId": "subnet-03faf608bcdbb05b7,subnet-0f8f70334cd62cd4b", # coma separeted list
          "TagSpecifications": TagSpecifications,
          "UserData": UserData,
          "InstanceType": instanceType,
          "ImageId": eventParam["ImageId"],
          "KeyName": eventParam["KeyName"]
        })
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
    