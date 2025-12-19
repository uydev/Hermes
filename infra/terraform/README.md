# Hermes Backend Infrastructure (Terraform)

This directory contains Terraform configuration to deploy the Hermes backend to AWS EC2.

## Prerequisites

1. **AWS CLI configured** with your personal account:
   ```bash
   export AWS_PROFILE=hephaestus-fleet
   aws sts get-caller-identity
   ```

2. **Terraform installed** (>= 1.0):
   ```bash
   terraform version
   ```

## Quick Start

### Step 1: Initialize Terraform

```bash
cd infra/terraform
terraform init
```

This downloads the AWS provider plugin.

### Step 2: Review What Will Be Created

```bash
terraform plan
```

This shows you:
- EC2 t3.micro instance (Ubuntu 22.04)
- Security group (HTTPS + SSH)
- Elastic IP address
- Estimated costs

### Step 3: Apply Infrastructure

```bash
terraform apply
```

Type `yes` when prompted. This will:
- Create the EC2 instance (~5 minutes)
- Assign an Elastic IP
- Install Docker, Nginx, Certbot

### Step 4: Get Your Public IP

After `terraform apply` completes, you'll see output like:

```
instance_public_ip = "54.123.45.67"
backend_url = "https://54.123.45.67"
ssh_command = "ssh ubuntu@54.123.45.67"
```

**Save this IP address** - you'll need it for DNS configuration.

## Next Steps (After Terraform)

1. **Configure DNS** - Point your domain to the IP:
   - Route 53: Create A record `api.yourdomain.com` → `<instance_public_ip>`
   - Or Cloudflare: Add A record

2. **SSH to Instance**:
   ```bash
   ssh ubuntu@<instance_public_ip>
   ```

3. **Set up SSL Certificate**:
   ```bash
   sudo certbot --nginx -d api.yourdomain.com
   ```

4. **Deploy Backend** (see deployment guide)

## Cost Estimate

- **EC2 t3.micro**: Free for 12 months (750 hours/month), then ~$7/month
- **Elastic IP**: Free while instance is running
- **Data Transfer**: First 100 GB/month free, then ~$0.09/GB
- **Total**: **$0/month (first year)**, then **~$7-10/month**

## Variables

You can customize in `variables.tf`:
- `aws_region`: Default is `eu-west-3` (Paris)
- `instance_type`: Default is `t3.micro`

Override via command line:
```bash
terraform apply -var="instance_type=t3.small"
```

## Cleanup

To destroy all resources:
```bash
terraform destroy
```

⚠️ **Warning**: This will delete the EC2 instance and all data on it!

## Troubleshooting

### Terraform can't find AWS credentials
```bash
export AWS_PROFILE=hephaestus-fleet
aws sts get-caller-identity
```

### Can't SSH to instance
- Check security group allows port 22
- Verify you have the correct key pair (if using one)
- Check instance is running: `aws ec2 describe-instances --instance-ids <id>`

### Instance creation fails
- Check AWS account limits (EC2 instance limit)
- Verify default VPC exists: `aws ec2 describe-vpcs --filters "Name=isDefault,Values=true"`
