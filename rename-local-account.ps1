# Lists all local user accounts
## Renames local user account to new specified prompted name
### Prompts for change to full Display Name


#Requires -Version 5.1
#Requires -RunAsAdministrator
<#
Run in 64-bit PowerShell as Administrator on the target Windows computer.
Lists local accounts, prompts for changes, and asks for confirmation.
Blank input preserves the current value. Q exits account selection.
The profile folder, password, SID, and permissions are preserved.
#>

& {
    $ErrorActionPreference = 'Stop'
    try {
        Import-Module Microsoft.PowerShell.LocalAccounts -ErrorAction Stop
        $accounts = @(Get-LocalUser | Sort-Object Name)
        if ($accounts.Count -eq 0) {
            Write-Host 'No local accounts found.'
            return
        }

        Write-Host "`nLocal accounts on $env:COMPUTERNAME" -ForegroundColor Cyan
        $rows = for ($i = 0; $i -lt $accounts.Count; $i++) {
            [pscustomobject]@{
                Number = $i + 1
                Username = $accounts[$i].Name
                DisplayName = $accounts[$i].FullName
                Enabled = $accounts[$i].Enabled
                Source = $accounts[$i].PrincipalSource
            }
        }
        $rows | Format-Table -AutoSize | Out-Host

        while ($true) {
            $choice = (Read-Host 'Select an account number (Q to quit)').Trim()
            if ($choice -ieq 'Q') { return }
            $number = 0
            if ([int]::TryParse($choice, [ref]$number) -and
                $number -ge 1 -and $number -le $accounts.Count) {
                break
            }
            Write-Host 'Enter a valid account number.' -ForegroundColor Yellow
        }

        $account = $accounts[$number - 1]
        $sid = $account.SID
        if ([string]$account.PrincipalSource -ne 'Local') {
            Write-Warning 'This account is not identified as a standalone local account. Manage its name in its identity provider.'
            return
        }
        Write-Host "`nSelected: $($account.Name) | Display name: $($account.FullName)"

        while ($true) {
            $newName = (Read-Host 'New username (Enter to keep current)').Trim()
            if ([string]::IsNullOrWhiteSpace($newName)) { $newName = $account.Name }
            if ($newName.Length -gt 20 -or $newName -match '["/\\\[\]:;|=,+*?<>\x00-\x1F]' -or
                $newName -match '^[. ]+$' -or $newName.EndsWith('.')) {
                Write-Host 'Use 1-20 characters, no trailing period, and no invalid username characters.' -ForegroundColor Yellow
                continue
            }
            $duplicate = @(Get-LocalUser | Where-Object {
                $_.Name -ieq $newName -and $_.SID.Value -ne $sid.Value
            })
            if ($duplicate.Count -gt 0) {
                Write-Host 'That username already exists. Choose another.' -ForegroundColor Yellow
                continue

}
            break
        }

        $newFullName = (Read-Host 'New display name (Enter to keep current)').Trim()
        if ([string]::IsNullOrWhiteSpace($newFullName)) { $newFullName = $account.FullName }
        $rename = $newName -cne $account.Name
        $changeDisplay = $newFullName -cne $account.FullName
        if (-not $rename -and -not $changeDisplay) {
            Write-Host 'No changes requested.'
            return
        }

        Write-Host "`nProposed changes" -ForegroundColor Cyan
        Write-Host "Username:     $($account.Name) -> $newName"
        Write-Host "Display name: $($account.FullName) -> $newFullName"
        Write-Host 'The existing C:\Users profile folder will keep its current name.'
        if ((Read-Host 'Apply these changes? (Y/N)').Trim() -ine 'Y') {
            Write-Host 'Cancelled. No changes made.'
            return
        }

        # Use the stable SID so both operations target the same account after a rename.
        if ($rename) {
            Rename-LocalUser -SID $sid -NewName $newName
            Write-Host 'Username updated.' -ForegroundColor Green
        }
        if ($changeDisplay) {
            Set-LocalUser -SID $sid -FullName $newFullName
            Write-Host 'Display name updated.' -ForegroundColor Green
        }
        Get-LocalUser -SID $sid | Select-Object Name, FullName, Enabled, SID |
            Format-List | Out-Host
        Write-Host 'Have the user sign out and back in. Use the new username at the next sign-in.'
    }
    catch {
        Write-Warning "Operation stopped: $($_.Exception.Message)"
        Write-Warning 'Any changes already reported as updated remain applied. Check the current account details before retrying.'
    }
}
