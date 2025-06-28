#!/bin/bash

# AWS Infrastructure Resource Map Generator
# Run this script after terraform apply to generate visualizations

set -e

echo "🗺️  AWS Infrastructure Resource Map Generator"
echo "=============================================="

# Check if terraform is initialized
if [ ! -d ".terraform" ]; then
    echo "❌ Terraform not initialized. Run 'terraform init' first."
    exit 1
fi

# Check if infrastructure is deployed
if ! terraform show > /dev/null 2>&1; then
    echo "❌ No Terraform state found. Deploy infrastructure first with 'terraform apply'."
    exit 1
fi

echo "✅ Terraform state detected. Generating resource maps..."

# Create output directory
mkdir -p resource-maps
cd resource-maps

echo ""
echo "📊 1. Generating Terraform Dependency Graph..."
if command -v dot &> /dev/null; then
    terraform graph | dot -Tpng > terraform-graph.png
    echo "✅ Terraform graph saved to: resource-maps/terraform-graph.png"
else
    echo "⚠️  Graphviz not installed. Install with: brew install graphviz (macOS) or apt-get install graphviz (Linux)"
    terraform graph > terraform-graph.dot
    echo "✅ Terraform graph DOT file saved to: resource-maps/terraform-graph.dot"
    echo "   Install Graphviz and run: dot -Tpng terraform-graph.dot > terraform-graph.png"
fi

echo ""
echo "📋 2. Generating Resource Summary..."
cat > resource-summary.md << 'EOF'
# AWS Infrastructure Resource Summary

## Generated on: $(date)

### VPC Information
EOF

# Get VPC information
VPC_ID=$(cd .. && terraform output -raw vpc_id 2>/dev/null || echo "Not available")
echo "- **VPC ID**: $VPC_ID" >> resource-summary.md
echo "- **VPC CIDR**: $(cd .. && terraform output -raw vpc_cidr_block 2>/dev/null || echo "10.0.0.0/16")" >> resource-summary.md

echo "" >> resource-summary.md
echo "### Subnets" >> resource-summary.md

# Get subnet information
PUBLIC_SUBNET_1=$(cd .. && terraform output -raw public_subnet_1_id 2>/dev/null || echo "Not available")
PUBLIC_SUBNET_2=$(cd .. && terraform output -raw public_subnet_2_id 2>/dev/null || echo "Not available")
PRIVATE_SUBNET_1=$(cd .. && terraform output -raw private_subnet_1_id 2>/dev/null || echo "Not available")
PRIVATE_SUBNET_2=$(cd .. && terraform output -raw private_subnet_2_id 2>/dev/null || echo "Not available")

echo "- **Public Subnet 1**: $PUBLIC_SUBNET_1" >> resource-summary.md
echo "- **Public Subnet 2**: $PUBLIC_SUBNET_2" >> resource-summary.md
echo "- **Private Subnet 1**: $PRIVATE_SUBNET_1" >> resource-summary.md
echo "- **Private Subnet 2**: $PRIVATE_SUBNET_2" >> resource-summary.md

echo "" >> resource-summary.md
echo "### Instances" >> resource-summary.md

# Get instance information
BASTION_ID=$(cd .. && terraform output -raw bastion_instance_id 2>/dev/null || echo "Not available")
BASTION_IP=$(cd .. && terraform output -raw bastion_public_ip 2>/dev/null || echo "Not available")
WEB_ID=$(cd .. && terraform output -raw instance_id 2>/dev/null || echo "Not available")
WEB_PRIVATE_IP=$(cd .. && terraform output -raw instance_private_ip 2>/dev/null || echo "Not available")

echo "- **Bastion Host**: $BASTION_ID (Public IP: $BASTION_IP)" >> resource-summary.md
echo "- **Web Server**: $WEB_ID (Private IP: $WEB_PRIVATE_IP)" >> resource-summary.md

echo "" >> resource-summary.md
echo "### NAT Gateways" >> resource-summary.md

# Get NAT Gateway information
NAT_GATEWAYS=$(cd .. && terraform output -json nat_gateway_ids 2>/dev/null | jq -r '.[]' 2>/dev/null || echo "Not available")
if [ "$NAT_GATEWAYS" != "Not available" ]; then
    echo "$NAT_GATEWAYS" | while read -r nat_id; do
        echo "- **NAT Gateway**: $nat_id" >> resource-summary.md
    done
else
    echo "- **NAT Gateways**: Not available" >> resource-summary.md
fi

echo "✅ Resource summary saved to: resource-maps/resource-summary.md"

echo ""
echo "🔧 3. Generating AWS CLI Commands for Resource Discovery..."
cat > aws-resource-commands.sh << EOF
#!/bin/bash
# AWS CLI commands to explore deployed resources

echo "🔍 AWS Resource Discovery Commands"
echo "=================================="

if [ "$VPC_ID" != "Not available" ]; then
    echo ""
    echo "📡 VPC Resources:"
    echo "aws ec2 describe-vpcs --vpc-ids $VPC_ID"
    echo ""
    echo "🌐 Subnets:"
    echo "aws ec2 describe-subnets --filters \"Name=vpc-id,Values=$VPC_ID\""
    echo ""
    echo "🔒 Security Groups:"
    echo "aws ec2 describe-security-groups --filters \"Name=vpc-id,Values=$VPC_ID\""
    echo ""
    echo "🚪 NAT Gateways:"
    echo "aws ec2 describe-nat-gateways --filter \"Name=vpc-id,Values=$VPC_ID\""
    echo ""
    echo "🖥️  EC2 Instances:"
    echo "aws ec2 describe-instances --filters \"Name=vpc-id,Values=$VPC_ID\""
    echo ""
    echo "📊 Route Tables:"
    echo "aws ec2 describe-route-tables --filters \"Name=vpc-id,Values=$VPC_ID\""
else
    echo "VPC ID not available. Deploy infrastructure first."
fi
EOF

chmod +x aws-resource-commands.sh
echo "✅ AWS CLI commands saved to: resource-maps/aws-resource-commands.sh"

echo ""
echo "🎨 4. Creating ASCII Architecture Diagram..."
cat > architecture-diagram.txt << 'EOF'
                    AWS Multi-AZ Infrastructure
    ┌─────────────────────────────────────────────────────────────────┐
    │                        Internet Gateway                         │
    └─────────────────────────┬───────────────────────────────────────┘
                              │
    ┌─────────────────────────────────────────────────────────────────┐
    │                    VPC (10.0.0.0/16)                           │
    │                                                                 │
    │  ┌─────────────────┐              ┌─────────────────┐          │
    │  │  Public Subnet  │              │  Public Subnet  │          │
    │  │   10.0.1.0/24   │              │   10.0.2.0/24   │          │
    │  │   (eu-north-1a) │              │   (eu-north-1b) │          │
    │  │                 │              │                 │          │
    │  │  ┌─────────────┐│              │┌─────────────┐  │          │
    │  │  │ Bastion     ││              ││ NAT Gateway ││  │          │
    │  │  │ Host        ││              ││             ││  │          │
    │  │  └─────────────┘│              │└─────────────┘  │          │
    │  └─────────────────┘              └─────────────────┘          │
    │           │                                │                    │
    │  ┌─────────────────┐              ┌─────────────────┐          │
    │  │ Private Subnet  │              │ Private Subnet  │          │
    │  │   10.0.3.0/24   │              │   10.0.4.0/24   │          │
    │  │   (eu-north-1a) │              │   (eu-north-1b) │          │
    │  │                 │              │                 │          │
    │  │  ┌─────────────┐│              │                 │          │
    │  │  │ Web Server  ││              │  (Available for │          │
    │  │  │             ││              │   future apps)  │          │
    │  │  └─────────────┘│              │                 │          │
    │  └─────────────────┘              └─────────────────┘          │
    └─────────────────────────────────────────────────────────────────┘

    Security Groups:
    ┌─────────────────┬─────────────────┬─────────────────┬─────────────────┐
    │   Web SG        │   Bastion SG    │   Private SG    │  Database SG    │
    │ HTTP/HTTPS      │ SSH from        │ SSH from        │ MySQL/PostgreSQL│
    │ from Internet   │ Internet        │ Bastion         │ from App Tiers  │
    │ SSH from        │                 │ App ports from  │                 │
    │ Bastion         │                 │ Web tier        │                 │
    └─────────────────┴─────────────────┴─────────────────┴─────────────────┘
EOF

echo "✅ ASCII diagram saved to: resource-maps/architecture-diagram.txt"

echo ""
echo "📸 5. Screenshot Guide..."
cat > screenshot-guide.md << 'EOF'
# AWS Console Screenshot Guide

## 🎯 Best Screenshots to Take:

### 1. VPC Resource Map (MOST IMPORTANT)
**Location**: AWS Console → VPC → Your VPC → Resource map tab
**URL**: https://console.aws.amazon.com/vpc/home#vpcs:
**What to capture**: Complete network topology with subnets, gateways, and connections

### 2. EC2 Instances Overview
**Location**: AWS Console → EC2 → Instances
**What to capture**: List of all instances with their subnet placement

### 3. Security Groups Rules
**Location**: AWS Console → EC2 → Security Groups
**What to capture**: Inbound and outbound rules for each security group

### 4. NAT Gateways Status
**Location**: AWS Console → VPC → NAT Gateways
**What to capture**: NAT Gateway status and subnet associations

### 5. Route Tables
**Location**: AWS Console → VPC → Route Tables
**What to capture**: Routing configuration for each subnet

### 6. Subnets Overview
**Location**: AWS Console → VPC → Subnets
**What to capture**: Subnet CIDR blocks and availability zones

## 📱 Pro Screenshot Tips:

1. **Use full-screen browser** for maximum detail
2. **Zoom browser to 80-90%** to fit more content
3. **Use browser's screenshot tools** for clean captures
4. **Take multiple screenshots** if content doesn't fit
5. **Add annotations** after taking screenshots

## 🔗 Direct Console Links (after deployment):

- VPC Console: https://console.aws.amazon.com/vpc/home
- EC2 Console: https://console.aws.amazon.com/ec2/home
- Systems Manager: https://console.aws.amazon.com/systems-manager/inventory
- AWS Config: https://console.aws.amazon.com/config/home
EOF

echo "✅ Screenshot guide saved to: resource-maps/screenshot-guide.md"

cd ..

echo ""
echo "🎉 Resource Map Generation Complete!"
echo "======================================"
echo ""
echo "📁 Generated files in 'resource-maps/' directory:"
echo "   • terraform-graph.png (or .dot) - Terraform dependency graph"
echo "   • resource-summary.md - Infrastructure summary"
echo "   • aws-resource-commands.sh - AWS CLI exploration commands"
echo "   • architecture-diagram.txt - ASCII architecture diagram"
echo "   • screenshot-guide.md - AWS Console screenshot guide"
echo ""
echo "🚀 Next Steps:"
echo "   1. Open AWS Console and take screenshots using the guide"
echo "   2. Run aws-resource-commands.sh for CLI exploration"
echo "   3. View the ASCII diagram for quick reference"
echo "   4. Use terraform-graph.png for technical documentation"
echo ""
echo "📖 For detailed visualization methods, see: visualization-guide.md" 