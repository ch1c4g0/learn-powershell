# This script extracts members and owners from Distribution Lists
## It prompts the user to enter the address associated with the group
### It provides error checking for unresolveable SID's.
#### This only extracts display names

$List = Read-Host "Enter the distribution list email address"

if ([string]::IsNullOrWhiteSpace($List)) {
    throw "Distribution list email address cannot be blank."
}

$Group = Get-DistributionGroup -Identity $List.Trim() -ErrorAction Stop

Write-Output "`nOWNERS"

$Group.ManagedBy |
    ForEach-Object {
        $Owner = $_.ToString()
        try {
            Get-Recipient -Identity $Owner -ErrorAction Stop |
                Select-Object -ExpandProperty DisplayName
        }
        catch {
            "[Unresolved] $Owner"
        }
    } |
    Sort-Object -Unique

Write-Output "`nMEMBERS"

Get-DistributionGroupMember -Identity $Group.PrimarySmtpAddress.ToString() -ResultSize Unlimited -ErrorAction Stop |
    Select-Object -ExpandProperty DisplayName |
    Sort-Object -Unique
