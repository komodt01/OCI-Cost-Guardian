# OCI Cost Guardian - Lessons Learned

## 📋 **Project Summary**
- **Project**: OCI Cost Governance and Budget Enforcement
- **Duration**: June 15-16, 2025
- **Environment**: WSL Ubuntu, Terraform v1.12.2, OCI Provider v5.x
- **Outcome**: ✅ **Production Ready Deployment**

---

## 🔧 **Actual Technical Challenges We Faced**

### **Challenge #1: Terraform Installation in WSL**

**Problem**: After installing Terraform via tfenv, got "command not found"
```bash
terraform: command not found

What we did:
source ~/.bashrc

Lesson: Always reload shell after PATH changes

Challenge #2: Terraform Syntax Errors
Problem: Multiple "Unsupported block type" errors when running terraform plan
Specific errors we encountered:

Line 86: dynamic "budget_alert_rule" - unsupported block type
Line 82: Type mismatch in recipients field
Display name errors: "Warning at 80%" not allowed

What we tried:

First attempt: Fixed complex Service Connector syntax - still failed
Second attempt: Removed Service Connectors entirely - still had dynamic block errors
Third attempt: Replaced dynamic blocks with separate resources - worked!
Fourth attempt: Fixed naming to use underscores only - success!

Final working pattern:
hcl# This failed:
display_name = "Warning at 80%"

# This worked:
display_name = "Warning_80_Percent"
Lesson: OCI has strict naming rules - only a-zA-Z0-9_ for display names

Challenge #3: Free Tier VM Authorization Failures
Problem: Tried to create compute instances for testing, got authorization errors
bashError: 404-NotAuthorizedOrNotFound, Authorization failed
What we discovered: OCI free tier blocks compute instance creation
What we did: Switched to Object Storage for testing
hcl# This failed in free tier:
resource "oci_core_instance" "test" { ... }

# This worked:
resource "oci_objectstorage_bucket" "test" { ... }
Result: Object Storage generates ~$0.02/month, perfect for triggering $1 budget alerts
Lesson: Design for free tier limitations, don't fight them

Challenge #4: Email Notifications Don't Work
Problem: Budget alert emails not being delivered
What we discovered: OCI free tier blocks SMTP/email notifications
What we did: Relied on OCI Console monitoring and logging instead
Lesson: Free tier has more restrictions than expected

🎯 Our Architecture Evolution
What We Started With (Too Complex)

Budget with dynamic alert rule blocks
Service Connector Hub for event routing
Complex event rules and streaming

What We Ended With (Works)

Simple budget resource
Separate alert rule resources
Basic logging for audit trail
Object Storage for testing

🚀 Our Successful Development Strategy
Incremental Deployment (What Worked)
Our actual steps:

Basic budget only → terraform apply ✅
Add warning alert → terraform apply ✅
Add critical alert → terraform apply ✅
Add logging → terraform apply ✅
Add test resources → terraform apply ✅
Key insight: Test each piece separately before combining

OCI-Specific Discoveries
What We Learned About OCI Terraform Provider

Naming rules are strict: Only underscores, no spaces or special characters
Dynamic blocks problematic: Avoid nested dynamic configurations
Free tier restrictions: More limited than AWS/Azure free tiers
Error messages misleading: Syntax errors vs permission issues hard to distinguish

Our Debugging Process
bash# What we did every time:
terraform validate  # Check syntax first
terraform plan      # See what would change
terraform apply     # Deploy one change at a time

📊 Free Tier Reality Check
What Actually Works in OCI Free Tier

✅ Budget creation and monitoring
✅ Alert rules (but no email delivery)
✅ Logging (10GB free)
✅ Object Storage (10GB free)

What Doesn't Work

❌ Email notifications (SMTP blocked)
❌ Compute instances (authorization failures)
❌ Complex service integrations

Our Workaround Strategy

Use Object Storage instead of VMs for testing
Monitor via OCI Console instead of email
Keep architecture simple

💡 Key Takeaways
Technical

Start simple - Don't build complex configurations initially
Test incrementally - Deploy one resource type at a time
Read error messages carefully - OCI naming rules are strict
Free tier has real limitations - Design around them

Process

Validate frequently - Use terraform validate after every change
Document what works - Free tier patterns differ from paid accounts
Don't assume cloud portability - Each provider has unique quirks

✅ What We Successfully Built

Working budget monitoring with $1 limit
Two alert rules at 80% and 95% thresholds
Logging infrastructure for audit trails
Object Storage testing that generates predictable costs
Complete documentation of lessons learned