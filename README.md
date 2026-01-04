# AWS Application Load Balancer Terraform Infrastructure

This project provides a complete, production-ready Terraform configuration for deploying an AWS Application Load Balancer infrastructure with VPC, Auto Scaling Groups, and comprehensive monitoring.

## Architecture Overview

The infrastructure consists of the following components:

1. VPC with public and private subnets across 3 availability zones
2. Application Load Balancer in public subnets with HTTP/HTTPS listeners
3. Auto Scaling Group with EC2 instances in private subnets
4. NAT Gateways for private subnet internet access
5. Security Groups implementing least-privilege access
6. CloudWatch monitoring and alarms
7. S3 bucket for ALB access logs
8. Route53 DNS records
9. ACM SSL/TLS certificates
10. IAM roles and policies for EC2 instances

## Architecture Diagram

```
                                    Internet
                                       |
                                       |
                        +--------------+---------------+
                        |                              |
                        |         Route53 DNS          |
                        |    (app.example.com)         |
                        |                              |
                        +--------------+---------------+
                                       |
                                       |
                        +--------------v---------------+
                        |                              |
                        |    ACM SSL Certificate       |
                        |                              |
                        +--------------+---------------+
                                       |
                                       |
    +----------------------------------v-----------------------------------+
    |                                                                      |
    |                          AWS Region (us-east-1)                     |
    |                                                                      |
    |  +----------------------------------------------------------------+ |
    |  |                    VPC (10.0.0.0/16)                          | |
    |  |                                                                | |
    |  |  +------------------+  +------------------+  +---------------+ | |
    |  |  | Availability     |  | Availability     |  | Availability  | | |
    |  |  | Zone A           |  | Zone B           |  | Zone C        | | |
    |  |  |                  |  |                  |  |               | | |
    |  |  | +-------------+  |  | +-------------+  |  | +-----------+ | | |
    |  |  | | Public      |  |  | | Public      |  |  | | Public    | | | |
    |  |  | | Subnet      |  |  | | Subnet      |  |  | | Subnet    | | | |
    |  |  | | 10.0.0.0/24 |  |  | | 10.0.1.0/24 |  |  | |10.0.2.0/24| | | |
    |  |  | |             |  |  | |             |  |  | |           | | | |
    |  |  | |   +-----+   |  |  | |   +-----+   |  |  | | +-----+   | | | |
    |  |  | |   | NAT |   |  |  | |   | NAT |   |  |  | | | NAT |   | | | |
    |  |  | |   | GW  |   |  |  | |   | GW  |   |  |  | | | GW  |   | | | |
    |  |  | |   +--+--+   |  |  | |   +--+--+   |  |  | | +--+--+   | | | |
    |  |  | +------|------+  |  | +------|------+  |  | +----|------+ | | |
    |  |  |        |         |  |        |         |  |      |        | | |
    |  |  | +------v------+  |  | +------v------+  |  | +----v-----+ | | |
    |  |  | | Private     |  |  | | Private     |  |  | | Private  | | | |
    |  |  | | Subnet      |  |  | | Subnet      |  |  | | Subnet   | | | |
    |  |  | | 10.0.3.0/24 |  |  | | 10.0.4.0/24 |  |  | |10.0.5.0/2| | | |
    |  |  | |             |  |  | |             |  |  | |          | | | |
    |  |  | |  +-------+  |  |  | |  +-------+  |  |  | | +------+ | | | |
    |  |  | |  |  EC2  |  |  |  | |  |  EC2  |  |  |  | | | EC2  | | | | |
    |  |  | |  |Instance  |  |  | |  |Instance  |  |  | | |Instan| | | | |
    |  |  | |  +-------+  |  |  | |  +-------+  |  |  | | +------+ | | | |
    |  |  | |             |  |  | |             |  |  | |          | | | |
    |  |  | +-------------+  |  | +-------------+  |  | +----------+ | | |
    |  |  +------------------+  +------------------+  +--------------+ | |
    |  |                                                                | |
    |  |  +----------------------------------------------------------+  | |
    |  |  |                                                          |  | |
    |  |  |           Application Load Balancer (ALB)               |  | |
    |  |  |                                                          |  | |
    |  |  |  HTTP Listener (80) --> HTTPS Redirect (443)            |  | |
    |  |  |  HTTPS Listener (443) --> Target Group                  |  | |
    |  |  |                                                          |  | |
    |  |  +----------------------------------------------------------+  | |
    |  |                                                                | |
    |  |  +----------------------------------------------------------+  | |
    |  |  |                                                          |  | |
    |  |  |              Auto Scaling Group (ASG)                   |  | |
    |  |  |                                                          |  | |
    |  |  |  Min: 1-3  |  Desired: 1-3  |  Max: 3-10               |  | |
    |  |  |  Health Check: ELB                                      |  | |
    |  |  |  Scaling Policy: CPU-based                              |  | |
    |  |  |                                                          |  | |
    |  |  +----------------------------------------------------------+  | |
    |  |                                                                | |
    |  |  +----------------------------------------------------------+  | |
    |  |  |                  Security Groups                        |  | |
    |  |  |                                                          |  | |
    |  |  |  ALB SG: 0.0.0.0/0:80,443 --> ALB                       |  | |
    |  |  |  App SG: ALB SG:80 --> EC2 Instances                    |  | |
    |  |  |  EC2 SG: All outbound traffic                           |  | |
    |  |  |                                                          |  | |
    |  |  +----------------------------------------------------------+  | |
    |  |                                                                | |
    |  +----------------------------------------------------------------+ |
    |                                                                      |
    |  +----------------------------------------------------------------+ |
    |  |                    Supporting Services                         | |
    |  |                                                                | |
    |  |  +------------------+  +------------------+  +---------------+ | |
    |  |  |                  |  |                  |  |               | | |
    |  |  |  S3 Bucket       |  |  CloudWatch      |  |  SNS Topic    | | |
    |  |  |  (ALB Logs)      |  |  (Alarms &       |  |  (Alerts)     | | |
    |  |  |                  |  |   Dashboard)     |  |               | | |
    |  |  |  - Encrypted     |  |                  |  |  - Email      | | |
    |  |  |  - Lifecycle     |  |  - CPU Alarms    |  |    Endpoints  | | |
    |  |  |    Policy        |  |  - Health Alarms |  |               | | |
    |  |  |                  |  |  - HTTP Errors   |  |               | | |
    |  |  +------------------+  +------------------+  +---------------+ | |
    |  |                                                                | |
    |  |  +------------------+  +------------------+                   | |
    |  |  |                  |  |                  |                   | |
    |  |  |  IAM Roles       |  |  Systems Manager |                   | |
    |  |  |                  |  |  Parameter Store |                   | |
    |  |  |  - EC2 Instance  |  |                  |                   | |
    |  |  |    Profile       |  |  - Sensitive     |                   | |
    |  |  |  - SSM Access    |  |    Config        |                   | |
    |  |  |  - CloudWatch    |  |                  |                   | |
    |  |  |                  |  |                  |                   | |
    |  |  +------------------+  +------------------+                   | |
    |  |                                                                | |
    |  +----------------------------------------------------------------+ |
    |                                                                      |
    +----------------------------------------------------------------------+

Traffic Flow:

1. User Request:
   Internet --> Route53 DNS --> ALB (Public Subnets)

2. Load Balancing:
   ALB --> Target Group --> EC2 Instances (Private Subnets)

3. Outbound Traffic:
   EC2 Instances --> NAT Gateway --> Internet Gateway --> Internet

4. Monitoring:
   ALB --> CloudWatch Metrics --> CloudWatch Alarms --> SNS --> Email

5. Logging:
   ALB Access Logs --> S3 Bucket (Encrypted)

6. Instance Management:
   EC2 Instances --> IAM Role --> Systems Manager + CloudWatch

Security Layers:

1. Network Layer:
   - VPC isolation with public/private subnet separation
   - Security groups with least-privilege rules
   - Network ACLs (default)

2. Application Layer:
   - ALB with SSL/TLS termination
   - HTTP to HTTPS redirect
   - Health checks for instance availability

3. Data Layer:
   - Encrypted EBS volumes
   - Encrypted S3 bucket for logs
   - No public IP addresses on application instances

4. Access Layer:
   - IAM roles instead of access keys
   - Systems Manager for secure instance access
   - No SSH keys required (optional)

High Availability Features:

1. Multi-AZ deployment across 3 availability zones
2. Auto Scaling Group with health checks
3. ALB distributes traffic across healthy instances
4. NAT Gateways in each AZ for redundancy
5. Cross-zone load balancing enabled
6. Automatic instance replacement on failure

## Prerequisites

Before deploying this infrastructure, ensure you have the following:

1. AWS CLI version 2.0 or higher installed and configured
2. Terraform version 1.5 or higher installed
3. Valid AWS credentials with appropriate permissions
4. An existing Route53 hosted zone (if using DNS features)
5. An existing ACM certificate ARN (or create one manually first)
6. jq command-line tool for JSON processing

## Tool Installation

### Terraform Installation

For Linux:
```bash
wget https://releases.hashicorp.com/terraform/1.5.0/terraform_1.5.0_linux_amd64.zip
unzip terraform_1.5.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/
```

### AWS CLI Installation

For Linux:
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

## AWS Credentials Setup

Configure your AWS credentials using one of the following methods:

Method 1: AWS CLI Configuration
```bash
aws configure
```

Method 2: Environment Variables
```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

Method 3: AWS Profile
```bash
export AWS_PROFILE="your-profile-name"
```

## Project Structure

```
.
├── environments/
│   ├── dev/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── variables.tf
│   ├── staging/
│   │   ├── backend.tf
│   │   ├── main.tf
│   │   ├── terraform.tfvars
│   │   └── variables.tf
│   └── prod/
│       ├── backend.tf
│       ├── main.tf
│       ├── terraform.tfvars
│       └── variables.tf
├── modules/
│   ├── vpc/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── security-groups/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── asg/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── scripts/
│   ├── deploy.sh
│   ├── validate.sh
│   └── destroy.sh
└── README.md
```

## Deployment Instructions

### Step 1: Clone and Configure

1. Navigate to the project directory
2. Choose your target environment (dev, staging, or prod)
3. Edit the terraform.tfvars file in the corresponding environment directory

### Step 2: Customize Configuration

Edit the terraform.tfvars file for your chosen environment:

```hcl
project_name = "myapp"
environment = "dev"
aws_region = "us-east-1"
vpc_cidr = "10.0.0.0/16"
```

Update the backend.tf file with your S3 bucket and DynamoDB table names.

### Step 3: Deploy Infrastructure

Use the deployment script to deploy the infrastructure:

```bash
chmod +x scripts/deploy.sh
./scripts/deploy.sh dev
```

The script will:
1. Validate prerequisites
2. Initialize Terraform
3. Create a deployment plan
4. Apply the configuration
5. Display outputs

### Step 4: Verify Deployment

Run the validation script to check resource health:

```bash
chmod +x scripts/validate.sh
./scripts/validate.sh dev
```

## Customization Guide

### Modifying Instance Types

Edit the terraform.tfvars file:

```hcl
instance_type = "t3.medium"
```

### Adjusting Auto Scaling Parameters

```hcl
asg_min_size = 2
asg_max_size = 10
asg_desired_capacity = 3
```

### Changing Health Check Settings

```hcl
health_check_path = "/health"
health_check_interval = 30
health_check_timeout = 5
healthy_threshold = 2
unhealthy_threshold = 3
```

### Enabling Sticky Sessions

```hcl
enable_stickiness = true
stickiness_duration = 3600
```

## Environment-Specific Configurations

### Development Environment

Optimized for cost with minimal resources:
- 1-2 instances
- Smaller instance types (t3.small)
- Single NAT Gateway
- Reduced monitoring

### Staging Environment

Mirrors production with reduced capacity:
- 2-4 instances
- Medium instance types (t3.medium)
- NAT Gateway per AZ
- Full monitoring

### Production Environment

High availability and performance:
- 3-10 instances
- Larger instance types (t3.large or higher)
- NAT Gateway per AZ
- Deletion protection enabled
- Enhanced monitoring
- Multi-AZ deployment

## Monitoring and Alarms

The infrastructure includes CloudWatch alarms for:

1. ALB Unhealthy Host Count
2. ALB Target Response Time
3. ALB HTTP 5xx Errors
4. ALB HTTP 4xx Errors
5. ASG CPU Utilization

Alarms send notifications to SNS topics configured per environment.

## Security Considerations

1. Security groups implement least-privilege access
2. Private subnets for application instances
3. No hardcoded credentials in code
4. Encryption at rest for S3 logs
5. IAM roles with minimal required permissions
6. ALB access logs enabled
7. Systems Manager Parameter Store for sensitive data

## Cost Considerations

Estimated monthly costs for each environment:

Development: $150-250
- 1-2 t3.small instances
- 1 NAT Gateway
- 1 Application Load Balancer
- Minimal data transfer

Staging: $300-500
- 2-4 t3.medium instances
- 2-3 NAT Gateways
- 1 Application Load Balancer
- Moderate data transfer

Production: $800-1500+
- 3-10 t3.large instances
- 3 NAT Gateways
- 1 Application Load Balancer
- High availability configuration
- Enhanced monitoring

Cost optimization tips:
1. Use Reserved Instances for production
2. Enable Auto Scaling to match demand
3. Use single NAT Gateway for dev environment
4. Review CloudWatch logs retention
5. Enable S3 lifecycle policies for access logs

## Troubleshooting

### Issue: Terraform initialization fails

Solution: Ensure S3 bucket and DynamoDB table exist for backend state storage.

```bash
aws s3 mb s3://your-terraform-state-bucket
aws dynamodb create-table --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### Issue: Certificate validation timeout

Solution: Ensure DNS records for ACM certificate validation are created in Route53.

### Issue: Instances failing health checks

Solution: Verify security group rules allow ALB to reach instances on the application port.

### Issue: Cannot access application via ALB

Solution: Check that target group has healthy instances and security groups allow inbound traffic.

### Issue: Auto Scaling not working

Solution: Verify CloudWatch alarms are configured correctly and IAM roles have necessary permissions.

## Updating Infrastructure

To update the infrastructure:

1. Modify the terraform.tfvars or module configurations
2. Run the deployment script again
3. Review the plan carefully before applying
4. Monitor the update process

```bash
./scripts/deploy.sh prod
```

## Rolling Back Changes

If deployment fails or issues occur:

1. Review Terraform state
2. Use Terraform to revert to previous configuration
3. Or restore from state backup

```bash
cd environments/prod
terraform state pull > backup.tfstate
terraform apply -var-file=terraform.tfvars.backup
```

## Clean-up Instructions

To destroy all resources:

```bash
chmod +x scripts/destroy.sh
./scripts/destroy.sh dev
```

Warning: This will permanently delete all resources. Ensure you have backups of any important data.

For production environments, the script includes additional safety confirmations.

## Support and Maintenance

1. Regularly update Terraform and provider versions
2. Review AWS security bulletins
3. Monitor CloudWatch alarms and logs
4. Perform regular security audits
5. Keep AMIs updated with latest patches
6. Review and optimize costs monthly

## Additional Resources

1. Terraform AWS Provider Documentation: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
2. AWS Application Load Balancer Documentation: https://docs.aws.amazon.com/elasticloadbalancing/
3. AWS Auto Scaling Documentation: https://docs.aws.amazon.com/autoscaling/
4. Terraform Best Practices: https://www.terraform.io/docs/cloud/guides/recommended-practices/

## License

This project is provided as-is for infrastructure deployment purposes.
