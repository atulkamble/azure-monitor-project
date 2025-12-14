# Azure Monitor Project - Terraform Deployment

This directory contains Terraform configuration files for deploying the Azure Monitor project infrastructure.

## 🚀 **Quick Start**

### **Prerequisites**
- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>= 1.0)
- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed and authenticated
- SSH key pair generated (`ssh-keygen -t rsa -b 2048`)

### **Authentication**
```bash
# Login to Azure
az login

# Set your subscription (if you have multiple)
az account set --subscription "your-subscription-id"
```

### **Deployment Steps**

1. **Initialize Terraform**
```bash
cd terraform
terraform init
```

2. **Create Configuration File**
```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
vim terraform.tfvars  # or use any editor
```

3. **Plan Deployment**
```bash
terraform plan
```

4. **Deploy Infrastructure**
```bash
terraform apply
```

5. **Get Connection Information**
```bash
terraform output deployment_summary
terraform output ssh_connection_command
```

## 📋 **Configuration Variables**

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| **Infrastructure** | | | |
| `resource_group_name` | Name of the resource group | `monitor` | No |
| `location` | Azure region | `eastus` | No |
| `workspace_name` | Log Analytics workspace name | `mylaw` | No |
| `vm_name` | Virtual machine name | `monitor-vm` | No |
| `vm_size` | VM size (recommend Standard_B2s) | `Standard_B2s` | No |
| `admin_username` | VM admin username | `azureuser` | No |
| `subscription_id` | Azure subscription ID | `""` | **Yes** |
| `ssh_public_key_path` | Path to SSH public key | `~/.ssh/id_rsa.pub` | No |
| **Alert Configuration** | | | |
| `alert_email` | Email for alert notifications | `atul_kamble@hotmail.com` | **Yes** |
| `cpu_threshold` | CPU alert threshold (%) | `80` | No |
| `memory_threshold_gb` | Memory threshold (GB available) | `1.5` | No |
| `memory_threshold_bytes` | Memory threshold (bytes) | `1610612736` | No |
| `network_threshold_mb` | Network traffic threshold (MB/5min) | `100` | No |
| `network_threshold_bytes` | Network threshold (bytes) | `104857600` | No |
| `disk_ops_threshold` | Disk operations threshold (ops/sec) | `50` | No |

## 🔧 **Customization Examples**

### **Custom Alert Thresholds**
```hcl
# terraform.tfvars - Customize monitoring sensitivity
alert_email            = "alerts@mycompany.com"
cpu_threshold          = 75    # More sensitive CPU monitoring
memory_threshold_gb    = 2.0   # Higher memory threshold
network_threshold_mb   = 200   # Less sensitive network monitoring
disk_ops_threshold     = 100   # Higher disk activity threshold
```

### **Different Environment Configuration**
```hcl
# terraform.tfvars - Production environment
resource_group_name = "prod-monitoring"
location           = "westus2"
vm_size           = "Standard_B4ms"  # Larger VM for production
workspace_name    = "prod-law"
vm_name           = "prod-monitor-vm"
```

### **Development Environment**
```hcl
# terraform.tfvars - Cost-optimized development
vm_size              = "Standard_B1s"     # Smaller/cheaper
cpu_threshold        = 90                 # Less sensitive alerts
memory_threshold_gb  = 1.0                # Lower memory threshold
```

## 📊 **Deployed Resources**

After successful deployment, you'll have:

**Core Infrastructure:**
- ✅ Resource Group with proper tags
- ✅ Log Analytics Workspace (30-day retention) 
- ✅ Virtual Machine (Ubuntu 22.04 LTS, Standard_B2s)
- ✅ Virtual Network and Security Group (SSH access)
- ✅ Public IP and Network Interface

**Monitoring Components:**  
- ✅ OMS Agent for Linux (monitoring extension)
- ✅ VM Insights Solution for comprehensive monitoring
- ✅ Data Collection Rules for performance counters and logs
- ✅ Action Group for email notifications

**Enhanced Alert System (5 alerts):** ⭐ **NEW**
- ✅ **CPU High Alert**: >80% CPU usage (auto-mitigate enabled)
- ✅ **Memory Low Alert**: <1.5GB available memory  
- ✅ **Network Traffic Alert**: >100MB inbound in 5 minutes
- ✅ **VM Availability Alert**: Virtual machine downtime detection
- ✅ **Disk Performance Alert**: >50 disk write operations/sec

**All alerts include:**
- Auto-mitigation (alerts clear automatically)
- Validated metric names and configurations
- Production-ready error handling  
- Proper severity levels and descriptions

## 🔍 **Outputs**

Terraform provides useful outputs:

```bash
# Get all outputs
terraform output

# Get specific output
terraform output vm_public_ip
terraform output ssh_connection_command
```

## 🧪 **Testing the Deployment**

1. **Connect to VM**
```bash
# Use the SSH command from output
terraform output ssh_connection_command
# Or manually: ssh azureuser@<public-ip>
```

2. **Generate CPU Load (to test alerts)**
```bash
# Inside the VM
sudo apt update && sudo apt install stress-ng -y
stress-ng --cpu 2 --timeout 300s
```

3. **Monitor in Azure Portal**
- VM Insights: Monitor → Virtual Machines → your-vm
- Log Analytics: Log Analytics workspaces → your-workspace
- Alerts: Monitor → Alerts

## 🗑️ **Cleanup**

To remove all resources:

```bash
terraform destroy
```

Or use the project cleanup script:
```bash
cd ..
./scripts/cleanup.sh your-resource-group-name
```

## ⚠️ **Important Notes**

- **Email Configuration**: Update `alert_email` in terraform.tfvars
- **SSH Key**: Ensure your SSH public key exists at the specified path
- **VM Size**: Standard_B2s is recommended for monitoring workloads
- **OS Version**: Uses Ubuntu 22.04 LTS for OMS Agent compatibility
- **Agent Type**: Uses OMS Agent (not Azure Monitor Agent) for broader compatibility

## 🔧 **Troubleshooting**

### **Common Issues**

#### **VM Quota Exceeded**
```
Error: QuotaExceeded: Operation could not be completed...
```
**Solution**: Change `vm_size` in terraform.tfvars to a size you have quota for.

#### **SSH Key Not Found**
```
Error: no such file or directory: ~/.ssh/id_rsa.pub
```
**Solution**: Generate SSH key or update `ssh_public_key_path` in terraform.tfvars.

#### **Authentication Error**
```
Error: building account: unable to configure ResourceManagerAccount
```
**Solution**: Run `az login` and ensure you're authenticated to Azure.

## 🆚 **Terraform vs CLI Deployment**

| Feature | Terraform | CLI Script |
|---------|-----------|------------|
| **Infrastructure as Code** | ✅ Yes | ❌ No |
| **State Management** | ✅ Yes | ❌ No |
| **Customization** | ✅ High | ⚠️ Limited |
| **Rollback** | ✅ Easy | ❌ Manual |
| **CI/CD Integration** | ✅ Excellent | ⚠️ Basic |
| **Learning Curve** | ⚠️ Medium | ✅ Easy |
| **Quick Deployment** | ⚠️ More steps | ✅ One command |

Choose Terraform for production environments and infrastructure management. Choose CLI scripts for quick testing and demos.