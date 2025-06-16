# GitHub Actions Setup for Terraform CI/CD

This document explains how to set up the GitHub Actions workflow for automated Terraform deployments.

## Workflow Overview

The workflow consists of 3 jobs:

1. **terraform-check**: Format checking and validation
2. **terraform-plan**: Planning deployments 
3. **terraform-apply**: Deploying infrastructure (only on main/master branch)

## Required GitHub Secrets

You need to configure these secrets in your GitHub repository:

### AWS Credentials (Repository Secrets)
Go to `Settings > Secrets and variables > Actions > Repository secrets`:

```
AWS_ACCESS_KEY_ID=your_aws_access_key_id
AWS_SECRET_ACCESS_KEY=your_aws_secret_access_key
```

## Variable Configuration Strategy

### 📍 **All Variables in Our Project**

| Variable | Local Default | terraform.tfvars | GitHub Actions | Why in GitHub? |
|----------|---------------|------------------|----------------|----------------|
| `project_name` | `rs-aws-devops` | ✅ Set | ✅ **Required** | Environment-specific |
| `aws_region` | `eu-north-1` | ✅ Set | ✅ **Required** | Environment-specific |
| `vpc_cidr` | `10.0.0.0/16` | ✅ Set | ❌ Optional | Rarely changes |
| `public_subnet_cidr` | `10.0.1.0/24` | ✅ Set | ❌ Optional | Rarely changes |
| `ssh_cidr_blocks` | `["0.0.0.0/0"]` | ✅ Set | ✅ **Required** | Security-sensitive |
| `instance_type` | `t2.micro` | ✅ Set | ❌ Optional | Stable default |
| `key_name` | `null` | ✅ Set | ✅ **Required** | Environment-specific |
| `app_bucket_name` | `rs-aws-devops-app-bucket` | ✅ Set | ✅ **Required** | Must be unique |
| `environment` | `prod` | ✅ Set | ❌ Optional | Good default |
| `github_repository` | `freen/rs-aws-devops` | ❌ Uses default | ✅ **Required** | Repository-specific |

### 🎯 **Required GitHub Variables**
Go to `Settings > Secrets and variables > Actions > Variables`:

```bash
# REQUIRED - Environment-specific values
TF_VAR_PROJECT_NAME=rs-aws-devops
TF_VAR_AWS_REGION=eu-north-1
TF_VAR_APP_BUCKET_NAME=rs-aws-devops-app-bucket-freen
TF_VAR_KEY_NAME=rs-devops-key
TF_VAR_SSH_CIDR_BLOCKS=["0.0.0.0/0"]
TF_VAR_GITHUB_REPOSITORY=freen/rs-aws-devops
```

### 🔧 **Optional GitHub Variables**
These can be added if you want to override defaults:

```bash
# OPTIONAL - Override defaults if needed
TF_VAR_VPC_CIDR=10.0.0.0/16
TF_VAR_PUBLIC_SUBNET_CIDR=10.0.1.0/24
TF_VAR_INSTANCE_TYPE=t3.micro
TF_VAR_ENVIRONMENT=prod
```

## Variable Priority Order

Terraform uses this priority (highest to lowest):

1. **GitHub Actions Environment Variables** (`TF_VAR_*`)
2. **terraform.tfvars file** (your local values)
3. **Variable defaults** (in variables.tf)

## Production Environment Protection

The workflow uses a `production` environment for the apply job. To set this up:

1. Go to `Settings > Environments`
2. Create a new environment called `production`
3. Configure protection rules:
   - ✅ Required reviewers (add yourself or team members)
   - ✅ Wait timer (optional, e.g., 5 minutes)
   - ✅ Deployment branches (restrict to main/master)

## Workflow Behavior

### On Pull Requests:
- ✅ Runs `terraform-check` (format + validate)
- ✅ Runs `terraform-plan` 
- ✅ Comments the plan output on the PR
- ❌ Does NOT run `terraform-apply`

### On Push to main/master:
- ✅ Runs `terraform-check`
- ✅ Runs `terraform-plan`
- ✅ Runs `terraform-apply` (with environment protection)

## Security Best Practices

1. **AWS Credentials**: Use IAM user with minimal required permissions
2. **Environment Protection**: Require manual approval for production deployments
3. **Branch Protection**: Enable branch protection rules on main/master
4. **Secret Scanning**: Enable GitHub's secret scanning
5. **Dependency Updates**: Use Dependabot for action updates

## Troubleshooting

### Common Issues:

1. **"terraform fmt -check" fails**: Run `terraform fmt` locally and commit
2. **AWS credentials invalid**: Check secrets are correctly set
3. **Backend initialization fails**: Ensure S3 bucket and DynamoDB table exist
4. **Plan fails**: Check all required variables are set

### Debug Steps:

1. Check the Actions tab for detailed logs
2. Verify all secrets and variables are configured
3. Test locally with the same Terraform version (1.5.0)
4. Ensure your AWS credentials have sufficient permissions

## Local Testing

Before pushing, test locally:

```bash
# Format check
terraform fmt -check -recursive

# Validate
terraform init
terraform validate

# Plan
terraform plan
```

## Updating the Workflow

To modify the workflow:

1. Edit `.github/workflows/terraform.yml`
2. Test changes on a feature branch first
3. Use pull requests to review workflow changes
4. Monitor the first few runs after changes 