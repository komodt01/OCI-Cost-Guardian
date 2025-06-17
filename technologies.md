# Technologies Guide - OCI Cost Guardian

## 📋 **Overview**

This document explains the specific technologies we used in the OCI Cost Guardian project and how they work together for cost governance.

---

## 🏗️ **Oracle Cloud Infrastructure (OCI) Services**

### **OCI Budget Service**

**What it is**: Oracle's cloud cost monitoring service that tracks spending against defined limits.

**How it works**:
- Automatically tracks all spending in specified compartments
- Compares actual costs against monthly budget limits
- Triggers alerts when spending reaches threshold percentages
- Resets monthly for recurring budget cycles

**How we used it**:
```hcl
resource "oci_budget_budget" "main" {
  compartment_id = var.tenancy_ocid
  amount         = 1  # $1 monthly limit for testing
  reset_period   = "MONTHLY"
  targets        = [var.compartment_ocid]  # What to monitor
}
Why it's essential: Provides the core cost monitoring functionality for our governance solution.

OCI Budget Alert Rules
What they are: Notification triggers that fire when budget thresholds are exceeded.
How they work:

Monitor budget spending in real-time
Compare current spend to percentage thresholds
Generate alerts when thresholds are breached
Can target email recipients (though often blocked in free tier)

How we implemented them:
hcl# Warning at 80% of budget
resource "oci_budget_alert_rule" "warning_alert" {
  budget_id      = oci_budget_budget.main.id
  threshold      = 80
  threshold_type = "PERCENTAGE"
  type          = "ACTUAL"
  display_name  = "Warning_80_Percent"  # Must use underscores only
}

# Critical at 95% of budget
resource "oci_budget_alert_rule" "critical_alert" {
  budget_id      = oci_budget_budget.main.id
  threshold      = 95
  threshold_type = "PERCENTAGE"
  type          = "ACTUAL"
  display_name  = "Critical_95_Percent"
}
Why we use separate resources: OCI Terraform provider works better with individual alert rule resources rather than nested blocks.

OCI Logging Service
What it is: Centralized logging platform that captures events from OCI services.
How it works:

Automatically collects events from specified OCI services
Stores logs in organized log groups
Provides search and analysis capabilities
Maintains configurable retention periods

How we configured it:
hcl# Log group to organize budget-related logs
resource "oci_logging_log_group" "budget_alerts" {
  compartment_id = var.compartment_ocid
  display_name   = "budget_alert_logs"
}

# Log configuration to capture budget events
resource "oci_logging_log" "alert_events" {
  log_group_id = oci_logging_log_group.budget_alerts.id
  log_type     = "CUSTOM"
  
  configuration {
    source {
      service     = "budget"
      source_type = "OCISERVICE"
      resource    = oci_budget_budget.main.id
    }
  }
}
Why we need it: Provides audit trail for compliance and troubleshooting when alerts don't work as expected.

OCI Object Storage
What it is: Scalable object storage service for files and data.
How it works:

Stores files in buckets within a global namespace
Charges based on storage used and requests made
Provides immediate cost impact for budget testing
Highly available across OCI regions

How we use it for testing:
hcl# Create bucket for test files
resource "oci_objectstorage_bucket" "budget_test" {
  compartment_id = var.compartment_ocid
  name          = "budget-test-${formatdate("YYYYMMDD", timestamp())}"
  namespace     = data.oci_objectstorage_namespace.current.namespace
}

# Create test files that generate small costs
resource "oci_objectstorage_object" "test_objects" {
  count     = 3
  bucket    = oci_objectstorage_bucket.budget_test[0].name
  namespace = data.oci_objectstorage_namespace.current.namespace
  object    = "test-file-${count.index}.txt"
  content   = "Test content for budget monitoring"
}
Why we chose this for testing:

Always works in free tier (unlike compute instances)
Generates predictable small costs (~$0.02/month)
Perfect for triggering budget alerts with $1 limit

Infrastructure as Code
Terraform
What it is: Tool for defining and managing infrastructure using code.
How it works:

Read configuration files (.tf files)
Compare desired state to current state
Calculate what changes need to be made
Execute changes through provider APIs
Track state in .tfstate files

How we structured our Terraform:
main.tf           # Core budget and alert resources
variables.tf      # Input parameter definitions
test-resources.tf # Optional testing infrastructure
terraform.tfvars  # Our specific configuration values
Why we use it: Allows us to version control our infrastructure and deploy consistently across environments.

OCI Terraform Provider
What it is: Plugin that allows Terraform to manage OCI resources.
How it works:

Translates Terraform configuration into OCI REST API calls
Handles authentication through OCI CLI configuration
Maps Terraform resource names to OCI service APIs
Manages resource lifecycle (create, read, update, delete)

Our provider configuration:
hclterraform {
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
  }
}
Key discovery: OCI provider has stricter naming conventions than AWS/Azure providers.

HCL (HashiCorp Configuration Language)
What it is: The language used to write Terraform configurations.
How it works:

Declarative syntax (describe what you want, not how to get it)
Block-based structure for organizing configuration
Variables and expressions for dynamic values
Validation rules to catch errors before deployment

Example of our HCL structure:
hcl# Variable definition with validation
variable "monthly_budget_limit" {
  description = "Monthly budget limit"
  type        = number
  default     = 1
  
  validation {
    condition     = var.monthly_budget_limit > 0
    error_message = "Budget must be greater than 0"
  }
}

# Resource definition
resource "oci_budget_budget" "main" {
  compartment_id = var.compartment_ocid
  amount         = var.monthly_budget_limit
}
Why it's effective: Human-readable format that works well with version control and team collaboration.00Z

Development Environment
Windows Subsystem for Linux (WSL)
What it is: Linux environment running on Windows.
How we used it:

Provided native Linux environment for Terraform
Better compatibility with OCI CLI than Windows
Easy access to Windows files through /mnt/c/ path
Consistent bash shell environment

Our specific setup:
bash# Access our Windows project directory
cd "/mnt/c/Users/k_omo/Documents/GitHub_New/OCI Cost Guardian"

# Run Terraform commands
terraform init
terraform plan
terraform apply
Why WSL was essential: Terraform and OCI CLI work more reliably on Linux than Windows.

tfenv (Terraform Version Manager)
What it is: Tool for managing multiple Terraform versions.
How we used it:

Installed Terraform v1.12.2
Ensured consistent version across development
Managed PATH configuration automatically

Our installation process:
bashgit clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
tfenv install latest
tfenv use latest
Why we chose this: Easier version management than direct Terraform installation.

Authentication
OCI CLI
What it is: Command-line tool for Oracle Cloud Infrastructure.
How we used it:

Configured authentication credentials
Provided authentication for Terraform OCI provider
Used for debugging and verification

Our setup process:
bash# Install OCI CLI
bash -c "$(curl -L https://raw.githubusercontent.com/oracle/oci-cli/master/scripts/install/install.sh)"

# Configure authentication
oci setup config

# Test connection
oci iam compartment list --all

Technology Lessons Learned
What Worked Well:

Simple Terraform structure: Flat resource hierarchy easier than complex nesting
Object Storage testing: Reliable cost generation in free tier
Incremental deployment: Adding one resource type at a time
OCI Console monitoring: Better than relying on email alerts

Technology Limitations We Discovered:

OCI naming restrictions: Display names must use underscores only
Free tier email blocking: SMTP notifications often don't work
Compute authorization: VM creation blocked in many free tier accounts
Dynamic block complexity: OCI provider prefers separate resources

Best Practices for Our Stack:

Always run terraform validate before terraform plan
Use separate alert rule resources instead of nested blocks
Test each resource addition incrementally
Keep configuration simple for better reliability