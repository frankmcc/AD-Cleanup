# Clear Screen
clear

# Define and clear Variables
$VarArray = ("Days"),("DisabledOu"),("ADPath"),("DisabledOuPath"),("OuTest"),("SAMnames")
Clear-Variable $VarArray

#  Make sure we load the AD Module
Import-Module ActiveDirectory

# Set the Number of days since last logon
$Days=45 

# List of User Accounts that must not be disabled or moved
# Example: 
# $SAMnames = ("user1"),("user2"),("user3")
$SAMnames = ("hcadmin")

# OU to move diabled accounts
$DisabledOu = "!Disabled Users and Computers"

# Domain Distinguished name 
$ADPath = "DC=hollandcomputers,DC=net"

#-----------Nothing below here should ever be changed --------------------#

$DisabledOuPath = "OU=$DisabledOu,$ADPath"

# Test to see if OU Exists and create it if it does not.
$Outest = [adsi]::Exists("LDAP://$DisabledOuPath")
    if($Outest){
    Write-Host $DisabledOu" exists"
    }
    Else{
    New-ADOrganizationalUnit -Name $DisabledOu
    Write-Host $DisabledOu" created"
    }

# Find our users that have not logged on in over $Days

Get-Aduser -Filter * -Properties LastLogonDate | 
 Where-Object {$_.SamAccountName -notin $SAMnames} |
 Where-Object {$_.LastLogonDate -ne $null}|
 Where-Object {$_.LastLogonDate -lt (Get-Date).AddDays(-$Days)} |
 Where-Object {$_.Enabled -eq "True"} |
 Where-object {$_.Surname -ne $null} |
 Set-ADObject -ProtectedFromAccidentalDeletion $false -PassThru |
 Move-ADObject -TargetPath $DisabledOuPath -PassThru |
 Disable-ADAccount -PassThru|
 Set-ADObject -ProtectedFromAccidentalDeletion $true


# List disabled users that have not logged on in over $Days to verify
Get-Aduser -Filter * -Properties LastLogonDate, Enabled |
 Where-Object {$_.LastLogonDate -ne $null}|
 Where-Object {$_.LastLogonDate -lt (Get-Date).AddDays(-$Days)} |
 Where-Object {$_.Enabled -ne "True"} |
 Where-object {$_.Surname -ne $null}  