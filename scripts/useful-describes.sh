#!/bin/bash

##########################################################
# Useful describe commands to find resources dynamically #
##########################################################


# find a security group id by group-name=foo
SecurityGroupId=$(aws ec2 describe-security-groups --filter Name=group-name,Values=foo --query 'SecurityGroups[*].[GroupId]' --output text)
echo "ID: $SecurityGroupId" 

# find a vpc id by tag asset-id=poc
VpcId=$(aws ec2 describe-vpcs --filter Name=tag:asset-id,Values=poc --query 'Vpcs[*].VpcId' --output text)
echo "VpcId: $VpcId"

# find the first public subnet for the given vpc
PublicSubnet=$(aws ec2 describe-route-tables --filter Name=vpc-id,Values=$VpcId Name=association.main,Values=false --query 'RouteTables[0].Associations[0].SubnetId' --output text)
echo "Public Subnet: $PublicSubnet"