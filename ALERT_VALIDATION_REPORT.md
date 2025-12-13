# Azure Monitor Alerts - Validation & Updates Report

## 🔍 Command Validation Summary

Your original alert commands have been **validated, corrected, and enhanced** with current Azure Monitor best practices.

## ✅ Validation Results

### 1. **CPU High Alert** - ✅ VALIDATED & IMPROVED
**Original Command:**
```bash
az monitor metrics alert create \
  --name cpu-high-alert \
  --resource-group monitor \
  --scopes $VM_ID \
  --condition "avg Percentage CPU > 80" \
  --description "CPU exceeds 80% for 5 minutes" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action $ACTION_GROUP_ID
```

**✅ Updates Applied:**
- ✅ **Metric name quoted**: `"avg 'Percentage CPU' > 80"` (prevents parsing issues)
- ✅ **Added `--auto-mitigate true`**: Automatically resolves alert when condition is no longer met
- ✅ **Added `--verbose`**: Better debugging output
- ✅ **Variable quoting**: `"$RG"`, `"$VM_ID"` (safer bash scripting)

### 2. **Memory Low Alert** - ⚠️ CORRECTED & IMPROVED
**Original Command:**
```bash
az monitor metrics alert create \
  --name memory-low-alert \
  --resource-group monitor \
  --scopes $VM_ID \
  --condition "avg Available Memory Percentage < 15" \
  --description "Available memory is below 15%" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action $ACTION_GROUP_ID \
  || echo "Memory alert skipped - metric may not be available yet"
```

**⚠️ Issues Found & Fixed:**
- ❌ **Incorrect metric name**: `Available Memory Percentage` doesn't exist for VM host metrics
- ✅ **Fixed metric name**: `Available Memory Bytes` with threshold `< 1610612736` (1.5GB)
- ✅ **Better error handling**: More descriptive error message about Azure Monitor Agent requirement
- ✅ **Logical threshold**: Uses absolute memory value instead of percentage

### 3. **Disk Space Alert** - ⚠️ CORRECTED & IMPROVED
**Original Command:**
```bash
az monitor metrics alert create \
  --name disk-space-alert \
  --resource-group monitor \
  --scopes $VM_ID \
  --condition "avg Free Space Percentage < 10" \
  --description "Disk free space is below 10%" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 2 \
  --action $ACTION_GROUP_ID \
  || echo "Disk space alert skipped - metric may not be available yet"
```

**⚠️ Issues Found & Fixed:**
- ❌ **Incorrect metric name**: `Free Space Percentage` doesn't exist for VM host metrics
- ✅ **Fixed metric name**: `Disk Free Space %` (correct Azure Monitor metric)
- ✅ **Dependency note**: Added clear explanation about Azure Monitor Agent requirement

## 🚀 Additional Improvements Added

### 4. **Network Traffic Alert** - 🆕 NEW
```bash
az monitor metrics alert create \
  --name network-in-high-alert \
  --resource-group "$RG" \
  --scopes "$VM_ID" \
  --condition "total 'Network In Total' > 104857600" \
  --description "High network inbound traffic detected (>100MB in 5 minutes)" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 3 \
  --action "$ACTION_GROUP_ID"
```

### 5. **VM Availability Alert** - 🆕 NEW
```bash
az monitor metrics alert create \
  --name vm-availability-alert \
  --resource-group "$RG" \
  --scopes "$VM_ID" \
  --condition "avg 'VmAvailabilityMetric' < 1" \
  --description "Virtual Machine is not available" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --severity 1 \
  --action "$ACTION_GROUP_ID"
```

## 📊 Correct Azure VM Metrics

| Alert Type | Correct Metric Name | Availability | Threshold |
|-----------|-------------------|-------------|-----------|
| **CPU Usage** | `Percentage CPU` | ✅ Always available (host-level) | `> 80` |
| **Memory** | `Available Memory Bytes` | ⚠️ Requires Azure Monitor Agent | `< 1610612736` (1.5GB) |
| **Disk Space** | `Disk Free Space %` | ⚠️ Requires Azure Monitor Agent | `< 10` |
| **Network In** | `Network In Total` | ✅ Always available (host-level) | `> 104857600` (100MB) |
| **VM Availability** | `VmAvailabilityMetric` | ✅ Always available | `< 1` |

## 🔧 Script Enhancements

### Error Handling
- ✅ **Resource validation**: Checks if VM and Action Group exist before creating alerts
- ✅ **Graceful failures**: Continues with other alerts if one fails
- ✅ **Clear error messages**: Descriptive feedback for troubleshooting

### Security & Reliability
- ✅ **Variable quoting**: Prevents injection and handles spaces in names
- ✅ **Exit on error**: `set -e` prevents cascading failures
- ✅ **Parameterization**: Supports custom resource names

### User Experience
- ✅ **Progress indicators**: Clear feedback during execution
- ✅ **Summary output**: Lists all created alerts
- ✅ **Documentation**: Inline comments and usage instructions

## 🎯 Usage Instructions

### Run the Updated Script:
```bash
# Using defaults (monitor RG, monitor-vm, monitor-action-group)
./scripts/create-alert.sh

# With custom parameters
./scripts/create-alert.sh my-rg my-vm my-action-group
```

### Validate Configuration:
```bash
# Validate current setup and check available metrics
./scripts/validate-alerts.sh monitor monitor-vm
```

## ⚠️ Important Notes

1. **Host vs Guest Metrics**: 
   - CPU and Network metrics are always available (host-level)
   - Memory and Disk metrics require Azure Monitor Agent for guest OS access

2. **Alert Dependencies**:
   - Ensure Action Groups exist before creating alerts
   - VM must be running and have been operational for metrics to be available

3. **Best Practices Applied**:
   - Auto-mitigation enabled for faster resolution
   - Appropriate severity levels (1=Critical, 2=Error, 3=Warning)
   - 5-minute evaluation windows for balance between responsiveness and noise

Your original commands were mostly correct but needed metric name corrections and enhanced error handling. The updated version follows current Azure Monitor best practices and provides better reliability.