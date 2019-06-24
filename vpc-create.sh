#!/bin/bash

vpcId=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
#echo $vpcId
echo "The VPC ID is created "
echo "Tagging the VPC-id with CLI-VPC"
aws ec2 create-tags --resources $vpcId --tags Key=Name,Value=CLI-VPC
echo "VPC CREATED with CLI-VPC"

######******** enable-dns-support *************
aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-support "{\"Value\":true}"
aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-hostnames "{\"Value\":true}"

##############   INTERNET GATEWAY   ########################

internetGatewayId=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
#echo $internetGatewayId
echo "Tagging INTERNET GATEWAY"
aws ec2 create-tags --resources $internetGatewayId --tags Key=Name,Value=CLI-IG 
aws ec2 attach-internet-gateway --internet-gateway-id $internetGatewayId --vpc-id $vpcId
echo "INTERNET GATEWAY IS CREATED"


#### *******CREATING SUBNETS PUBLIC*********

echo "Creating Subnets (public/private)"

psubnetId=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block 10.0.1.0/24 --query 'Subnet.SubnetId' --output text)
#echo $psubnetId
echo "Tagging public subnet"
aws ec2 create-tags --resources $psubnetId --tags Key=Name,Value=CLI-PUBLIC-SUBNET
privateId=$(aws ec2 create-subnet --vpc-id $vpcId --cidr-block 10.0.2.0/24 --query 'Subnet.SubnetId' --output text)
#echo $privateId
echo "Tagging private subnet"
aws ec2 create-tags --resources $privateId --tags Key=Name,Value=CLI-PRIVATE-SUBNET

####################    ROUTE TABLE    #########################
routeTableId=$(aws ec2 create-route-table --vpc-id $vpcId --query 'RouteTable.RouteTableId' --output text)
#echo $routeTableId
echo "Tagging route table with Name"
aws ec2 create-tags --resources $routeTableId --tags Key=Name,Value=CLI-ROUTE
aws ec2 associate-route-table --route-table-id $routeTableId --subnet-id $psubnetId
aws ec2 create-route --route-table-id $routeTableId --destination-cidr-block 0.0.0.0/0 --gateway-id $internetGatewayId

echo "Route table is created"

##################### SECURITY GROUP  ##################################
sg=$(aws ec2 create-security-group --group-name CLI-SecuirtyGRP --description "my-security-group" --vpc-id $vpcId --query 'GroupId' --output text)
#echo $sg

aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $sg --protocol tcp --port 80 --cidr 0.0.0.0/0

echo "Security group is created"

###################  LAUNCH INSTANCE ##################################
echo "###################  LAUNCH INSTANCE ##################################"
aws ec2 run-instances --image-id ami-0b3046001e1ba9a99 --count 1 --instance-type t2.micro --key-name clikey --security-group-ids $sg --subnet-id $psubnetId --associate-public-ip-address
instance=$(aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId')
#echo $instance
echo "##########################################################################"
echo "Tagging Server with a Name"

aws ec2 create-tags --resources $instance --tags Key=Name,Value=MyServer

# ################  Logging into the Machine ###################

echo " # login=$(aws ec2 describe-instances --query 'Reservations[].Instances[].[PublicIpAddress]') "
echo " # ssh -i clikey ec2-user@$login "


######################    EEND    #######################################