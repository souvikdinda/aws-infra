## VPC Creation in AWS
_Aim of this assignment is to learn basics of AWS_

**Code in this repo does the following:**
1. Creates a VPC
2. Checks for availability zones for given region and creates public and private subnets for each region (max 3)
3. Creates Route Tables and Internet Gateway for public subnets


**To run code:**
Prerequisite: AWS CLI, terraform

**Commands**
1. Setup AWS credentials:
    aws configure
2. export AWS_PROFILE=_profilename_
3. terraform init
4. terraform plan
5. terraform apply -var "region=_region-name_"
6. terrafrom destroy (to delete above created VPC)


_Author: Souvik Dinda_