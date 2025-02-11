# Get OS information
$os = Get-CimInstance Win32_OperatingSystem

# Check if Windows is installed
if ($os) {
    Write-Host "Windows OS detected: $($os.Caption)"
} else {
    Write-Host "No Windows OS detected!"
    exit 1
}

# Get OS version and build number
$osVersion = $os.Version
$osBuild = $os.BuildNumber
$osName = $os.Caption

# Check if the OS is Windows Server 2019 or 2022
if ($osName -match "Windows Server 2019|Windows Server 2022") {
    Write-Host "OS is valid: $osName (Version: $osVersion, Build: $osBuild)"
} else {
    Write-Host "Invalid OS: $osName"
    exit 1
}

# Check VMware Tools status
$vmwareTools = Get-Service -Name VMTools -ErrorAction SilentlyContinue

if ($vmwareTools -and $vmwareTools.Status -eq 'Running') {
    Write-Host "VMware Tools is running."
} else {
    Write-Host "VMware Tools is NOT running or not installed!"
    exit 1
}

# Output results
return @{
    OSName = $osName
    OSVersion = $osVersion
    OSBuild = $osBuild
    VMwareToolsRunning = $true
}
