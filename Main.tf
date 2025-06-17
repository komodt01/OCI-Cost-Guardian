Now let me give you each file separately:

## **1. main.tf**

```hcl
# ==========================================
# OCI Cost Guardian - Production Ready
# ==========================================
# Author: Platform Engineering Team
# Purpose: Multi-cloud cost governance (OCI implementation)
# Compliance: ISO 27001, SOC 2 cost monitoring requirements
# Status: Production Ready ✅

terraform {
  required_version = ">= 1.0"
  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.1"
    }
  }
}

# ==========================================
# Local Variables and Data Sources
# ==========================================

locals {
  common_tags = {
    Environment     = var.environment
    Project         = var.project_name
    Owner           = var.owner
    CostCenter      = var.cost_center
    ManagedBy       = "terraform"
    ComplianceScope = "cost-governance"
  }
  
  budget_name = "${var.project_name}-${var.environment}-budget"
}

# Get current tenancy and compartment info
data "oci_identity_tenancy" "current" {
  tenancy_id = var.tenancy_ocid
}

data "oci_identity_compartment" "target" {
  id = var.compartment_ocid
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# ==========================================
# Core Budget Configuration
# ==========================================

resource "oci_budget_budget" "main" {
  compartment_id   = var.tenancy_ocid  # Budgets are created at tenancy level
  amount           = var.monthly_budget_limit
  reset_period     = "MONTHLY"
  display_name     = local.budget_name
  description      = "Cost governance budget for ${var.project_name} in ${var.environment}"
  
  # Target compartment for budget monitoring
  targets = [var.compartment_ocid]
  
  # Processing period for budget calculations
  processing_period_type = "MONTH"
  
  freeform_tags = local.common_tags
}

# ==========================================
# Budget Alert Rules
# ==========================================

# Warning alert at 80% threshold
resource "oci_budget_alert_rule" "warning_alert" {
  budget_id      = oci_budget_budget.main.id
  threshold      = var.warning_threshold
  threshold_type = "PERCENTAGE"
  type          = "ACTUAL"
  display_name  = "Warning_${var.warning_threshold}_Percent"
  description   = "Budget warning alert at ${var.warning_threshold}% of monthly limit"
  
  # Recipients (email notifications)
  recipients = var.notification_emails
  
  # Custom warning message
  message = "WARNING: ${var.project_name} budget has reached ${var.warning_threshold}% of the monthly limit ($${var.monthly_budget_limit} ${var.currency})"
  
  freeform_tags = merge(local.common_tags, {
    AlertLevel = "warning"
  })
}

# Critical alert at 95% threshold
resource "oci_budget_alert_rule" "critical_alert" {
  budget_id      = oci_budget_budget.main.id
  threshold      = var.critical_threshold
  threshold_type = "PERCENTAGE"
  type          = "ACTUAL"
  display_name  = "Critical_${var.critical_threshold}_Percent"
  description   = "Budget critical alert at ${var.critical_threshold}% of monthly limit"
  
  # Recipients (email notifications)
  recipients = var.notification_emails
  
  # Critical alert message
  message = "CRITICAL: ${var.project_name} budget has reached ${var.critical_threshold}% of the monthly limit ($${var.monthly_budget_limit} ${var.currency}) - immediate action required"
  
  freeform_tags = merge(local.common_tags, {
    AlertLevel = "critical"
  })
}

# ==========================================
# Logging Infrastructure
# ==========================================

# Log Group for budget events
resource "oci_logging_log_group" "budget_alerts" {
  compartment_id = var.compartment_ocid
  display_name   = "budget_alert_logs"
  description    = "Log group for budget alert events and cost governance"
  
  freeform_tags = merge(local.common_tags, {
    Purpose = "budget_monitoring"
  })
}

# Custom Log for budget alert events
resource "oci_logging_log" "alert_events" {
  display_name       = "budget_alert_events"
  log_group_id       = oci_logging_log_group.budget_alerts.id
  log_type          = "CUSTOM"
  is_enabled        = true
  retention_duration = var.log_retention_days
  
  configuration {
    source {
      category    = "all"
      resource    = oci_budget_budget.main.id
      service     = "budget"
      source_type = "OCISERVICE"
    }
    
    compartment_id = var.compartment_ocid
  }
  
  freeform_tags = merge(local.common_tags, {
    LogType = "budget_alerts"
  })
}

# ==========================================
# Outputs
# ==========================================

output "budget_id" {
  description = "The OCID of the created budget"
  value       = oci_budget_budget.main.id
}

output "budget_name" {
  description = "The display name of the budget"
  value       = oci_budget_budget.main.display_name
}

output "warning_alert_id" {
  description = "The OCID of the warning alert rule"
  value       = oci_budget_alert_rule.warning_alert.id
}

output "critical_alert_id" {
  description = "The OCID of the critical alert rule"
  value       = oci_budget_alert_rule.critical_alert.id
}

output "alert_log_group_id" {
  description = "The OCID of the budget monitoring log group"
  value       = oci_logging_log_group.budget_alerts.id
}

output "alert_log_id" {
  description = "The OCID of the alert events log"
  value       = oci_logging_log.alert_events.id
}

output "compliance_report" {
  description = "Compliance and monitoring endpoints"
  value = {
    budget_monitoring_endpoint = "https://cloud.oracle.com/budgets/${oci_budget_budget.main.id}"
    log_analytics_endpoint     = "https://cloud.oracle.com/logging/log-groups/${oci_logging_log_group.budget_alerts.id}"
    cost_analysis_endpoint     = "https://cloud.oracle.com/cost-analysis"
    budget_summary = {
      budget_limit    = var.monthly_budget_limit
      warning_at      = "${var.warning_threshold}% ($${var.monthly_budget_limit * var.warning_threshold / 100})"
      critical_at     = "${var.critical_threshold}% ($${var.monthly_budget_limit * var.critical_threshold / 100})"
      compartment_id  = var.compartment_ocid
    }
  }
}