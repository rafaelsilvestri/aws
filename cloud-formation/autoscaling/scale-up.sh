#!/bin/bash

set -x
# set -ex

# Deploys the ASG
# Usage: deploy-asg.sh <cf-stack-name> <ami-id> <os> <asg-desired> |tee /dev/fd/3 
 
CFN_STACK_NAME="$1"
AMI="$2" # ami-0dba2cb6798deb6d8
OS="$3"
INSTANCE_TYPE='t3.nano'
ASG_DESIRED=$4
SUBNET_AZ1=subnet-0e2feff76cceceb05 #us-east-1a
SUBNET_AZ2=subnet-00b475d30aed2e22b #us-east-1b
#KEY_NAME=key-09ad5f033f0e4c7b2
KEY_NAME='ec2-default'
# Get the current external IP to allow SSH connection x.x.x.x/32
SSH_LOCATION="$(dig @ns1-1.akamaitech.net ANY whoami.akamai.net +short)/32"
SG=sg-055bca2b68c0209c6
ENV_TYPE='DEVELOPMENT'


CFN_UPDATING=true
while $CFN_UPDATING; do
    CFN_STATUS=$(aws --output text cloudformation describe-stacks --stack-name  $CFN_STACK_NAME --query 'Stacks[0].StackStatus')
    echo "Status $CFN_STATUS" 
    if [[ -z "$CFN_STATUS" ]]; then
        echo "create-stack"
        CFN_COMMAND='create-stack'
        CFN_WAITING_FOR='stack-create-complete'
        CFN_UPDATING=false
    else
        case "$CFN_STATUS" in
            CREATE_COMPLETE|UPDATE_COMPLETE|ROLLBACK_COMPLETE|UPDATE_ROLLBACK_COMPLETE)
                echo "Status: $CFN_STATUS"
                CFN_COMMAND='update-stack'
                CFN_WAITING_FOR='stack-update-complete'
                CFN_UPDATING=false
                ;;
            CREATE_IN_PROGRESS|DELETE_IN_PROGRESS|ROLLBACK_IN_PROGRESS|UPDATE_COMPLETE_CLEANUP_IN_PROGRESS|UPDATE_IN_PROGRESS|UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS|UPDATE_ROLLBACK_IN_PROGRESS)
                echo "Status: $CFN_STATUS"
                sleep 5
                ;;
            CREATE_FAILED|DELETE_FAILED|ROLLBACK_FAILED|UPDATE_ROLLBACK_FAILED|DELETE_COMPLETE)
                echo "Status: $CFN_STATUS"
                exit 1
        esac
    fi
done


# Launching CF Stack
echo "Lauching Stack"
aws cloudformation $CFN_COMMAND --stack-name $CFN_STACK_NAME --template-body file://cfn-asg-template.yaml \
    --parameters \
    ParameterKey=AMI,ParameterValue=$AMI \
    ParameterKey=OS,ParameterValue=$OS \
    ParameterKey=InstanceType,ParameterValue=$INSTANCE_TYPE \
    ParameterKey=ASGDesiredCapacity,ParameterValue=$ASG_DESIRED \
    ParameterKey=InstanceSubnetAZ1,ParameterValue=$SUBNET_AZ1 \
    ParameterKey=InstanceSubnetAZ2,ParameterValue=$SUBNET_AZ2 \
    ParameterKey=KeyName,ParameterValue=$KEY_NAME \
    ParameterKey=SSHLocation,ParameterValue=$SSH_LOCATION \
    ParameterKey=InstanceSecurityGroup,ParameterValue=$SG \
    ParameterKey=EnvironmentType,ParameterValue=$ENV_TYPE 

# wait until the command is complete
aws cloudformation wait $CFN_WAITING_FOR --stack-name $CFN_STACK_NAME

# Display Output
echo "Outputs:"
aws cloudformation describe-stacks --stack-name $CFN_STACK_NAME --query 'Stacks[0].Outputs'
