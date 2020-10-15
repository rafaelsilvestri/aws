# aws-cloud-formation
A collections of AWS CloudFormation templates

## To create an AWS CloudFormation stack

The following create-stacks command creates a stack with the name `MyNetworkStack` using the `network.yaml` template:

```console
aws cloudformation create-stack --stack-name MyNetworkStack --template-body file://netowrk.yaml --parameters ParameterKey=KeyPairName,ParameterValue=TestKey ParameterKey=SubnetID,ParameterValue=SubnetID1
```

## References

https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/Welcome.html  
https://github.com/awsdocs/aws-cloudformation-user-guide
