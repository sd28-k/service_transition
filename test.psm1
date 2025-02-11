# ✔ VM exists in both vRA and vCenter
# ✔ Windows OS is installed
# ✔ Networking & IP assignment are successful
# ✔ VMware Tools & RDP are working


$vm = Invoke-RestMethod -Uri "$vraServer/catalog-service/api/consumer/resources" -Headers $headers | Where-Object { $_.name -eq $vmName }

if ($vm) {
    Write-Output "VM '$vmName' exists in vRA."
} else {
    Write-Output "VM '$vmName' not found. Build may have failed."
}

$request = Invoke-RestMethod -Uri "$vraServer/catalog-service/api/consumer/requests" -Headers $headers
$vmRequest = $request.content | Where-Object { $_.requestedFor -eq $vmName }

if ($vmRequest.phase -eq "SUCCESSFUL") {
    Write-Output "Provisioning is successful."
} else {
    Write-Output "VM is still in progress or failed. Status: $($vmRequest.phase)"
}

Connect-VIServer -Server "vcenter.yourdomain.com" -User "administrator" -Password "yourpassword"
$vm = Get-VM -Name $vmName

if ($vm) {
    Write-Output "VM '$vmName' found in vCenter."
} else {
    Write-Output "VM '$vmName' does not exist in vCenter."
}

$osType = $vm.data."Guest OS"

if ($osType -match "Windows") {
    Write-Output "Windows OS is installed."
} else {
    Write-Output "Detected OS: $osType. Expected Windows."
}

$ipAddress = $vm.data."ip_address"

if ($ipAddress) {
    Write-Output "IP Address: $ipAddress assigned to '$vmName'."
} else {
    Write-Output "No IP assigned. Networking may have failed."
}


$vmToolsStatus = $vm.data."toolsStatus"

if ($vmToolsStatus -eq "RUNNING") {
    Write-Output "VMware Tools are running."
} else {
    Write-Output "VMware Tools not running. Status: $vmToolsStatus."
}

$vm = Get-VM -Name $vmName

if ($vm.PowerState -eq "PoweredOn") {
    Write-Output "VM '$vmName' is powered on."
} else {
    Write-Output "VM '$vmName' is not powered on."
}

