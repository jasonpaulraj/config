<#
.SYNOPSIS
This script blocks or allows all .exe files in a specified directory by creating Windows Firewall rules.

.EXAMPLE
To run this script, use:
.\BlockExeWithFirewall.ps1 -DirectoryPath "D:\YourDirectory" -RulePrefix "[YourPrefix]" -Action "Block"

.PARAMETER DirectoryPath
Specifies the path to the directory containing .exe files to apply firewall rules to.

.PARAMETER RulePrefix
Specifies the prefix text to use in firewall rule names.

.PARAMETER Action
Specifies the action for the firewall rule, either "Block" or "Allow".
#>

param (
    [Parameter(Mandatory=$true)]
    [string]$DirectoryPath,

    [Parameter(Mandatory=$true)]
    [string]$RulePrefix,

    [Parameter(Mandatory=$true)]
    [ValidateSet("Block", "Allow")]
    [string]$Action
)

# Get all .exe files in the specified directory and create firewall rules
Get-ChildItem -Path $DirectoryPath -Filter *.exe | 
    Select-Object Name, FullName |
    ForEach-Object {
        # Create inbound firewall rule
        New-NetFirewallRule -DisplayName "$RulePrefix $($Action) $($_.Name) Inbound" `
                            -Direction Inbound `
                            -Program "$($_.FullName)" `
                            -Action $Action

        # Create outbound firewall rule
        New-NetFirewallRule -DisplayName "$RulePrefix $($Action) $($_.Name) Outbound" `
                            -Direction Outbound `
                            -Program "$($_.FullName)" `
                            -Action $Action
    }
