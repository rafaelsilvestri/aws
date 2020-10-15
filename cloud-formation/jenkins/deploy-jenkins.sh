#!/bin/bash

set -x

# Usage: deploy-jenkins.sh <cf-stack-name> |tee /dev/fd/3

CFN_STACK_NAME=$1
CURRENT_IP="$(dig @ns1-1.akamaitech.net ANY whoami.akamai.net +short)/32"

# Parameters
VPC=$(aws ec2 describe-vpcs --filter Name=tag:asset-id,Values=poc --query 'Vpcs[*].VpcId' --output text)
Subnet=$(aws ec2 describe-route-tables --filter Name=vpc-id,Values=$VPC Name=association.main,Values=false --query 'RouteTables[0].Associations[0].SubnetId' --output text)
KeyName='ec2-default'
AMI='ami-0dba2cb6798deb6d8' # Ubuntu us-east-1
InstanceType='t3.medium'
SSHLocation=$CURRENT_IP
HTTPLocation=$CURRENT_IP
EnvironmentType='DEVELOPMENT'
AssetId='poc'

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
aws cloudformation $CFN_COMMAND --stack-name $CFN_STACK_NAME --template-body file://cfn-jenkins-template.yaml \
    --parameters \
    ParameterKey=SSHLocation,ParameterValue=$SSHLocation \
    ParameterKey=VPC,ParameterValue=$VPC \
    ParameterKey=HTTPLocation,ParameterValue=$HTTPLocation \
    ParameterKey=Subnet,ParameterValue=$Subnet \
    ParameterKey=KeyName,ParameterValue=$KeyName \
    ParameterKey=AMI,ParameterValue=$AMI \
    ParameterKey=InstanceType,ParameterValue=$InstanceType \
    ParameterKey=EnvironmentType,ParameterValue=$EnvironmentType \
    ParameterKey=AssetId,ParameterValue=$AssetId 

# wait until the command is complete
aws cloudformation wait $CFN_WAITING_FOR --stack-name $CFN_STACK_NAME

# Display Output
echo "Outputs:"
aws cloudformation describe-stacks --stack-name $CFN_STACK_NAME --query 'Stacks[0].Outputs'
