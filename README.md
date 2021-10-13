# THIS SCRIPT IS A WORK IN PROGRESS

# Summary
A script to remove AD users from AD groups, based on a given memberships.  

# Behavior
Accepts a CSV file with one row for each user-in-group membership which should be removed. Checks that all objects are valid and performs the membership removals.  

# Requirements
- Requires RSAT to be installed.
- Must be run as a user account with permissions to modify the relevant AD groups.
- Developed and tested on PowerShell v7.1.

# Usage
1. Download `Remove-AdGroupMemberships.psm1` to `$HOME\Documents\WindowsPowerShell\Modules\Remove-AdGroupMemberships\Remove-AdGroupMemberships.psm1`.
2. Run it using the examples and documentation provided below, including the `-TestRun` switch.
3. Review the output to confirm that the changes match your expectations.
4. Run it again without the `-TestRun` switch.

# Example
It's recommended to capture the output in a variable, like so:
```powershell
$result = Remove-AdGroupMemberships -TestRun -InputCsv "c:\input.csv" -OutputCsv "c:\output.csv"
```

### Common usage for EngrIT
```powershell
$result = Remove-AdGroupMemberships -TestRun -InputCsv "c:\input.csv" -OutputCsv ":ENGRIT:" -Log ":ENGRIT:"
```

# Parameters

### -TestRun
Optional switch.  
If specified, the script will skip the step where it actually modifies AD groups. Everything else (i.e. the data gathering, munging, logging, and output) will happen as normal.  

### -InputCsv \<string\>
Required string.  
The full path to a properly-formatted CSV file. See `example-input.csv`.  
Columns named `Users` and `Groups` are required.  
Additional columns may be present and will be ignored.  
Columns may be in any order.  

### -OutputCsv \<string\>
Required string.  
The full path of a file to export results to, in CSV format.  
If `:TS:` is given as part of the string, it will be replaced by a timestamp of when the script was started, with a format specified by `-LogFileTimestampFormat`.  
Specify `:ENGRIT:` to use a default path (i.e. `c:\engrit\logs\Remove-AdGroupMemberships_<timestamp>.csv`).  

### -OUDN \<string\>
Optional string.  
The distinguished name of the AD OU to limit the search for the given groups. Only groups under this OU will be discovered and modified.  
Default is `OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu`.  

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
- By mseng3. See my other projects here: https://github.com/mmseng/code-compendium.
