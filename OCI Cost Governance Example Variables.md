# ==========================================
# OCI Minimal Variables
# ==========================================

variable "tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
}

variable "compartment_ocid" {
  description = "OCI compartment OCID"
  type        = string
}

variable "region" {
  description = "OCI region"
  type        = string
  default     = "us-phoenix-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cost-guardian"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "monthly_budget_limit" {
  description = "Monthly budget limit"
  type        = number
  default     = 1
}