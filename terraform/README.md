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
| `resource_group_name` | Name of the resource group | `monitor` | No |
| `location` | Azure region | `eastus` | No |
| `workspace_name` | Log Analytics workspace name | `mylaw` | No |
| `vm_name` | Virtual machine name | `monitor-vm` | No |
| `vm_size` | VM size (recommend Standard_B2s) | `Standard_B2s` | No |
| `admin_username` | VM admin username | `azureuser` | No |
| `alert_email` | Email for alerts | `atul_kamble@hotmail.com` | **Yes** |
| `cpu_threshold` | CPU alert threshold (%) | `80` | No |
| `ssh_public_key_path` | Path to SSH public key | `~/.ssh/id_rsa.pub` | No |

## 🔧 **Customization Examples**

### **Custom Email and Resource Names**
```hcl
# terraform.tfvars
resource_group_name = "my-monitoring"
workspace_name     = "my-workspace"
vm_name           = "my-monitor-vm"
alert_email       = "alerts@mycompany.com"
cpu_threshold     = 75
```

### **Different VM Size and Location**
```hcl
# terraform.tfvars
location = "westus2"
vm_size  = "Standard_B1s"  # Smaller/cheaper option
```

## 📊 **Deployed Resources**

After successful deployment, you'll have:

- ✅ Resource Group
- ✅ Log Analytics Workspace (30-day retention)
- ✅ Virtual Machine (Ubuntu 22.04 LTS)
- ✅ Virtual Network and Security Group
- ✅ Public IP and Network Interface  
- ✅ OMS Agent for Linux (monitoring extension)
- ✅ CPU Metric Alert (>80% threshold)
- ✅ Action Group for email notifications

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