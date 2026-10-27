
# Forces user to change password on next logon.

## DO NOT USE ON ACTIVE DIRECTORY OR ENTRAID COMPUTERS, FOR LOCAL ACCOUNTS ONLY!


# Require local users to change passwords at next login
# Run as SYSTEM through NinjaOne

$ExcludedAccounts = @(
    "Administrator",
    "DefaultAccount",
    "Guest",
    "WDAGUtilityAccount",
    "Rymark"
)

$Users = Get-LocalUser | Where-Object {
    $_.Enabled -eq $true -and
    $_.Name -notin $ExcludedAccounts -and
    $_.SID.Value -notmatch '-500$' -and
    $_.PrincipalSource -eq 'Local'
}

foreach ($User in $Users) {
    try {
        $Username = $User.Name

        # Require password change at next login
        $Account = [ADSI]"WinNT://$env:COMPUTERNAME/$Username,user"
        $Account.Put("PasswordExpired", 1)
        $Account.SetInfo()

        Write-Output "SUCCESS: $Username must change password at next login."
    }
    catch {
        Write-Output "ERROR: $($User.Name) - $($_.Exception.Message)"
    }
}
