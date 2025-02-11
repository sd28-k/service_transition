param (
    [string]$VMNameOrIP,   # VM Name or IP Address
    [string]$Username,     # Username for authentication
    [string]$Password      # Password for authentication
)

# Convert password to SecureString
$securePassword = ConvertTo-SecureString $Password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($Username, $securePassword)

# Test VM connectivity
if (-not (Test-Connection -ComputerName $VMNameOrIP -Count 2 -Quiet)) {
    Write-Host "VM $VMNameOrIP is unreachable!"
    exit 1
}

try {
    $scriptBlock = {
        # Alternative method: Using SystemInfo to fetch OS version
        $osInfo = systeminfo
        $osVersion = $osInfo | Select-String -Pattern "OS"
        
        # Extract OS version and build from SystemInfo output
        $osName = $osVersion.ToString().Trim().Split(':')[1].Trim()
        
        # Check VMware Tools status
        $vmwareTools = Get-Service -Name VMTools -ErrorAction SilentlyContinue

        if ($vmwareTools -and $vmwareTools.Status -eq 'Running') {
            $vmwareToolsRunning = $true
        } else {
            $vmwareToolsRunning = $false
        }

        return @{
            OSName = $osName
            VMwareToolsRunning = $vmwareToolsRunning
        }
    }

    # Run script remotely
    $result = Invoke-Command -ComputerName $VMNameOrIP -Credential $cred -ScriptBlock $scriptBlock

    # Display results
    Write-Host "VM: $VMNameOrIP"
    Write-Host "OS Name: $($result.OSName)"
    Write-Host "VMware Tools Running: $($result.VMwareToolsRunning)"

} catch {
    Write-Host "Failed to connect or execute script on $VMNameOrIP. Error: $_"
    exit 1
}
