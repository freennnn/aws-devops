# AWS DevOps Infrastructure with Terraform

A complete AWS DevOps infrastructure setup using Terraform with automated CI/CD via GitHub Actions. This project demonstrates modern infrastructure-as-code practices with secure authentication, remote state management, and automated deployments.

## 🏗️ Infrastructure Overview

This Terraform configuration creates:

- **VPC**: Isolated network environment (10.0.0.0/16)
- **EC2**: t3.micro instance with Amazon Linux 2023, Node.js 22, PM2, and Caddy reverse proxy
- **S3**: Application data storage with versioning and encryption
- **IAM**: Roles and policies for EC2-S3 access and GitHub Actions
- **Security Groups**: Network access control (HTTP/HTTPS/SSH)
- **Remote State**: S3 backend with DynamoDB locking

## 🚀 Quick Start

### Prerequisites
- AWS CLI configured with appropriate permissions
- Terraform >= 1.0.0 installed
- Git and GitHub account
- An AWS key pair (optional, for SSH access)

### 1. Clone and Configure
```bash
git clone <your-repo-url>
cd aws-devops

# Copy the example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
nano terraform.tfvars
```

### 2. Required Changes in terraform.tfvars
- `ssh_cidr_blocks`: Replace with your IP address for security
- `app_bucket_name`: Make it globally unique (add your name/identifier)
- `key_name`: Your AWS key pair name (optional, for SSH access)
- `aws_region`: Your preferred AWS region

### 3. Deploy Infrastructure
```bash
# Initialize Terraform
terraform init

# Review the plan
terraform plan

# Deploy
terraform apply
```

## 🔄 Remote State Setup

### Why Remote State?
- **Team Collaboration**: Multiple people can work on the same infrastructure
- **State Locking**: Prevents conflicts when multiple people run Terraform
- **Backup**: State is safely stored in AWS, not just on your computer
- **CI/CD Ready**: Automated pipelines can access the state

### Setup Process

#### Step 1: Create State Infrastructure
The `state-setup.tf` file contains the infrastructure needed for remote state:

```bash
# Initialize and apply to create state infrastructure
terraform init
terraform plan
terraform apply
```

#### Step 2: Note the Output Values
After applying, copy the bucket name from the output:
```
terraform_state_bucket = "rs-aws-devops-terraform-state-abc12345"
terraform_locks_table = "rs-aws-devops-terraform-locks"
```

#### Step 3: Configure Backend
1. Open `backend.tf`
2. Uncomment the terraform block (remove the `#` symbols)
3. Replace `rs-aws-devops-terraform-state-XXXXXXXX` with your actual bucket name

#### Step 4: Migrate to Remote State
```bash
# Reinitialize Terraform with the new backend
terraform init
# Answer "yes" when asked to copy existing state
```

#### Step 5: Cleanup (Optional)
```bash
# Remove the setup file since infrastructure is created
rm state-setup.tf
```

### Security Features
The setup includes:
- **Encryption**: State files are encrypted in S3
- **Versioning**: Previous state versions are kept for rollback
- **Access Control**: Bucket blocks all public access
- **State Locking**: DynamoDB prevents concurrent modifications

### Cost Impact
- **S3**: ~$0.023 per GB per month (state files are tiny)
- **DynamoDB**: Pay-per-request (very cheap for state locking)
- **Total**: Usually less than $1/month

### Working with Remote State
Once set up:
- `terraform plan/apply` works exactly the same
- State is automatically synced to S3
- Multiple team members can collaborate safely
- State locking prevents conflicts

### Important Notes
1. **Never delete** the state bucket accidentally
2. **Keep backups** of important state files
3. **Restrict access** to the state bucket (contains sensitive info)
4. **Use different buckets** for different environments (dev/prod)

## 🔐 Authentication Methods

This project supports two authentication methods for GitHub Actions:

### Current: IAM Role with OIDC (Recommended)
✅ **Currently Active** - More secure, uses temporary credentials

**Benefits:**
- Temporary credentials (1-hour tokens)
- No permanent secrets to manage
- AWS best practice for CI/CD
- Automatic credential rotation

**Setup:**
The IAM role and OIDC provider are created automatically by `github-actions-iam.tf`.

**Role ARN:** `arn:aws:iam::391720156721:role/GithubActionsRole`

### Alternative: IAM User with Access Keys
❌ **Commented Out** - Simpler but less secure

**Benefits:**
- Simple setup
- Good for learning/development
- Direct credential management

**To Switch Back:**
1. Uncomment the `env:` sections in `.github/workflows/terraform.yml`
2. Comment out the `aws-actions/configure-aws-credentials` step
3. Add AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to GitHub secrets

## 🤖 GitHub Actions CI/CD

### Workflow Overview
The workflow consists of 3 jobs:

1. **terraform-check**: Format checking and validation
2. **terraform-plan**: Planning deployments 
3. **terraform-apply**: Deploying infrastructure (only on main/master/staging branches)

### Branch Strategy
- **task-1**: Development branch for testing
- **staging**: Testing environment for apply operations
- **main**: Production environment

### Required GitHub Secrets (for Access Key method)
Go to `Settings > Secrets and variables > Actions > Repository secrets`:
```
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
```

### GitHub Variables (Optional)
Most variables use good defaults. Only set these if you need to override:

Go to `Settings > Secrets and variables > Actions > Variables`:
```bash
TF_VAR_PROJECT_NAME=rs-aws-devops
TF_VAR_AWS_REGION=eu-north-1
TF_VAR_APP_BUCKET_NAME=rs-aws-devops-app-bucket-freen
TF_VAR_KEY_NAME=rs-devops-key
TF_VAR_SSH_CIDR_BLOCKS=["0.0.0.0/0"]
```

### Variable Priority Order
Terraform uses this priority (highest to lowest):
1. **GitHub Actions Environment Variables** (`TF_VAR_*`)
2. **terraform.tfvars file** (your local values)
3. **Variable defaults** (in variables.tf)

### Production Environment Protection
1. Go to `Settings > Environments`
2. Create a new environment called `production`
3. Configure protection rules:
   - ✅ Required reviewers
   - ✅ Wait timer (optional)
   - ✅ Deployment branches (restrict to main/master)

### Workflow Behavior

**On Pull Requests:**
- ✅ Runs `terraform-check` (format + validate)
- ✅ Runs `terraform-plan` 
- ✅ Comments the plan output on the PR
- ❌ Does NOT run `terraform-apply`

**On Push to main/master/staging:**
- ✅ Runs `terraform-check`
- ✅ Runs `terraform-plan`
- ✅ Runs `terraform-apply` (with environment protection)

### Security Best Practices
1. **AWS Credentials**: Use IAM role with minimal required permissions
2. **Environment Protection**: Require manual approval for production deployments
3. **Branch Protection**: Enable branch protection rules on main/master
4. **Secret Scanning**: Enable GitHub's secret scanning
5. **Dependency Updates**: Use Dependabot for action updates

## 📁 Project Structure

```
aws-devops/
├── modules/
│   ├── networking/          # VPC, subnets, security groups
│   ├── compute/            # EC2 instances, user data
│   └── storage/            # S3 buckets, IAM roles
├── .github/workflows/      # GitHub Actions CI/CD
├── main.tf                 # Root module configuration
├── variables.tf            # Variable definitions
├── terraform.tfvars       # Variable values (not in git)
├── backend.tf             # Remote state configuration
├── github-actions-iam.tf  # OIDC and IAM role for GitHub Actions
└── outputs.tf             # Output values
```

## 🔒 Security Features

- **Network Security**: VPC with controlled access via security groups
- **SSH Access**: Key-based authentication with configurable CIDR blocks
- **S3 Encryption**: Server-side encryption enabled
- **IAM Roles**: Least privilege access for EC2 and GitHub Actions
- **State Security**: Encrypted remote state with access controls
- **HTTPS**: Caddy reverse proxy with automatic SSL certificates

## 💰 Cost Estimate

Most resources are Free Tier eligible:
- **EC2 t3.micro**: 750 hours/month free
- **S3**: 5GB storage free
- **EBS**: 30GB free
- **DynamoDB**: 25GB free
- **Estimated cost**: $0-2/month

## 🔧 Local Development

### Format and Validate
```bash
# Format code
terraform fmt -recursive

# Validate configuration
terraform validate

# Plan changes
terraform plan

# Apply changes
terraform apply
```

### SSH Access
```bash
# Connect to EC2 instance
ssh -i ~/.ssh/your-key.pem ec2-user@<instance-public-ip>

# Check application status
sudo systemctl status caddy
pm2 status
```

### Local Testing Before Push
```bash
# Format check
terraform fmt -check -recursive

# Validate
terraform init
terraform validate

# Plan
terraform plan
```

## 🆘 Troubleshooting

### Common Issues

1. **"terraform fmt -check" fails**
   ```bash
   terraform fmt -recursive
   git add . && git commit -m "Fix formatting"
   ```

2. **AWS credentials invalid**
   - Check secrets are correctly set in GitHub
   - Verify IAM role permissions

3. **Backend initialization fails**
   - Ensure S3 bucket and DynamoDB table exist
   - Check bucket name in `backend.tf`

4. **Bucket name conflicts**
   - Make `app_bucket_name` more unique in `terraform.tfvars`

5. **Permission errors**
   - Check AWS IAM permissions
   - Verify GitHub secrets are correctly set

6. **Instance launch failures**
   - Try different instance type or region
   - Check AWS service limits

7. **State lock errors**
   ```bash
   # Lock auto-releases after 15 minutes, or force unlock:
   terraform force-unlock LOCK_ID
   ```

8. **Backend configuration changed**
   ```bash
   terraform init -reconfigure
   ```

### Debug Steps
1. Check the Actions tab for detailed logs
2. Verify all secrets and variables are configured
3. Test locally with the same Terraform version (1.5.0)
4. Review AWS CloudFormation events for detailed errors
5. Enable debug logging: `TF_LOG=DEBUG terraform apply`
6. Ensure your AWS credentials have sufficient permissions

### Getting Help
- Check AWS CloudFormation events for detailed errors
- Review Terraform logs with debug enabled
- Ensure your AWS credentials have sufficient permissions
- Test the same commands locally before pushing to GitHub

## 🔄 Migration and Rollback

### Switching Authentication Methods

**From Access Keys to IAM Role:**
1. Ensure `github-actions-iam.tf` is applied
2. Update workflow to use `aws-actions/configure-aws-credentials@v4`
3. Comment out `env:` sections with AWS credentials
4. Test on staging branch first

**From IAM Role to Access Keys:**
1. Create IAM user with programmatic access
2. Add AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY to GitHub secrets
3. Uncomment `env:` sections in workflow
4. Comment out `aws-actions/configure-aws-credentials` step

### Rollback to Local State
1. Comment out the backend block in `backend.tf`
2. Run `terraform init`
3. Answer "yes" to copy state back locally

### Want to go back to local state?
1. Comment out the backend block in `backend.tf`
2. Run `terraform init`
3. Answer "yes" to copy state back locally

## 📚 Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Free Tier Details](https://aws.amazon.com/free/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch from `task-1`
3. Make your changes
4. Test locally and on staging
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

**Note**: This infrastructure is designed for learning and development. For production use, consider additional security measures, monitoring, and backup strategies.