
# This script extracts "send as" and "Full access" delegates from exchange shared-mailboxes. 
## Once ran, it prompts for the address.
### It will then spit out users in two groups, send as and full access, as well as error checking for unresolvable SID's

$Mailbox = Read-Host "Enter the shared mailbox email address"

if ([string]::IsNullOrWhiteSpace($Mailbox)) {
    throw "Mailbox address cannot be blank."
}

# Validate the mailbox before retrieving permissions.
$Mailbox = (Get-Mailbox -Identity $Mailbox.Trim() -ErrorAction Stop).PrimarySmtpAddress.ToString()

function Resolve-DelegateName {
    param([string]$Identity)

    if ([string]::IsNullOrWhiteSpace($Identity)) {
        return "[Unresolved: empty identity]"
    }

    # Try resolving an Exchange recipient.
    try {
        $Recipient = Get-Recipient -Identity $Identity -ErrorAction Stop
        if ($Recipient.DisplayName) {
            return $Recipient.DisplayName
        }
    }
    catch {}

    # Fall back to a user lookup, including by SID.
    try {
        if ($Identity -match '^S-\d-\d+(-\d+)+$') {
            $Delegate = Get-User -Filter "Sid -eq '$Identity'" -ErrorAction Stop
        }
        else {
            $Delegate = Get-User -Identity $Identity -ErrorAction Stop
        }

        if ($Delegate.DisplayName) {
            return $Delegate.DisplayName
        }
    }
    catch {}

    return "[Unresolved] $Identity"
}

Write-Output "`nFULL ACCESS"

Get-MailboxPermission -Identity $Mailbox -ErrorAction Stop |
    Where-Object {
        $_.AccessRights -contains "FullAccess" -and
        -not $_.IsInherited -and
        -not $_.Deny -and
        $_.User.ToString() -notin @("NT AUTHORITY\SELF", "S-1-5-10")
    } |
    ForEach-Object {
        Resolve-DelegateName -Identity $_.User.ToString()
    } |
    Sort-Object -Unique

Write-Output "`nSEND AS"

Get-RecipientPermission -Identity $Mailbox -ErrorAction Stop |
    Where-Object {
        $_.AccessRights -contains "SendAs" -and
        $_.AccessControlType -eq "Allow" -and
        $_.Trustee.ToString() -notin @("NT AUTHORITY\SELF", "S-1-5-10")
    } |
    ForEach-Object {
        Resolve-DelegateName -Identity $_.Trustee.ToString()
    } |
    Sort-Object -Unique
