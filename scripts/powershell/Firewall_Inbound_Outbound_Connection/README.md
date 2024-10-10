# BlockExeWithFirewall.ps1

This PowerShell script creates Windows Firewall rules to block or allow all `.exe` files in a specified directory. You can define the directory path, rule prefix, and firewall action (either "Block" or "Allow") through command-line parameters.

## Usage Example

To run the script, use the following syntax:

```powershell
.\BlockExeWithFirewall.ps1 -DirectoryPath "D:\YourDirectory" -RulePrefix "[YourPrefix]" -Action "Block"
```
