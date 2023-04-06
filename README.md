# Infrastructure as Code
_This project focuses on Creation and Management of Cloud Infra (AWS), following DevSecOps best practices_

### To run code:
**Prerequisite:** AWS CLI, Terraform

**Commands**
1. Setup AWS credentials:
    aws configure
2. export AWS_PROFILE=_profilename_ (Linux/Mac) _or_ setx AWS_PROFILE _profilename_ (Windows)
3. terraform init
4. terraform plan
5. terraform apply -var-file="var.tfvars" --auto-approve
6. terrafrom destroy -var-file="var.tfvars" --auto-approve (to destroy above created infra)

### Working of the code:
1. Creates **VPC** in given region with max 3 _Public_ and _Private_ **Subnets**, along with **RouteTables**, **Internet Gateway**
2. **Auto Scaler** initializes **EC2** instances (min 1 and max 3) based on _Avg CPU Utilisation_
3. **Auto Scaler** uses **Launch Config** that defines AMI image to be used, size of volume and User Data
4. Traffic is routed to these instances through **Load Balancer**
5. **EC2 Instances** are launched in public subnets wherease **RDS** is in private subnet
6. **EC2** accepts traffic only through **Load Balancer** and **RDS** accepts only through **EC2 Instances**
7. **IAM Role and Policy** and **Security Groups** gets created to support above requirement
8. **S3 Bucket** is used to store files with required permissions as per application requirement
9. **CloudWatch** is used for _logging, metrics monitoring and to trigger alarms in case of breach in threshold_
10. **Route53** creates A record for given domain name and creates alias for **Load Balancer** DNS Name



_Author: Souvik Dinda_