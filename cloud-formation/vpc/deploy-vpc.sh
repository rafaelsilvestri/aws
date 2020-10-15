#!/bin/bash

set -x

# Usage: deploy-vpc.sh <cf-stack-name> |tee /dev/fd/3

CFN_STACK_NAME=$1
# Parameters
VpcCIDR='10.0.0.0/16'
PublicSubnetAZ1CIDR='10.0.1.0/24'
PublicSubnetAZ2CIDR='10.0.2.0/24'
PrivateSubnetAppAZ1CIDR='10.0.10.0/24'
PrivateSubnetAppAZ2CIDR='10.0.11.0/24'
PrivateSubnetDataAZ1CIDR='10.0.20.0/24'
PrivateSubnetDataAZ2CIDR='10.0.21.0/24'
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
aws cloudformation $CFN_COMMAND --stack-name $CFN_STACK_NAME --template-body file://cfn-vpc-template.yaml \
    --parameters \
    ParameterKey=VpcCIDR,ParameterValue=$VpcCIDR \
    ParameterKey=PublicSubnetAZ1CIDR,ParameterValue=$PublicSubnetAZ1CIDR \
    ParameterKey=PublicSubnetAZ2CIDR,ParameterValue=$PublicSubnetAZ2CIDR \
    ParameterKey=PrivateSubnetAppAZ1CIDR,ParameterValue=$PrivateSubnetAppAZ1CIDR \
    ParameterKey=PrivateSubnetAppAZ2CIDR,ParameterValue=$PrivateSubnetAppAZ2CIDR \
    ParameterKey=PrivateSubnetDataAZ1CIDR,ParameterValue=$PrivateSubnetDataAZ1CIDR \
    ParameterKey=PrivateSubnetDataAZ2CIDR,ParameterValue=$PrivateSubnetDataAZ2CIDR \
    ParameterKey=EnvironmentType,ParameterValue=$EnvironmentType \
    ParameterKey=AssetId,ParameterValue=$AssetId 

# wait until the command is complete
aws cloudformation wait $CFN_WAITING_FOR --stack-name $CFN_STACK_NAME

# Display Output
echo "Outputs:"
aws cloudformation describe-stacks --stack-name $CFN_STACK_NAME --query 'Stacks[0].Outputs'
