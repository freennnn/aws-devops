#!/bin/bash

# Make all scripts executable
# This script ensures all shell scripts have proper execution permissions

set -e

echo "🔧 Setting execution permissions on all scripts..."

# Main directories containing scripts
SCRIPT_DIRS=(
    "scripts"
    "."
)

# Find and make all .sh files executable
for dir in "${SCRIPT_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        echo "📁 Processing directory: $dir"
        
        # Find all .sh files and make them executable
        find "$dir" -name "*.sh" -type f -exec chmod +x {} \; -print | while read file; do
            echo "  ✅ Made executable: $file"
        done
    fi
done

# Specific scripts that should be executable
SCRIPTS=(
    "scripts/setup-sonarqube.sh"
    "scripts/setup-docker-registry.sh"
    "scripts/setup-notifications.sh"
    "scripts/verify-deployment.sh"
    "scripts/deploy-flask-app.sh"
    "scripts/cleanup-flask-app.sh"
    "scripts/deploy-jenkins.sh"
    "scripts/cleanup-jenkins.sh"
    "make-scripts-executable.sh"
    "make-executable.sh"
    "generate-resource-map.sh"
)

echo ""
echo "🎯 Setting permissions on specific scripts..."

for script in "${SCRIPTS[@]}"; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        echo "  ✅ Made executable: $script"
    else
        echo "  ⚠️  Not found: $script"
    fi
done

echo ""
echo "🔍 Verifying script permissions..."

# List all executable scripts
echo "📋 Executable scripts found:"
find . -name "*.sh" -type f -executable | sort | while read file; do
    echo "  ✅ $file"
done

echo ""
echo "✅ All scripts are now executable!"
echo ""
echo "🚀 You can now run the following commands:"
echo "  ./scripts/setup-sonarqube.sh"
echo "  ./scripts/setup-docker-registry.sh"
echo "  ./scripts/setup-notifications.sh --all"
echo "  ./scripts/verify-deployment.sh"
echo "" 