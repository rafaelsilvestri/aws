#!/bin/bash
#
# Get the value of a tag for a running EC2 instance.
#

#
# Note the EC2 instance needs to have an IAM role that lets it read tags. 
# The policy JSON for this looks like:
#
#    {
#      "Version": "2012-10-17",
#      "Statement": [
#        {
#          "Effect": "Allow",
#          "Action": "ec2:DescribeTags",
#          "Resource": "*"
#        }
#      ]
#    }

# Define the tag you want to get the value for
KEY=$1

# If you are not using Amazon Linux AMI - Install AWS CLI
#apt-get update
#apt-get install -y python-pip
#pip install -U pip
#pip install awscli

# Grab instance ID and region as the 'describe-tags' action below requires them.
#INSTANCE_ID=$(ec2metadata --instance-id)
# On Amazon Linux AMI
INSTANCE_ID=$(ec2-metadata --instance-id | cut -f2 -d " ")
REGION=$(curl -s http://169.254.169.254/latest/dynamic/instance-identity/document | grep region | awk -F\" '{print $4}')

# Grab tag value
TAG_VALUE=$(aws ec2 describe-tags --filters "Name=resource-id,Values=$INSTANCE_ID" "Name=key,Values=$KEY" --region=$REGION --output=text | cut -f5)

echo $TAG_VALUE