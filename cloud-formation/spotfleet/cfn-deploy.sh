#!/bin/bash

set -x

CFN_STACK_NAME=RequestSpotFleetApi

aws cloudformation deploy \
    --stack-name $CFN_STACK_NAME \
    --template-file cfn-spotfleet-template.yaml \
    --capabilities CAPABILITY_IAM


# wait until the command is complete
#aws cloudformation wait $CFN_WAITING_FOR --stack-name $CFN_STACK_NAME

# Display Output
echo "Outputs:"
aws cloudformation describe-stacks --stack-name $CFN_STACK_NAME --query 'Stacks[0].Outputs'
