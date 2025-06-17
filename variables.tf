# ==========================================
# OCI Cost Guardian - Variable Definitions
# ==========================================

# ==========================================
# Core Infrastructure Variables
# ==========================================

variable "tenancy_ocid" {
  description = "The OCID of the tenancy"
  type        = string
  
  validation {
    condition     = can(regex("^ocid1\\.tenancy\\.oc1\\.", var.tenancy_ocid))
    error_message = "Tenancy OCID must be a valid OCI tenancy identifier starting with 'ocid1.tenancy.oc1.'."
  }
}

variable "compartment_ocid" {
  description = "The OCID of the compartment to monitor"
  type        = string
  
  validation {
    condition     = can(regex("^ocid1\\.(compartment|tenancy)\\.oc1\\.", var.compartment_ocid))
    error_message = "Compartment OCID must be a valid OCI compartment identifier."
  }
}

variable "region" {
  description = "The OCI region for resource deployment"
  type        = string
  default     = "us-phoenix-1"
  
  validation {
    condition = contains([
      "us-phoenix-1", "us-ashburn-1", "uk-london-1", "eu-frankfurt-1", 
      "ap-tokyo-1", "ap-sydney-1", "ca-toronto-1", "sa-saopaulo-1"
    ], var.region)
    error_message = "Region must be a valid OCI region identifier."
  }
}

# ==========================================
# Project Configuration
# ==========================================

variable "project_name" {
  description = "Name of the project for resource naming and tagging"
  type        = string
  default     = "cost-guardian"
  
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 50
    error_message = "Project name must be between 1 and 50 characters."
  }
  
  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.project_name))
    error_message = "Project name must contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

variable "owner" {
  description = "Owner or team responsible for resources"
  type        = string
  default     = "platform-team"
  
  validation {
    condition     = length(var.owner) > 0 && length(var.owner) <= 100
    error_message = "Owner must be between 1 and 100 characters."
  }
}

variable "cost_center" {
  description = "Cost center for billing and reporting"
  type        = string
  default     = "engineering"
  
  validation {
    condition     = length(var.cost_center) > 0 && length(var.cost_center) <= 50
    error_message = "Cost center must be between 1 and 50 characters."
  }
}

# ==========================================
# Budget Configuration
# ==========================================

variable "monthly_budget_limit" {
  description = "Monthly budget limit (in currency units)"
  type        = number
  default     = 1
  
  validation {
    condition     = var.monthly_budget_limit > 0
    error_message = "Monthly budget limit must be greater than 0."
  }
  
  validation {
    condition     = var.monthly_budget_limit <= 1000000
    error_message = "Monthly budget limit must be reasonable (≤ 1,000,000)."
  }
}

variable "currency" {
  description = "Currency for budget (USD, EUR, GBP, etc.)"
  type        = string
  default     = "USD"
  
  validation {
    condition     = contains(["USD", "EUR", "GBP", "CAD", "AUD", "JPY"], var.currency)
    error_message = "Currency must be one of: USD, EUR, GBP, CAD, AUD, JPY."
  }
}

variable "warning_threshold" {
  description = "Warning threshold percentage (0-100)"
  type        = number
  default     = 80
  
  validation {
    condition     = var.warning_threshold >= 0 && var.warning_threshold <= 100
    error_message = "Warning threshold must be between 0 and 100."
  }
}

variable "critical_threshold" {
  description = "Critical threshold percentage (0-100)"
  type        = number
  default     = 95
  
  validation {
    condition     = var.critical_threshold >= 0 && var.critical_threshold <= 100
    error_message = "Critical threshold must be between 0 and 100."
  }
  
  validation {
    condition     = var.critical_threshold > var.warning_threshold
    error_message = "Critical threshold must be greater than warning threshold."
  }
}

# ==========================================
# Notification Configuration
# ==========================================

variable "notification_emails" {
  description = "List of email addresses for budget alerts"
  type        = list(string)
  default     = []
  
  validation {
    condition = alltrue([
      for email in var.notification_emails : can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", email))
    ])
    error_message = "All notification emails must be valid email addresses."
  }
}

variable "webhook_url" {
  description = "Webhook URL for alternative notifications (Slack, Teams, etc.)"
  type        = string
  default     = ""
  
  validation {
    condition = var.webhook_url == "" || can(regex("^https?://", var.webhook_url))
    error_message = "Webhook URL must be empty or start with http:// or https://."
  }
}

# ==========================================
# Logging Configuration
# ==========================================

variable "log_retention_days" {
  description = "Number of days to retain budget monitoring logs"
  type        = number
  default     = 30
  
  validation {
    condition     = var.log_retention_days >= 1 && var.log_retention_days <= 365
    error_message = "Log retention must be between 1 and 365 days."
  }
}

# ==========================================
# Testing Configuration
# ==========================================

variable "enable_test_resources" {
  description = "Enable test resources to generate budget costs for testing"
  type        = bool
  default     = false
}

# ==========================================
# Advanced Configuration
# ==========================================

variable "enable_cost_anomaly_detection" {
  description = "Enable cost anomaly detection (may require paid features)"
  type        = bool
  default     = false
}

variable "budget_forecast_enabled" {
  description = "Enable budget forecasting features"
  type        = bool
  default     = true
}

variable "compliance_tags_required" {
  description = "Enforce compliance tagging on all resources"
  type        = bool
  default     = true
}

# ==========================================
# Free Tier Specific Variables
# ==========================================

variable "free_tier_optimized" {
  description = "Optimize configuration for free tier limitations"
  type        = bool
  default     = true
}

variable "skip_email_notifications" {
  description = "Skip email notifications (recommended for free tier)"
  type        = bool
  default     = true
}

# ==========================================
# Multi-Environment Support
# ==========================================

variable "environment_config" {
  description = "Environment-specific configuration overrides"
  type = object({
    budget_multiplier     = optional(number, 1)
    alert_email_override  = optional(list(string), [])
    log_retention_override = optional(number, 30)
    enable_enhanced_monitoring = optional(bool, false)
  })
  default = {}
}

# ==========================================
# Tagging Configuration
# ==========================================

variable "additional_tags" {
  description = "Additional tags to apply to all resources"
  type        = map(string)
  default     = {}
  
  validation {
    condition = alltrue([
      for key, value in var.additional_tags : length(key) <= 100 && length(value) <= 256
    ])
    error_message = "Tag keys must be ≤100 characters and values ≤256 characters."
  }
}

# ==========================================
# Security Configuration
# ==========================================

variable "enable_audit_logging" {
  description = "Enable comprehensive audit logging"
  type        = bool
  default     = true
}

variable "log_encryption_enabled" {
  description = "Enable encryption for log data"
  type        = bool
  default     = true
}

variable "access_control_strict" {
  description = "Enable strict access controls"
  type        = bool
  default     = true
}