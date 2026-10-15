
# This script extracts members and owners from M365 Exchange Groups
## It prompts the user to enter the address associated with the group
### It provides error checking for unresolveable SID's.
#### This only extracts display names

$Group = Read-Host "Enter the Microsoft 365 group email address"

if ([string]::IsNullOrWhiteSpace($Group)) {
    throw "Group email address cannot be blank."
}

# Validate the group.
$Group = (Get-UnifiedGroup -Identity $Group.Trim() -ErrorAction Stop).PrimarySmtpAddress.ToString()

Write-Output "`nOWNERS"

Get-UnifiedGroupLinks -Identity $Group -LinkType Owners -ResultSize Unlimited -ErrorAction Stop |
    Select-Object -ExpandProperty DisplayName |
    Sort-Object -Unique

Write-Output "`nMEMBERS"

Get-UnifiedGroupLinks -Identity $Group -LinkType Members -ResultSize Unlimited -ErrorAction Stop |
    Select-Object -ExpandProperty DisplayName |
    Sort-Object -Unique
