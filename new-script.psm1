param (
    [string]$VMNameOrIP,   # VM Name or IP Address
    [string]$Username,     # Username for authentication
    [string]$Password      # Password for authentication
)

# Convert password to SecureString
$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)

# Test if VM is reachable
if (-not (Test-Connection -ComputerName $VMNameOrIP -Count 2 -Quiet)) {
    Write-Host "VM $VMNameOrIP is unreachable!"
    exit 1
}

# Run script remotely using Invoke-Command
try {
    $scriptBlock = {
        # Get OS information
        $os = Get-CimInstance Win32_OperatingSystem

        # Check if Windows is installed
        if (-not $os) {
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

        # Return OS and VMware Tools details
        return @{
            OSName = $osName
            OSVersion = $osVersion
            OSBuild = $osBuild
            VMwareToolsRunning = $true
        }
    }

    # Execute script remotely
    $result = Invoke-Command -ComputerName $VMNameOrIP -Credential $cred -ScriptBlock $scriptBlock

    # Display results
    Write-Host "VM: $VMNameOrIP"
    Write-Host "OS Name: $($result.OSName)"
    Write-Host "OS Version: $($result.OSVersion)"
    Write-Host "OS Build: $($result.OSBuild)"
    Write-Host "VMware Tools Running: $($result.VMwareToolsRunning)"

} catch {
    Write-Host "Failed to connect or execute script on $VMNameOrIP. Error: $_"
    exit 1
}
