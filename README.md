# Summary
A script to remove AD users from AD groups, based on given memberships.  

See also: https://github.com/engrit-illinois/Add-AdGroupMemberships  

# Behavior
- Accepts a CSV file with one row for each user-in-group membership which should be removed. See documentation of `-InputCsv` parameter.
- Validates that all given AD objects and memberships exist.
- Performs the membership removals.
- Outputs results to new CSV.

# Requirements
- Requires RSAT to be installed.
- Must be run as a user account with write access to the relevant AD groups.
- Must be run as a user account with [read access to the MemberOf property](https://answers.uillinois.edu/48115) of the relevant AD users.

# Usage
1. Download `Remove-AdGroupMemberships.psm1` to `$HOME\Documents\WindowsPowerShell\Modules\Remove-AdGroupMemberships\Remove-AdGroupMemberships.psm1`.
  - The above path is for PowerShell v5.1. For later versions, replace `WindowsPowerShell` with `PowerShell`.
3. Run it using the examples and documentation provided below, including the `-TestRun` switch.
4. Review the output to confirm that the changes match your expectations.
5. Run it again without the `-TestRun` switch.

# Example
It's recommended to capture the output in a variable, like so:
```powershell
$result = Remove-AdGroupMemberships ...
```

### Common usage for EngrIT
```powershell
$result = Remove-AdGroupMemberships -TestRun -InputCsv "c:\input.csv" -OutputCsv ":ENGRIT:" -Log ":ENGRIT:"
```

# Parameters

### -TestRun
Optional switch.  
If specified, the script will skip the step where it actually modifies AD groups. Everything else (i.e. the data gathering, munging, logging, and output) will happen as normal.  

### -ConfirmEach
Optional switch.  
If specified, the script will prompt for confirmation before each individual membership removal.  
If not specified, no prompts will be given.  

### -InputCsv \<string\>
Required string.  
The full path to a properly-formatted CSV file.  
Formatting requirements:  
  - Columns named `User` and `Group` are required (by default). Input column names can be customized using the `-InputUserColumn` and `-InputGroupColumn` parameters.
  - Each row represents a single membership of a user in a group.
  - Cells should just contain the regular name of the user or group.
  - Additional columns may be present and will be ignored.  
  - Columns may be in any order.  

`example-input1.csv` shows an example of the minimum requirements.  
`example-input2.csv` shows an example of the minimum requirements with some extraneous data in columns which will be ignored.  

### -InputUserColumn \<string\>
Optional string.  
The name of the column in the input CSV which contains the user names of the memberships.  
Default is `User`.  

### -InputGroupColumn \<string\>
Optional string.  
The name of the column in the input CSV which contains the group names of the memberships.  
Default is `Group`.  

### -OutputCsv \<string\>
Required string.  
The full path of a file to export results to, in CSV format.  
If `:TS:` is given as part of the string, it will be replaced by a timestamp of when the script was started, with a format specified by `-LogFileTimestampFormat`.  
Specify `:ENGRIT:` to use a default path (i.e. `c:\engrit\logs\Remove-AdGroupMemberships_<timestamp>.csv`).  

### -OutputUserColumn \<string\>
Optional string.  
The name of the column in the output CSV which contains the user names of the memberships.  
Default is `User`.  

### -OutputGroupColumn \<string\>
Optional string.  
The name of the column in the output CSV which contains the group names of the memberships.  
Default is `Group`.  

### -GroupOudn \<string\>
Optional string.  
The distinguished name of the AD OU to limit the search for the given groups. Only groups under this OU will be discovered and modified.  
Default is `OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu`.  

### -VerificationDelaySecs \<int\>
Optional integer.  
The number of seconds to wait after attempting all removals and before attempting verification of removals.  
This ensures that the removals are fully replicated to domain controllers before attempting to verify.  
Default is `5`.  

### -Log \<string\>
Optional string.  
The full path of a file to log to.  
If omitted, no log will be created.  
If `:TS:` is given as part of the string, it will be replaced by a timestamp of when the script was started, with a format specified by `-LogFileTimestampFormat`.  
Specify `:ENGRIT:` to use a default path (i.e. `c:\engrit\logs\Remove-AdGroupMemberships_<timestamp>.log`).  

### -NoConsoleOutput
Optional switch.  
If specified, progress output is not logged to the console.  

### -Indent \<string\>
Optional string.  
The string used as an indent, when indenting log entries.  
Default is four space characters.  

### -LogFileTimestampFormat \<string\>
Optional string.  
The format of the timestamp used in filenames which include `:TS:`.  
Default is `yyyy-MM-dd_HH-mm-ss`.  

### -LogLineTimestampFormat \<string\>
Optional string.  
The format of the timestamp which prepends each log line.  
Default is `[HH:mm:ss]⎵`.  

### -Verbosity \<int\>
Optional integer.  
The level of verbosity to include in output logged to the console and logfile.  
Currently not significantly implemented.  
Default is `0`.  

# Notes
- Developed and tested on PowerShell v7.1. Should work on PowerShell v5.1.
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
