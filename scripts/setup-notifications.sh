#!/bin/bash

# Notification Setup Script
# This script helps configure notification systems for Jenkins pipelines

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local missing=0
    
    if ! command -v curl &> /dev/null; then
        log_error "curl is not installed"
        missing=1
    fi
    
    if ! command -v jq &> /dev/null; then
        log_warning "jq is not installed (optional but recommended)"
    fi
    
    # Check if Jenkins is running
    if ! curl -s -f "$JENKINS_URL" > /dev/null 2>&1; then
        log_error "Jenkins is not accessible at $JENKINS_URL"
        missing=1
    fi
    
    if [ $missing -eq 1 ]; then
        exit 1
    fi
    
    log_success "Prerequisites check passed"
}

create_slack_config() {
    log_info "Creating Slack notification configuration..."
    
    local slack_webhook_url=""
    local slack_channel=""
    local slack_team_domain=""
    
    echo "Enter your Slack webhook URL:"
    read -r slack_webhook_url
    
    echo "Enter your Slack channel (e.g., #devops-alerts):"
    read -r slack_channel
    
    echo "Enter your Slack team domain:"
    read -r slack_team_domain
    
    # Create Slack configuration template
    cat > "${SCRIPT_DIR}/slack-config.json" << EOF
{
  "webhook_url": "$slack_webhook_url",
  "channel": "$slack_channel",
  "team_domain": "$slack_team_domain",
  "username": "Jenkins Bot",
  "icon_emoji": ":jenkins:",
  "colors": {
    "success": "good",
    "failure": "danger",
    "unstable": "warning",
    "started": "#439FE0"
  }
}
EOF
    
    log_success "Slack configuration saved to slack-config.json"
    
    # Test Slack webhook
    test_slack_notification
}

test_slack_notification() {
    log_info "Testing Slack notification..."
    
    if [ ! -f "${SCRIPT_DIR}/slack-config.json" ]; then
        log_error "Slack configuration file not found"
        return 1
    fi
    
    local webhook_url=$(jq -r '.webhook_url' "${SCRIPT_DIR}/slack-config.json" 2>/dev/null || echo "")
    local channel=$(jq -r '.channel' "${SCRIPT_DIR}/slack-config.json" 2>/dev/null || echo "")
    
    if [ -z "$webhook_url" ] || [ "$webhook_url" = "null" ]; then
        log_error "Invalid Slack webhook URL"
        return 1
    fi
    
    local payload=$(cat << EOF
{
  "channel": "$channel",
  "username": "Jenkins Bot",
  "icon_emoji": ":jenkins:",
  "color": "good",
  "text": "🧪 Test notification from Jenkins setup script",
  "attachments": [
    {
      "color": "good",
      "fields": [
        {
          "title": "Status",
          "value": "Test notification",
          "short": true
        },
        {
          "title": "Time",
          "value": "$(date)",
          "short": true
        }
      ]
    }
  ]
}
EOF
)
    
    if curl -s -X POST -H 'Content-type: application/json' --data "$payload" "$webhook_url" > /dev/null; then
        log_success "Slack test notification sent successfully"
        return 0
    else
        log_error "Failed to send Slack test notification"
        return 1
    fi
}

create_email_config() {
    log_info "Creating email notification configuration..."
    
    local smtp_server=""
    local smtp_port=""
    local smtp_username=""
    local smtp_password=""
    local sender_email=""
    local recipient_emails=""
    
    echo "Enter SMTP server (e.g., smtp.gmail.com):"
    read -r smtp_server
    
    echo "Enter SMTP port (e.g., 587 for TLS, 465 for SSL):"
    read -r smtp_port
    
    echo "Enter SMTP username:"
    read -r smtp_username
    
    echo "Enter SMTP password:"
    read -rs smtp_password
    echo
    
    echo "Enter sender email address:"
    read -r sender_email
    
    echo "Enter recipient email addresses (comma-separated):"
    read -r recipient_emails
    
    # Create email configuration template
    cat > "${SCRIPT_DIR}/email-config.json" << EOF
{
  "smtp": {
    "server": "$smtp_server",
    "port": $smtp_port,
    "username": "$smtp_username",
    "password": "$smtp_password",
    "use_tls": true,
    "use_ssl": false
  },
  "sender": "$sender_email",
  "recipients": "$recipient_emails",
  "templates": {
    "success": {
      "subject": "✅ Jenkins Pipeline Success: {job_name} - Build #{build_number}",
      "body": "The Jenkins pipeline for {job_name} (Build #{build_number}) completed successfully.\n\nBranch: {branch}\nCommit: {commit}\nDuration: {duration}\n\nView details: {build_url}"
    },
    "failure": {
      "subject": "❌ Jenkins Pipeline Failure: {job_name} - Build #{build_number}",
      "body": "The Jenkins pipeline for {job_name} (Build #{build_number}) failed.\n\nBranch: {branch}\nCommit: {commit}\nStage: {failed_stage}\nDuration: {duration}\n\nView details: {build_url}\nLogs: {console_url}"
    },
    "unstable": {
      "subject": "⚠️ Jenkins Pipeline Unstable: {job_name} - Build #{build_number}",
      "body": "The Jenkins pipeline for {job_name} (Build #{build_number}) completed with warnings.\n\nBranch: {branch}\nCommit: {commit}\nDuration: {duration}\n\nView details: {build_url}"
    }
  }
}
EOF
    
    log_success "Email configuration saved to email-config.json"
    log_warning "Email configuration contains sensitive information - keep it secure!"
    
    # Test email notification
    test_email_notification
}

test_email_notification() {
    log_info "Testing email notification..."
    
    if [ ! -f "${SCRIPT_DIR}/email-config.json" ]; then
        log_error "Email configuration file not found"
        return 1
    fi
    
    # Create a simple Python script to test email
    cat > "/tmp/test_email.py" << 'EOF'
import json
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import sys

def send_test_email(config_file):
    try:
        with open(config_file, 'r') as f:
            config = json.load(f)
        
        smtp_config = config['smtp']
        
        # Create message
        msg = MIMEMultipart()
        msg['From'] = config['sender']
        msg['To'] = config['recipients']
        msg['Subject'] = "🧪 Test Email from Jenkins Setup"
        
        body = """This is a test email from the Jenkins notification setup script.
        
If you received this email, your email configuration is working correctly.

Test sent at: """ + str(__import__('datetime').datetime.now())
        
        msg.attach(MIMEText(body, 'plain'))
        
        # Connect to server
        server = smtplib.SMTP(smtp_config['server'], smtp_config['port'])
        
        if smtp_config.get('use_tls', True):
            server.starttls()
        
        server.login(smtp_config['username'], smtp_config['password'])
        
        # Send email
        text = msg.as_string()
        server.sendmail(config['sender'], config['recipients'].split(','), text)
        server.quit()
        
        print("SUCCESS: Test email sent successfully")
        return True
        
    except Exception as e:
        print(f"ERROR: Failed to send test email: {e}")
        return False

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python test_email.py <config_file>")
        sys.exit(1)
    
    success = send_test_email(sys.argv[1])
    sys.exit(0 if success else 1)
EOF
    
    if python3 "/tmp/test_email.py" "${SCRIPT_DIR}/email-config.json" 2>/dev/null; then
        log_success "Email test notification sent successfully"
        rm -f "/tmp/test_email.py"
        return 0
    else
        log_error "Failed to send email test notification"
        rm -f "/tmp/test_email.py"
        return 1
    fi
}

create_webhook_config() {
    log_info "Creating webhook notification configuration..."
    
    local webhook_url=""
    local webhook_secret=""
    local custom_headers=""
    
    echo "Enter webhook URL:"
    read -r webhook_url
    
    echo "Enter webhook secret (optional, press Enter to skip):"
    read -rs webhook_secret
    echo
    
    echo "Enter custom headers in JSON format (optional, press Enter to skip):"
    echo "Example: {\"Authorization\": \"Bearer token\", \"Content-Type\": \"application/json\"}"
    read -r custom_headers
    
    if [ -z "$custom_headers" ]; then
        custom_headers="{}"
    fi
    
    # Create webhook configuration template
    cat > "${SCRIPT_DIR}/webhook-config.json" << EOF
{
  "url": "$webhook_url",
  "secret": "$webhook_secret",
  "headers": $custom_headers,
  "timeout": 30,
  "retry_count": 3,
  "retry_delay": 5,
  "templates": {
    "success": {
      "event": "pipeline_success",
      "data": {
        "status": "success",
        "job_name": "{job_name}",
        "build_number": "{build_number}",
        "branch": "{branch}",
        "commit": "{commit}",
        "duration": "{duration}",
        "timestamp": "{timestamp}",
        "build_url": "{build_url}"
      }
    },
    "failure": {
      "event": "pipeline_failure",
      "data": {
        "status": "failure",
        "job_name": "{job_name}",
        "build_number": "{build_number}",
        "branch": "{branch}",
        "commit": "{commit}",
        "failed_stage": "{failed_stage}",
        "duration": "{duration}",
        "timestamp": "{timestamp}",
        "build_url": "{build_url}",
        "console_url": "{console_url}"
      }
    }
  }
}
EOF
    
    log_success "Webhook configuration saved to webhook-config.json"
    
    # Test webhook
    test_webhook_notification
}

test_webhook_notification() {
    log_info "Testing webhook notification..."
    
    if [ ! -f "${SCRIPT_DIR}/webhook-config.json" ]; then
        log_error "Webhook configuration file not found"
        return 1
    fi
    
    local webhook_url=$(jq -r '.url' "${SCRIPT_DIR}/webhook-config.json" 2>/dev/null || echo "")
    
    if [ -z "$webhook_url" ] || [ "$webhook_url" = "null" ]; then
        log_error "Invalid webhook URL"
        return 1
    fi
    
    local test_payload='{
        "event": "test_notification",
        "data": {
            "status": "test",
            "message": "Test notification from Jenkins setup script",
            "timestamp": "'$(date -u +%Y-%m-%dT%H:%M:%SZ)'"
        }
    }'
    
    if curl -s -X POST \
        -H "Content-Type: application/json" \
        -d "$test_payload" \
        "$webhook_url" > /dev/null; then
        log_success "Webhook test notification sent successfully"
        return 0
    else
        log_error "Failed to send webhook test notification"
        return 1
    fi
}

create_jenkins_credentials() {
    log_info "Creating Jenkins credentials for notifications..."
    
    local jenkins_password=""
    
    echo "Enter Jenkins admin password:"
    read -rs jenkins_password
    echo
    
    # Create Slack token credential
    if [ -f "${SCRIPT_DIR}/slack-config.json" ]; then
        local slack_webhook=$(jq -r '.webhook_url' "${SCRIPT_DIR}/slack-config.json" 2>/dev/null || echo "")
        if [ -n "$slack_webhook" ] && [ "$slack_webhook" != "null" ]; then
            create_jenkins_credential "slack-webhook-url" "Slack Webhook URL" "secret" "$slack_webhook" "$jenkins_password"
        fi
    fi
    
    # Create email credentials
    if [ -f "${SCRIPT_DIR}/email-config.json" ]; then
        local smtp_password=$(jq -r '.smtp.password' "${SCRIPT_DIR}/email-config.json" 2>/dev/null || echo "")
        if [ -n "$smtp_password" ] && [ "$smtp_password" != "null" ]; then
            create_jenkins_credential "smtp-password" "SMTP Password" "secret" "$smtp_password" "$jenkins_password"
        fi
    fi
    
    # Create webhook secret credential
    if [ -f "${SCRIPT_DIR}/webhook-config.json" ]; then
        local webhook_secret=$(jq -r '.secret' "${SCRIPT_DIR}/webhook-config.json" 2>/dev/null || echo "")
        if [ -n "$webhook_secret" ] && [ "$webhook_secret" != "null" ]; then
            create_jenkins_credential "webhook-secret" "Webhook Secret" "secret" "$webhook_secret" "$jenkins_password"
        fi
    fi
}

create_jenkins_credential() {
    local cred_id="$1"
    local description="$2"
    local cred_type="$3"
    local value="$4"
    local jenkins_password="$5"
    
    local credential_xml=""
    
    case "$cred_type" in
        "secret")
            credential_xml='<org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>
                <scope>GLOBAL</scope>
                <id>'$cred_id'</id>
                <description>'$description'</description>
                <secret>'$value'</secret>
            </org.jenkinsci.plugins.plaincredentials.impl.StringCredentialsImpl>'
            ;;
        "userpass")
            local username="$value"
            local password="$6"
            credential_xml='<com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>
                <scope>GLOBAL</scope>
                <id>'$cred_id'</id>
                <description>'$description'</description>
                <username>'$username'</username>
                <password>'$password'</password>
            </com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl>'
            ;;
    esac
    
    # Create credential via Jenkins CLI or API
    if curl -s -u "$JENKINS_USER:$jenkins_password" \
        -H "Content-Type: application/xml" \
        -X POST "$JENKINS_URL/credentials/store/system/domain/_/createCredentials" \
        --data-raw "$credential_xml" > /dev/null 2>&1; then
        log_success "Created Jenkins credential: $cred_id"
    else
        log_warning "Failed to create Jenkins credential: $cred_id (may already exist)"
    fi
}

generate_jenkins_groovy_script() {
    log_info "Generating Jenkins configuration script..."
    
    cat > "${SCRIPT_DIR}/jenkins-notification-config.groovy" << 'EOF'
import jenkins.model.*
import hudson.plugins.emailext.*
import jenkins.plugins.slack.*

def jenkins = Jenkins.getInstance()

// Configure Email Extension Plugin
def emailExtDescriptor = jenkins.getDescriptor(ExtendedEmailPublisher.class)
if (emailExtDescriptor) {
    // Configure SMTP settings from email-config.json
    emailExtDescriptor.setSmtpHost("smtp.gmail.com") // Update with your SMTP server
    emailExtDescriptor.setSmtpPort("587")
    emailExtDescriptor.setUseSsl(false)
    emailExtDescriptor.setUseTls(true)
    emailExtDescriptor.setCharset("UTF-8")
    emailExtDescriptor.setDefaultSubject("Jenkins Build Notification")
    emailExtDescriptor.setDefaultBody("Build Status: \$BUILD_STATUS")
    emailExtDescriptor.save()
    println "Email Extension Plugin configured"
}

// Configure Slack Plugin
def slackDescriptor = jenkins.getDescriptor(SlackNotifier.class)
if (slackDescriptor) {
    slackDescriptor.setTeamDomain("your-team") // Update with your team domain
    slackDescriptor.setToken("your-slack-token") // Update with your Slack token
    slackDescriptor.setRoom("#general") // Update with your default channel
    slackDescriptor.save()
    println "Slack Plugin configured"
}

jenkins.save()
println "Jenkins notification configuration completed"
EOF
    
    log_success "Jenkins configuration script saved to jenkins-notification-config.groovy"
    log_info "Run this script in Jenkins Script Console (Manage Jenkins > Script Console)"
}

create_notification_templates() {
    log_info "Creating notification templates..."
    
    # Create directory for templates
    mkdir -p "${SCRIPT_DIR}/templates"
    
    # Slack message template
    cat > "${SCRIPT_DIR}/templates/slack-message.json" << 'EOF'
{
  "channel": "${SLACK_CHANNEL}",
  "username": "Jenkins Bot",
  "icon_emoji": ":jenkins:",
  "attachments": [
    {
      "color": "${COLOR}",
      "fallback": "${STATUS} - ${JOB_NAME} #${BUILD_NUMBER}",
      "pretext": "${STATUS_EMOJI} Pipeline ${STATUS}",
      "title": "${JOB_NAME} - Build #${BUILD_NUMBER}",
      "title_link": "${BUILD_URL}",
      "fields": [
        {
          "title": "Branch",
          "value": "${BRANCH_NAME}",
          "short": true
        },
        {
          "title": "Commit",
          "value": "${GIT_COMMIT_SHORT}",
          "short": true
        },
        {
          "title": "Duration",
          "value": "${BUILD_DURATION}",
          "short": true
        },
        {
          "title": "Stage",
          "value": "${STAGE_NAME}",
          "short": true
        }
      ],
      "footer": "Jenkins",
      "footer_icon": "https://jenkins.io/images/logos/jenkins/jenkins.png",
      "ts": "${TIMESTAMP}"
    }
  ]
}
EOF
    
    # Email template
    cat > "${SCRIPT_DIR}/templates/email-template.html" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Jenkins Build Notification</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 0; padding: 20px; background-color: #f5f5f5; }
        .container { max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { background-color: ${HEADER_COLOR}; color: white; padding: 20px; border-radius: 8px 8px 0 0; }
        .content { padding: 20px; }
        .status { font-size: 24px; font-weight: bold; margin-bottom: 10px; }
        .details { background-color: #f8f9fa; padding: 15px; border-radius: 4px; margin: 15px 0; }
        .detail-row { display: flex; justify-content: space-between; margin: 5px 0; }
        .button { display: inline-block; padding: 12px 24px; background-color: #007bff; color: white; text-decoration: none; border-radius: 4px; margin: 15px 0; }
        .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <div class="status">${STATUS_EMOJI} Pipeline ${STATUS}</div>
            <div>${JOB_NAME} - Build #${BUILD_NUMBER}</div>
        </div>
        <div class="content">
            <div class="details">
                <div class="detail-row">
                    <strong>Branch:</strong>
                    <span>${BRANCH_NAME}</span>
                </div>
                <div class="detail-row">
                    <strong>Commit:</strong>
                    <span>${GIT_COMMIT_SHORT}</span>
                </div>
                <div class="detail-row">
                    <strong>Duration:</strong>
                    <span>${BUILD_DURATION}</span>
                </div>
                <div class="detail-row">
                    <strong>Stage:</strong>
                    <span>${STAGE_NAME}</span>
                </div>
                <div class="detail-row">
                    <strong>Timestamp:</strong>
                    <span>${BUILD_TIMESTAMP}</span>
                </div>
            </div>
            
            <a href="${BUILD_URL}" class="button">View Build Details</a>
            
            ${ADDITIONAL_INFO}
        </div>
        <div class="footer">
            This notification was sent by Jenkins CI/CD Pipeline
        </div>
    </div>
</body>
</html>
EOF
    
    log_success "Notification templates created in templates/ directory"
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help              Show this help message"
    echo "  --slack                 Configure Slack notifications"
    echo "  --email                 Configure email notifications"
    echo "  --webhook               Configure webhook notifications"
    echo "  --jenkins-creds         Create Jenkins credentials"
    echo "  --templates             Create notification templates"
    echo "  --all                   Set up all notification types"
    echo "  --test-only             Only run notification tests"
    echo ""
    echo "Examples:"
    echo "  $0 --slack              Configure Slack notifications"
    echo "  $0 --all                Set up all notification types"
    echo "  $0 --test-only          Test existing configurations"
    echo ""
}

main() {
    local setup_slack=false
    local setup_email=false
    local setup_webhook=false
    local setup_jenkins_creds=false
    local create_templates=false
    local test_only=false
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            --slack)
                setup_slack=true
                shift
                ;;
            --email)
                setup_email=true
                shift
                ;;
            --webhook)
                setup_webhook=true
                shift
                ;;
            --jenkins-creds)
                setup_jenkins_creds=true
                shift
                ;;
            --templates)
                create_templates=true
                shift
                ;;
            --all)
                setup_slack=true
                setup_email=true
                setup_webhook=true
                setup_jenkins_creds=true
                create_templates=true
                shift
                ;;
            --test-only)
                test_only=true
                shift
                ;;
            *)
                log_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Default to showing usage if no options provided
    if [ "$setup_slack" = false ] && [ "$setup_email" = false ] && [ "$setup_webhook" = false ] && [ "$setup_jenkins_creds" = false ] && [ "$create_templates" = false ] && [ "$test_only" = false ]; then
        show_usage
        exit 0
    fi
    
    check_prerequisites
    
    log_info "Starting notification setup..."
    
    if [ "$test_only" = true ]; then
        log_info "Testing existing notification configurations..."
        
        if [ -f "${SCRIPT_DIR}/slack-config.json" ]; then
            test_slack_notification
        fi
        
        if [ -f "${SCRIPT_DIR}/email-config.json" ]; then
            test_email_notification
        fi
        
        if [ -f "${SCRIPT_DIR}/webhook-config.json" ]; then
            test_webhook_notification
        fi
        
        log_success "Notification testing completed"
        exit 0
    fi
    
    if [ "$setup_slack" = true ]; then
        create_slack_config
    fi
    
    if [ "$setup_email" = true ]; then
        create_email_config
    fi
    
    if [ "$setup_webhook" = true ]; then
        create_webhook_config
    fi
    
    if [ "$create_templates" = true ]; then
        create_notification_templates
    fi
    
    if [ "$setup_jenkins_creds" = true ]; then
        create_jenkins_credentials
    fi
    
    generate_jenkins_groovy_script
    
    log_success "🎉 Notification setup completed!"
    
    echo ""
    echo "=== Next Steps ==="
    echo "1. Review and update configuration files in: $SCRIPT_DIR"
    echo "2. Run the Jenkins Groovy script in Jenkins Script Console"
    echo "3. Update your Jenkinsfile to use the notification functions"
    echo "4. Test notifications with: $0 --test-only"
    echo ""
}

# Run main function
main "$@" 