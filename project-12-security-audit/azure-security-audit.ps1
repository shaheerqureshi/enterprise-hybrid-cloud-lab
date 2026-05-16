# ============================================
# Azure Security Audit Script
# Author: Shaheer Qureshi
# Description: Scans Azure environment for
# common security misconfigurations
# ============================================

param(
    [string]$SubscriptionId = "7b01d9ac-7159-4a86-b68c-773c66f39156",
    [string]$OutputPath = ".\security-audit-report.txt"
)

# Connect to Azure
Write-Host "`n[*] Connecting to Azure..." -ForegroundColor Cyan
$context = Get-AzContext
if (-not $context) {
    Connect-AzAccount
}
Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
Write-Host "[+] Connected to subscription: $SubscriptionId" -ForegroundColor Green

# Initialize report
$report = @()
$report += "============================================"
$report += "  AZURE SECURITY AUDIT REPORT"
$report += "  Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$report += "  Subscription: $SubscriptionId"
$report += "============================================"
$report += ""

$findings = 0

# CHECK 1: VMs with public IPs
Write-Host "`n[*] Checking VMs with public IPs..." -ForegroundColor Cyan
$report += "CHECK 1: VMs with direct public IP exposure"
$report += "--------------------------------------------"

$vms = Get-AzVM
foreach ($vm in $vms) {
    $nics = $vm.NetworkProfile.NetworkInterfaces
    foreach ($nicRef in $nics) {
        $nic = Get-AzNetworkInterface -ResourceId $nicRef.Id
        foreach ($ipConfig in $nic.IpConfigurations) {
            if ($ipConfig.PublicIpAddress) {
                $pip = Get-AzPublicIpAddress -ResourceId $ipConfig.PublicIpAddress.Id
                $report += "[FINDING] VM '$($vm.Name)' has public IP '$($pip.IpAddress)' directly exposed"
                $findings++
            }
        }
    }
}
if ($findings -eq 0) { $report += "[OK] No VMs with direct public IP exposure found" }
$report += ""

# CHECK 2: NSGs open to internet
Write-Host "[*] Checking NSGs for dangerous open rules..." -ForegroundColor Cyan
$report += "CHECK 2: NSGs with SSH or RDP open to internet"
$report += "------------------------------------------------"
$checkFindings = 0

$nsgs = Get-AzNetworkSecurityGroup
foreach ($nsg in $nsgs) {
    foreach ($rule in $nsg.SecurityRules) {
        if ($rule.Direction -eq "Inbound" -and
            $rule.Access -eq "Allow" -and
            ($rule.DestinationPortRange -match "22|3389") -and
            ($rule.SourceAddressPrefix -eq "*" -or
             $rule.SourceAddressPrefix -eq "Internet" -or
             $rule.SourceAddressPrefix -eq "0.0.0.0/0")) {
            $report += "[FINDING] NSG '$($nsg.Name)' has port $($rule.DestinationPortRange) open to ANY source (rule: $($rule.Name))"
            $findings++
            $checkFindings++
        }
    }
}
if ($checkFindings -eq 0) { $report += "[OK] No dangerous open NSG rules found" }
$report += ""

# CHECK 3: Storage accounts with public access
Write-Host "[*] Checking storage accounts for public blob access..." -ForegroundColor Cyan
$report += "CHECK 3: Storage accounts with public blob access"
$report += "--------------------------------------------------"
$checkFindings = 0

$storageAccounts = Get-AzStorageAccount
foreach ($sa in $storageAccounts) {
    if ($sa.AllowBlobPublicAccess -eq $true) {
        $report += "[FINDING] Storage account '$($sa.StorageAccountName)' has public blob access ENABLED"
        $findings++
        $checkFindings++
    }
}
if ($checkFindings -eq 0) { $report += "[OK] No storage accounts with public blob access found" }
$report += ""

# CHECK 4: Unattached public IPs
Write-Host "[*] Checking for unattached public IPs..." -ForegroundColor Cyan
$report += "CHECK 4: Unattached public IPs (wasting money)"
$report += "------------------------------------------------"
$checkFindings = 0

$pips = Get-AzPublicIpAddress
foreach ($pip in $pips) {
    if (-not $pip.IpConfiguration) {
        $report += "[FINDING] Public IP '$($pip.Name)' ($($pip.IpAddress)) is not attached to any resource"
        $findings++
        $checkFindings++
    }
}
if ($checkFindings -eq 0) { $report += "[OK] No unattached public IPs found" }
$report += ""

# CHECK 5: Subnets with no NSG
Write-Host "[*] Checking subnets for missing NSG protection..." -ForegroundColor Cyan
$report += "CHECK 5: Subnets with no NSG associated"
$report += "----------------------------------------"
$checkFindings = 0

$reservedSubnets = @("AzureFirewallSubnet", "AzureFirewallManagementSubnet", "AzureBastionSubnet", "GatewaySubnet")
$vnets = Get-AzVirtualNetwork
foreach ($vnet in $vnets) {
    foreach ($subnet in $vnet.Subnets) {
        if ($reservedSubnets -contains $subnet.Name) { continue }
        if (-not $subnet.NetworkSecurityGroup) {
            $report += "[FINDING] Subnet '$($subnet.Name)' in VNet '$($vnet.Name)' has NO NSG attached"
            $findings++
            $checkFindings++
        }
    }
}
if ($checkFindings -eq 0) { $report += "[OK] All subnets have NSG protection" }
$report += ""

# SUMMARY
$report += "============================================"
$report += "  AUDIT SUMMARY"
$report += "  Total findings: $findings"
if ($findings -eq 0) {
    $report += "  Status: CLEAN - No critical issues found"
} elseif ($findings -lt 5) {
    $report += "  Status: WARNING - Review findings above"
} else {
    $report += "  Status: CRITICAL - Immediate action required"
}
$report += "============================================"

# Output to console and file
$report | ForEach-Object { Write-Host $_ }
$report | Out-File -FilePath $OutputPath -Encoding UTF8
Write-Host "`n[+] Report saved to: $OutputPath" -ForegroundColor Green
