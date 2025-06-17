# ==========================================
# Simple Object Storage Test (Free Tier Safe)
# ==========================================
# Replace your test-resources.tf content with this simpler version

# Get object storage namespace
data "oci_objectstorage_namespace" "current" {
  compartment_id = var.tenancy_ocid
}

# Simple object storage bucket for testing
resource "oci_objectstorage_bucket" "budget_test" {
  count          = var.enable_test_resources ? 1 : 0
  compartment_id = var.compartment_ocid
  name          = "budget-test-${formatdate("YYYYMMDD", timestamp())}"
  namespace     = data.oci_objectstorage_namespace.current.namespace
  
  # Standard storage tier
  storage_tier = "Standard"
  
  freeform_tags = {
    Environment = var.environment
    Project     = var.project_name
    Purpose     = "budget_testing"
  }
}

# Create some test objects to generate minimal costs
resource "oci_objectstorage_object" "test_objects" {
  count     = var.enable_test_resources ? 3 : 0
  bucket    = oci_objectstorage_bucket.budget_test[0].name
  namespace = data.oci_objectstorage_namespace.current.namespace
  object    = "test-file-${count.index}.txt"
  content   = "This is test file ${count.index} for budget testing - ${timestamp()}"
  
  content_type = "text/plain"
}

# Outputs for test resources
output "test_bucket_name" {
  description = "Test bucket name (if created)"
  value       = var.enable_test_resources ? oci_objectstorage_bucket.budget_test[0].name : null
}

output "test_objects_count" {
  description = "Number of test objects created"
  value       = var.enable_test_resources ? length(oci_objectstorage_object.test_objects) : 0
}