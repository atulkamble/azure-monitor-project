# 🔍 **Azure Monitor Complete Project**

> **Comprehensive Azure monitoring solution with multiple deployment options**

## ✨ **Features**
- ✅ Complete infrastructure deployment (VM, VNet, Log Analytics)
- ✅ Azure Monitor Agent with VM Insights
- ✅ CPU, Memory, Disk, and Network metrics alerts
- ✅ Custom Azure Dashboard with performance widgets
- ✅ Multiple deployment methods (CLI, Terraform, Bicep)
- ✅ One-click deployment script
- ✅ Cleanup and maintenance scripts

---

## 🏗️ **Architecture**

```mermaid
flowchart TD
    A[Azure Virtual Machine] -->|Azure Monitor Agent| B[Log Analytics Workspace]
    B --> C[Azure Monitor]
    C --> D[Metric Alerts]
    C --> E[VM Insights]
    C --> F[Custom Dashboard]
    G[Virtual Network] --> A
    H[Public IP] --> A
    I[Network Security Group] --> A
```

---

## 📊 **Monitoring Components**

| Component | Purpose | Metrics Collected |
|-----------|---------|------------------|
| **Log Analytics Workspace** | Centralized log storage and analysis | System logs, performance counters, events |
| **Azure Monitor Agent** | Data collection from VM | CPU, Memory, Disk, Network, Process data |
| **VM Insights** | Comprehensive VM monitoring | Performance maps, dependency tracking |
| **Metric Alerts** | Proactive monitoring notifications | CPU >80%, Memory >85%, Disk space <10% |
| **Custom Dashboard** | Visual performance overview | Real-time charts and KPI widgets |

---

## 📁 **Project Structure**

```
azure-monitor-project/
├── 📜 README.md                    # This documentation
├── 📋 DEPLOYMENT.md                # Quick deployment guide
├── 📊 dashboard.json               # Azure Dashboard template
├── 📂 scripts/                     # Deployment and management scripts
│   ├── 🚀 deploy-all.sh           # One-click complete deployment
│   ├── 📊 create-law.sh           # Log Analytics Workspace setup
│   ├── 🔍 enable-vminsights.sh    # VM Insights configuration
│   ├── ⚠️ create-alert.sh         # Metric alerts setup
│   └── 🧹 cleanup.sh              # Resource cleanup
├── 📂 terraform/                   # Infrastructure as Code (Terraform)
│   ├── main.tf                    # Main Terraform configuration
│   ├── variables.tf               # Input variables
│   └── outputs.tf                 # Output values
└── 📂 bicep/                      # Infrastructure as Code (Bicep)
    ├── main.bicep                 # Main deployment template
    ├── loganalytics.bicep         # Log Analytics resources
    ├── vminsights.bicep           # VM monitoring setup
    └── alerts.bicep               # Alert rules configuration
```

---

## 🚀 **Quick Start**

### ⚡ **Option 1: One-Click Deployment**
```bash
# Clone and deploy everything in one command
git clone https://github.com/atulkamble/azure-monitor-project.git
cd azure-monitor-project
chmod +x scripts/deploy-all.sh
./scripts/deploy-all.sh
```

### 🏗️ **Option 2: Terraform Deployment**
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 📐 **Option 3: Bicep Deployment**
```bash
az deployment sub create \
  --location eastus \
  --template-file bicep/main.bicep \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
```

### 📋 **Option 4: Step-by-Step Manual**
See [DEPLOYMENT.md](DEPLOYMENT.md) for detailed manual deployment steps.

---

## 🛠️ **Prerequisites**

Before deploying, ensure you have:

- ✅ **Azure CLI** installed and authenticated (`az login`)
- ✅ **SSH key pair** generated (`ssh-keygen -t rsa -b 2048`)
- ✅ **Terraform** (optional, for Terraform deployment)
- ✅ **Azure subscription** with appropriate permissions
- ✅ **Resource quota** for VM deployment in target region

---

## 🎯 **Deployed Resources**

After successful deployment, you'll have:

| Resource Type | Resource Name | Purpose |
|---------------|---------------|---------|
| **Resource Group** | `monitor` | Container for all resources |
| **Log Analytics Workspace** | `mylaw` | Centralized logging and analytics |
| **Virtual Machine** | `monitor-vm` | Ubuntu VM for monitoring |
| **Virtual Network** | `monitor-vnet` | Isolated network environment |
| **Public IP** | `monitor-vm-pip` | External access to VM |
| **Network Security Group** | `monitor-vm-nsg` | Network security rules |
| **Metric Alerts** | `cpu-high-alert` + others | Proactive monitoring |
| **Dashboard** | `Azure Monitor Dashboard` | Visual monitoring interface |

---

## 📊 **Monitoring Features**

### 🔍 **VM Insights**
- Real-time performance monitoring
- Process and dependency mapping  
- Historical performance trends
- Capacity planning insights

### ⚠️ **Metric Alerts**
- **CPU Alert**: Triggers when CPU > 80% for 5 minutes
- **Memory Alert**: Triggers when available memory < 15%
- **Disk Alert**: Triggers when free disk space < 10%
- **Network Alert**: Monitors network connectivity issues

### 📈 **Dashboard Widgets**
- CPU utilization charts
- Memory usage graphs
- Disk I/O performance
- Network traffic visualization
- Alert status overview

---

## 🧪 **Testing & Validation**

### Generate Test Load
```bash
# SSH into the VM
ssh azureuser@<vm-public-ip>

# Generate CPU load to trigger alerts
stress --cpu 2 --timeout 300s

# Check memory usage
free -h

# Monitor disk I/O
iostat -x 1
```

### Verify Monitoring
1. **Azure Portal** → **Monitor** → **Metrics**
2. **Virtual Machines** → **monitor-vm** → **Insights**
3. **Monitor** → **Alerts** → Check alert rules
4. **Dashboards** → View custom dashboard

---

## 🛠️ **Infrastructure as Code**

### 🌱 **Terraform Configuration**

The Terraform implementation provides complete infrastructure deployment:

**Key Resources:**
- Resource Group with configurable name and location
- Log Analytics Workspace with PerGB2018 pricing tier  
- Virtual Network with subnets and security groups
- Ubuntu VM with SSH key authentication
- Azure Monitor Agent extension
- Multiple metric alerts (CPU, Memory, Disk)
- Network security rules for SSH access

**Deployment:**
```bash
cd terraform
terraform init
terraform plan -var="admin_username=your-username"
terraform apply
```

### 📐 **Bicep Templates**

Modular Bicep templates for Azure-native deployment:

**Template Structure:**
- **`main.bicep`**: Orchestrates all deployments at subscription scope
- **`loganalytics.bicep`**: Log Analytics Workspace and data collection rules
- **`vminsights.bicep`**: VM Insights configuration and monitoring extensions  
- **`alerts.bicep`**: Comprehensive metric alerting rules

**Features:**
- Parameterized for flexible deployment
- Subscription-scoped deployment
- Automatic networking and security configuration
- VM Insights with dependency tracking

---

## 📊 **Log Analytics Queries**

### 🔍 **Performance Monitoring**
```kusto
// CPU utilization over time
Perf
| where ObjectName == "Processor" and CounterName == "% Processor Time"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m)
| render timechart

// Memory usage analysis  
Perf
| where ObjectName == "Memory" and CounterName == "Available MBytes"
| summarize avg(CounterValue) by bin(TimeGenerated, 5m)
| render timechart

// Disk space monitoring
Perf
| where ObjectName == "LogicalDisk" and CounterName == "% Free Space"
| summarize avg(CounterValue) by bin(TimeGenerated, 1h), InstanceName
| render timechart
```

### 🚨 **Alert Investigation**
```kusto
// Recent alerts fired
Alert
| where TimeGenerated > ago(24h)
| summarize count() by AlertName, AlertSeverity
| order by count_ desc

// VM heartbeat monitoring
Heartbeat
| where Computer contains "monitor-vm"
| summarize max(TimeGenerated) by Computer
| where max_TimeGenerated < ago(5m)
```

---

## 🧹 **Cleanup & Maintenance**

### 🗑️ **Resource Cleanup**
```bash
# Remove all resources
chmod +x scripts/cleanup.sh
./scripts/cleanup.sh

# Or manual cleanup
az group delete --name monitor --yes --no-wait
```

### 🔄 **Update Management**
```bash
# Update Azure Monitor Agent
az vm extension set \
  --publisher Microsoft.Azure.Monitor \
  --name AzureMonitorLinuxAgent \
  --resource-group monitor \
  --vm-name monitor-vm \
  --enable-auto-upgrade true
```

### 💰 **Cost Optimization**
- **VM Size**: Consider B-series burstable VMs for dev/test
- **Log Retention**: Configure appropriate retention policies
- **Alert Frequency**: Balance monitoring needs with costs
- **Data Collection**: Use targeted data collection rules

---

## 🐛 **Troubleshooting**

### Common Issues & Solutions

| Issue | Cause | Solution |
|-------|-------|----------|
| **VM Agent not reporting** | Extension not installed | Run `enable-vminsights.sh` script |
| **No metrics in dashboard** | Data collection delay | Wait 5-10 minutes for initial data |
| **Alerts not firing** | Threshold misconfiguration | Check alert rule criteria |
| **SSH connection failed** | NSG rules or key issues | Verify security group and SSH keys |

### 🔧 **Debug Commands**
```bash
# Check VM extension status
az vm extension list --resource-group monitor --vm-name monitor-vm

# Verify Log Analytics connection
az monitor log-analytics workspace show --resource-group monitor --workspace-name mylaw

# List active alerts
az monitor metrics alert list --resource-group monitor
```

---

## 📚 **Additional Resources**

### 📖 **Documentation**
- [Azure Monitor Documentation](https://docs.microsoft.com/en-us/azure/azure-monitor/)
- [VM Insights Overview](https://docs.microsoft.com/en-us/azure/azure-monitor/insights/vminsights-overview)
- [Log Analytics Workspace](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/log-analytics-workspace-overview)
- [Azure Monitor Agent](https://docs.microsoft.com/en-us/azure/azure-monitor/agents/azure-monitor-agent-overview)

### 🎓 **Learning Paths**
- [Monitor and back up Azure resources](https://docs.microsoft.com/en-us/learn/paths/monitor-backup-azure-resources/)
- [Implement resource management security in Azure](https://docs.microsoft.com/en-us/learn/paths/implement-resource-mgmt-security/)

### 🔗 **Related Projects**
- [Azure Monitoring Best Practices](https://github.com/Azure/azure-monitor-baseline-alerts)
- [Azure Resource Manager Templates](https://github.com/Azure/azure-quickstart-templates)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)

---

## 🤝 **Contributing**

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### 📋 **Development Setup**
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### 🧪 **Testing**
- Test deployments in a separate Azure subscription
- Validate all deployment methods (CLI, Terraform, Bicep)
- Ensure cleanup scripts work properly
- Verify monitoring functionality

---

## 📄 **License**

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## ⭐ **Acknowledgments**

- Azure Monitor team for excellent documentation
- Community contributors for best practices
- Microsoft Learn for comprehensive tutorials

---

> **💡 Tip**: Star this repository if you find it helpful and share it with others who are learning Azure monitoring!
