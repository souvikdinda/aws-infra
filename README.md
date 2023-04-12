# Infrastructure as Code (AWS)
---------------------------------------------------------------------------------------------------------

### Summary
-----------------------

_This project focuses on Creation and Management of Cloud Infra (AWS), following DevSecOps best practices_

-   Creates [VPC](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html) in given region with _Public_ and _Private_ [Subnets](https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html), along with [RouteTables](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html), [Internet Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html)
-   [Auto Scaler](https://docs.aws.amazon.com/autoscaling/ec2/userguide/what-is-amazon-ec2-auto-scaling.html) initializes [EC2](https://docs.aws.amazon.com/ec2/?icmpid=docs_homepage_featuredsvcs) instances (min 1 and max 3) based on _Avg CPU Utilisation_
-   **EC2** instances are built on custom [AMI](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/AMIs.html) using [Packer](https://packer.io/) 
-   **Auto Scaler** uses [Launch Template](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-launch-templates.html) that defines AMI image to be used, size of volume and User Data
-   Traffic is routed to these instances through [Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html)
-   **EC2** Instances are launched in public subnets wherease [RDS](https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Welcome.html) is in private subnet
-   **EC2** accepts traffic only through **Load Balancer** and **RDS** accepts only through **EC2 Instances**
-   [IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html) Role and Policy and [Security Groups](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html) gets created to support above requirement
-   [S3 Bucket](https://docs.aws.amazon.com/AmazonS3/latest/userguide/Welcome.html) is used to store files with required permissions as per application requirement
9. [CloudWatch](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/WhatIsCloudWatch.html) is used for _logging, metrics monitoring and to trigger alarms in case of breach in threshold_
10. [Route53](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/Welcome.html) creates A record for given domain name and creates alias for **Load Balancer** DNS Name


### Architecture Diagram
-----------------------

![infra](https://user-images.githubusercontent.com/22276234/231334647-76481d35-bb97-43fb-af8a-c92d765d1e8b.jpg)


### Tools and Technologies
-----------------------

| Infrastructure        |   VPC, Route53, ALB, EC2, RDS, S3         |
|-----------------------|-------------------------------------------|
| Web Application       |   NodeJS, ExpressJS, MySQL, Sequelize     |
| Alerting and logging  |   statsd, CloudWatch                      |
| Custom AMI            |   Packer                                  |
| IaC Language          |   Terraform                               |

### CI/CD
-----------------------

-   [Github Actions](https://docs.github.com/en/actions/quickstart) gets triggered whenever Code is merged to `main` branch of **Web Application**
-   **Github Actions** will run Test cases and then run [Packer](https://www.packer.io/) code which will take artifact/zip of the latest code in branch and create custom AMI image on [Amazon Linux 2](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/amazon-linux-ami-basics.html) and make it available to use in AWS account
-   [Github Secrets](https://docs.github.com/en/actions/security-guides/encrypted-secrets) have been used to store sensitive credentials and keys
-   `terraform apply` will create **new Version** of **Launch Template** and update **Auto Scaling Group** which will deploy newly generated code on **EC2 instances** via [Instance Refresh](https://docs.aws.amazon.com/autoscaling/ec2/userguide/asg-instance-refresh.html)


### To run code:
-----------------------

**Prerequisite:** [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html), [Terraform](https://www.terraform.io/)


**Useful Commands**

1. Setup AWS credentials:
    ```
    aws configure
    ```
2. Set profile to environment variables:
    -   Linux/Mac
    ```
    export AWS_PROFILE= <profilename>
    ```
    -   Windows
    ```
    setx AWS_PROFILE <profilename>
    ```
3. Initialize Terraform:
    ```
    terraform init
    ```
4. Plan to apply changes:
    ```
    terraform plan
    ```
5. Apply terraform:
    ```
    terraform apply -var-file="var.tfvars" --auto-approve
    ```
6. Import SSL Certificate to AWS Certificate Manager using command:
    ```
    aws acm import-certificate --certificate fileb://path-to-file --private-key fileb://path-to-file --certificate-chain fileb://path-to-file
    ```
7. Create Load Balancer Listener using above imported certificate:
    ```
    aws elbv2 create-listener --load-balancer-arn <lb-arn> --protocol HTTPS --port 443 --certificates CertificateArn=<cert-arn> --default-actions Type=forward,TargetGroupArn=<lb-target-grp-arn>
    ```
8. To perfrom instance refresh:
    ```
    aws autoscaling start-instance-refresh --auto-scaling-group-name <auto scaling group name> --preferences MinHealthyPercentage=90,InstanceWarmup=60 --strategy Rolling 
    ```
9. `terrafrom destroy -var-file="var.tfvars" --auto-approve` (to destroy above created infra)




_Author: Souvik Dinda_