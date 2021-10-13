# Documentation home: https://github.com/engrit-illinois/Remove-AdUsersFromGroups
# By mseng3

function Remove-AdGroupMemberships {
	
	param(
		[Parameter(Mandatory=$true)]
		[string]$InputCsv,
		
		[Parameter(Mandatory=$true)]
		[string]$OutputCsv,
		
		[switch]$TestRun,
		
		[string]$GroupOudn = "OU=Engineering,OU=Urbana,DC=ad,DC=uillinois,DC=edu",
		
		# ":ENGRIT:" will be replaced with "c:\engrit\logs\$($MODULE_NAME)_:TS:.log"
		# ":TS:" will be replaced with start timestamp
		[string]$Log,

		[switch]$NoConsoleOutput,
		[string]$Indent = "    ",
		[string]$LogFileTimestampFormat = "yyyy-MM-dd_HH-mm-ss",
		[string]$LogLineTimestampFormat = "[HH:mm:ss] ", # Minimal timestamp
		[int]$Verbosity = 0
	)

	# Logic to determine final filenames
	$MODULE_NAME = "Remove-AdGroupMemberships"
	$ENGRIT_LOG_DIR = "c:\engrit\logs"
	$ENGRIT_LOG_FILENAME = "$($MODULE_NAME)_:TS:"
	$START_TIMESTAMP = Get-Date -Format $LogFileTimestampFormat

	if($Log) {
		$Log = $Log.Replace(":ENGRIT:","$($ENGRIT_LOG_DIR)\$($ENGRIT_LOG_FILENAME).log")
		$Log = $Log.Replace(":TS:",$START_TIMESTAMP)
	}
	if($OutputCsv) {
		$OutputCsv = $OutputCsv.Replace(":ENGRIT:","$($ENGRIT_LOG_DIR)\$($ENGRIT_LOG_FILENAME)_output.csv")
		$OutputCsv = $OutputCsv.Replace(":TS:",$START_TIMESTAMP)
	}

	function log {
		param (
			[Parameter(Position=0)]
			[string]$Msg = "",

			[int]$L = 0, # level of indentation
			[int]$V = 0, # verbosity level

			[ValidateScript({[System.Enum]::GetValues([System.ConsoleColor]) -contains $_})]
			[string]$FC = (get-host).ui.rawui.ForegroundColor, # foreground color
			[ValidateScript({[System.Enum]::GetValues([System.ConsoleColor]) -contains $_})]
			[string]$BC = (get-host).ui.rawui.BackgroundColor, # background color

			[switch]$E, # error
			[switch]$NoTS, # omit timestamp
			[switch]$NoNL, # omit newline after output
			[switch]$NoConsole, # skip outputting to console
			[switch]$NoLog # skip logging to file
		)

		if($E) { $FC = "Red" }

		# Custom indent per message, good for making output much more readable
		for($i = 0; $i -lt $L; $i += 1) {
			$Msg = "$Indent$Msg"
		}

		# Add timestamp to each message
		# $NoTS parameter useful for making things like tables look cleaner
		if(!$NoTS) {
			if($LogLineTimestampFormat) {
				$ts = Get-Date -Format $LogLineTimestampFormat
			}
			$Msg = "$ts$Msg"
		}

		# Each message can be given a custom verbosity ($V), and so can be displayed or ignored depending on $Verbosity
		# Check if this particular message is too verbose for the given $Verbosity level
		if($V -le $Verbosity) {

			# Check if this particular message is supposed to be logged
			if(!$NoLog) {

				# Check if we're allowing logging
				if($Log) {

					# Check that the logfile already exists, and if not, then create it (and the full directory path that should contain it)
					if(-not (Test-Path -PathType "Leaf" -Path $Log)) {
						New-Item -ItemType "File" -Force -Path $Log | Out-Null
						log "Logging to `"$Log`"."
					}

					if($NoNL) {
						$Msg | Out-File $Log -Append -NoNewline
					}
					else {
						$Msg | Out-File $Log -Append
					}
				}
			}

			# Check if this particular message is supposed to be output to console
			if(!$NoConsole) {

				# Check if we're allowing console output
				if(!$NoConsoleOutput) {

					if($NoNL) {
						Write-Host $Msg -NoNewline -ForegroundColor $FC -BackgroundColor $BC
					}
					else {
						Write-Host $Msg -ForegroundColor $FC -BackgroundColor $BC
					}
				}
			}
		}
	}
	
	function Log-Error($e, $L=0) {
		$msg = $e.Exception.Message
		$inv = ($e.InvocationInfo.PositionMessage -split "`n")[0]
		log $msg -L $l -E
		log $inv -L ($L + 1) -E
	}
	
	function Log-Object {
		param(
			[PSObject]$Object,
			[string]$Format = "Table",
			[int]$L = 0,
			[int]$V = 0,
			[switch]$NoTs,
			[switch]$E
		)
		if(!$NoTs) { $NoTs = $false }
		if(!$E) { $E = $false }

		switch($Format) {
			"List" { $string = ($object | Format-List | Out-String) }
			#Default { $string = ($object | Format-Table | Out-String) }
			Default { $string = ($object | Format-Table -AutoSize | Out-String) }
		}
		$string = $string.Trim()
		$lines = $string -split "`n"

		$params = @{
			L = $L
			V = $V
			NoTs = $NoTs
			E = $E
		}

		foreach($line in $lines) {
			$params["Msg"] = $line
			log @params
		}
	}
	
	# Handy utility function to reliably count members of an array that might be empty
	# Because of Powershell's weird way of handling arrays containing null values
	# i.e. null values in arrays still count as items in the array
	function count($array) {
		$count = 0
		if($array) {
			# If we didn't check $array in the above if statement, this would return 1 if $array was $null
			# i.e. @().count = 0, @($null).count = 1
			$count = @($array).count
			# We can't simply do $array.count, because if it's null, that would throw an error due to trying to access a method on a null object
		}
		$count
	}
	
	# Shorthand for an annoying common line to add new members to objects
	function addm($property, $value, $object, $adObject = $false) {
		if($adObject) {
			# This gets me EVERY FLIPPIN TIME:
			# https://stackoverflow.com/questions/32919541/why-does-add-member-think-every-possible-property-already-exists-on-a-microsoft
			$object | Add-Member -NotePropertyName $property -NotePropertyValue $value -Force
		}
		else {
			$object | Add-Member -NotePropertyName $property -NotePropertyValue $value
		}
		$object
	}

	function Quit {
		param(
			[string]$Msg,
			[System.Management.Automation.ErrorRecord]$E = $null
		)
		
		if($E) { Log-Error $E }
		
		if(!$Msg) { $Msg = "Quitting. No message given." }
		Throw $Msg
	}
	
	function Log-Inputs {
		log "Inputs:"
		log "Input CSV: `"$InputCsv`"." -L 1
		log "Output CSV: `"$OutputCsv`"." -L 1
		log "OUDN: `"$OUDN`"." -L 1
		log "Log: `"$Log`"." -L 1
	}
	
	function Import-Memberships {
		
		# make sure given input CSV exists
		if(-not (Test-Path -PathType "Leaf" -Path $InputCsv)) {
			Quit "Could not find input CSV `"$InputCsv`"!"
		}
		
		# Import CSV data
		$memberships = Import-Csv -Path $InputCsv
		if(-not $memberships) {
			Quit "No data found in input CSV `"$InputCsv`"!"
		}
		
		# Log CSV data
		$membershipsCount = count $memberships
		log "Found $membershipsCount users in input CSV:"
		Log-Object $memberships -L 1
		
		# Filter and sort data
		log "Filtering to only group and user columns, and sorting by group and then user:"
		$memberships = $memberships | Select Group,User | Sort Group,User
		Log-Object $memberships -L 1
		
		$memberships
	}
	
	# Takes a user or group name and returns the DN of the object if it exists
	# If object is not found in AD (in the given $OUDN), returns an error string to use as the value instead
	function Validate-AdObject($name, $type) {
		
		switch($type) {
			"User" {
				$result = Get-ADUser -Filter { Name -eq $name }
			}
			"Group" {
				$result = Get-ADGroup -Filter { Name -eq $name } -SearchBase $GroupOudn
			}
			"default" {
				Quit "Invalid type `"$type`", sent to Validate-AdObject function!"
			}
		}
		
		if($result) {
			$dn = $result.DistinguishedName
			log "$Type exists. DN: `"$dn`"." -L 2
		}
		else {
			log "$Type not found in AD!" -L 2
		}
		
		$result
	}
	
	function Validate-Membership($membership) {
		$valid = $false
		
		if($membership.AdObjectsExist) {
			$groupMemberDns = Get-ADGroupMember -Identity $membership.GroupObject.DistinguishedName | Select -ExpandProperty DistinguishedName
			
			if($groupMemberDns -contains $membership.UserObject.DistinguishedName) {
				log "Membership exists." -L 2
				$valid = $true
			}
			else {
				log "Membership does not exist!" -L 2
			}
		}
		else {
			log "User and/or group does not exist!" -L 2
		}
		
		$valid
	}
	
	function Validate-Memberships($memberships) {
		
		log "Validating AD objects and memberships..."
		
		$memberships = $memberships | ForEach {
			$membership = $_
			
			$userName = $membership.user
			$groupName = $membership.group
			log "Validating membership of user `"$userName`" in group `"$groupName`"..." -L 1
			
			# Test that user exists
			$userObject = Validate-AdObject $userName "User"
			$membership = addm "UserObject" $userObject $membership
			
			# Test that group exists
			$groupObject = Validate-AdObject $groupName "Group"
			$membership = addm "GroupObject" $groupObject $membership
			
			# Record whether both AD objects exist
			$adObjectsExist = $false
			if(
				($membership.UserObject) -and
				($membership.GroupObject)
			) {
				$adObjectsExist = $true
			}
			$membership = addm "AdObjectsExist" $adObjectsExist $membership
			
			# Test that membership exists
			$membershipExists = Validate-Membership $membership
			$membership = addm "MembershipExists" $membershipExists $membership
			
			$membership
		}
		
		$memberships
	}
	
	function Remove-Memberships($memberships) {
		
		log "Removing memberships..."
		
		$memberships = $memberships | ForEach {
			$membership = $_
			$result = "unknown"
			
			log "Removing membership of user `"$($membership.User)`" in group `"$($membership.Group)`"..." -L 1
			
			# Make sure membership is valid
			if(-not $membership.MembershipExists) {
				$result = "Membership does not exist."
			}
			else {
				if($TestRun) {
					# Space before "-TestRun" is included to prevent Excel from infuriatingly interpreting the string as a forumla
					$result = " -TestRun was specified. Skipping removal."
				}
				else {
					# Remove membership
					Remove-AdGroupMember -Identity $membership.GroupObject.DistinguishedName -Members $membership.UserObject.DistinguishedName
					
					# Check that membership was removed
					if(Validate-Membership $membership) {
						$result = "Failed to remove membership!"
					}
					else {
						$result = "Successfully removed membership."
					}
				}
			}
			
			log $result -L 2
			$membership = addm "Result" $result $membership
			
			$membership
		}
		
		$memberships
	}
	
	function Print-Results($memberships) {
		log "Results:"
		Log-Object ($memberships | Select Group,User,Result) -L 1
	}
	
	function Export-Results($memberships) {
		log "Exporting results to CSV `"$OutputCsv`"..."
		$memberships | Export-Csv -NoTypeInformation -Encoding "Ascii" -Path $OutputCsv
	}
	
	function Do-Stuff {
		Log-Inputs
		$memberships = Import-Memberships
		$memberships = Validate-Memberships $memberships
		$memberships = Remove-Memberships $memberships
		Print-Results $memberships
		Export-Results $memberships
		$memberships
	}
	
	Do-Stuff
	
	log "EOF"
}