# Define the computer name and ServiceNow instance details
$ComputerName = "ApplicationServerName"  # Replace with the target application server name
$ServiceNowInstance = "<instance>"  # Replace with your ServiceNow instance name
$ServiceNowUser = "<username>"  # Replace with ServiceNow username
$ServiceNowPassword = "<password>"  # Replace with ServiceNow password
$SysId = "<sys_id>"  # Replace with the sys_id of the server in ServiceNow's CMDB table

# Set up ServiceNow API URL for CMDB table
$ServiceNowUrl = "https://$ServiceNowInstance.service-now.com/api/now/table/cmdb_ci_computer/$SysId"

# Encode the credentials for basic authentication
$ServiceNowAuth = [System.Convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes("$ServiceNowUser:$ServiceNowPassword"))
$Headers = @{Authorization = "Basic $ServiceNowAuth"}

# Get local system information (WMI - Computer System)
$LocalComputerInfo = Get-WmiObject -Class Win32_ComputerSystem

# Get the logged-in user (this might give an idea of owner)
$LocalOwner = $LocalComputerInfo.UserName

# Query Active Directory if the server is domain-joined for department info
$LocalDepartment = "Not Available"
try {
    $ADComputerInfo = Get-ADComputer -Identity $ComputerName -Properties Department
    $LocalDepartment = $ADComputerInfo.Department
} catch {
    Write-Host "Active Directory query failed: $($_.Exception.Message)"
}

# Output local system information for reference
Write-Host "Local Owner: $LocalOwner"
Write-Host "Local Department: $LocalDepartment"

# Query ServiceNow API to get department info for the system
try {
    $ServiceNowResponse = Invoke-RestMethod -Uri $ServiceNowUrl -Headers $Headers -Method Get
    $ServiceNowDepartment = $ServiceNowResponse.result.department
    $ServiceNowOwner = $ServiceNowResponse.result.assigned_to.display_value
} catch {
    Write-Host "ServiceNow API query failed: $($_.Exception.Message)"
    exit
}

# Output ServiceNow information for reference
Write-Host "ServiceNow Owner: $ServiceNowOwner"
Write-Host "ServiceNow Department: $ServiceNowDepartment"

# Compare the department and owner information
$departmentMatch = $LocalDepartment -eq $ServiceNowDepartment
$ownerMatch = $LocalOwner -eq $ServiceNowOwner

if ($departmentMatch -and $ownerMatch) {
    Write-Host "Validation passed: Department and Owner information match."
} else {
    Write-Host "Validation failed: Department and/or Owner information mismatch."
    if (-not $departmentMatch) {
        Write-Host "Department mismatch: Local ($LocalDepartment), ServiceNow ($ServiceNowDepartment)"
    }
    if (-not $ownerMatch) {
        Write-Host "Owner mismatch: Local ($LocalOwner), ServiceNow ($ServiceNowOwner)"
    }
}

# Optionally, you can log these results to a file for tracking purposes
$logFile = "C:\path\to\logfile.txt"
$logMessage = "Validation results for $ComputerName`n"
$logMessage += "Local Owner: $LocalOwner`n"
$logMessage += "Local Department: $LocalDepartment`n"
$logMessage += "ServiceNow Owner: $ServiceNowOwner`n"
$logMessage += "ServiceNow Department: $ServiceNowDepartment`n"
$logMessage += if ($departmentMatch -and $ownerMatch) {"Validation passed."} else {"Validation failed."}
Add-Content -Path $logFile -Value $logMessage
