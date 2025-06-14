# Terraform Backend Configuration for Remote State
# 
# SETUP PROCESS:
# 1. First run: Keep this commented out, run `terraform apply` to create state infrastructure
# 2. Note the bucket name and table name from the output
# 3. Uncomment the backend block below and update the bucket name
# 4. Run `terraform init` to migrate state to remote backend
# 5. Optional: Delete state-setup.tf after migration (or keep for reference)

# Remote backend configuration
# We'll enable this after creating the state infrastructure
# terraform {
#   backend "s3" {
#     bucket         = "BUCKET_NAME_FROM_OUTPUT"  # Will be filled after first apply
#     key            = "terraform.tfstate"
#     region         = "eu-north-1"
#     encrypt        = true
#     dynamodb_table = "rs-aws-devops-terraform-locks"
#   }
# }

# STEP 2: After creating infrastructure, uncomment above and update bucket name

 