# Parse the input arguments
function ParseArguments($input_args) {
	$directoryName = $env:appdata + '/Register-WorkTime/'
	$directoryExists = Test-Path $directoryName
    if ($directoryExists -eq $false) {
		New-Item $directoryName -type directory | out-null
	}
	$fileName = $directoryName + 'user.config'
    $evaluationDate = get-date -Format "yyyy-MM-dd"

	if (Test-Path $fileName) {
		$result = Get-Content -Raw -Path $fileName | ConvertFrom-Json
		$result.printHelp = $false;
		$result.debug = $false;
        $result.date = $evaluationDate;
		$result.fileName = $fileName;
	} else {
		$result = New-Object System.Object
		$result | Add-Member -type NoteProperty -name debug -value $false
		$result | Add-Member -type NoteProperty -name printHelp -value $false
        $result | Add-Member -type NoteProperty -name wakatimeApiKey -value $null
        $result | Add-Member -type NoteProperty -name togglApiToken -value $null
        $result | Add-Member -type NoteProperty -name togglWorkspace -value $null
        $result | Add-Member -type NoteProperty -name clockFile -value $null
        $result | Add-Member -type NoteProperty -name date -value $evaluationDate
        $result | Add-Member -type NoteProperty -name fileName -value $fileName
	}

	for ($i = 0; $i -lt $input_args.Length; $i++) {
		# Parse the current and next arguments
		$arg = $input_args[$i]
		$hasNextArg = $i -lt $input_args.Length-1
		$nextArg = $null
		if ($hasNextArg) {
			$nextArg = $input_args[$i+1]
		}

		if ($arg -eq "--debug") {
			$result.debug = $true
		}

		if ($arg -eq "--help" -or $arg -eq "-h") {
			$result.printHelp = $true
		}
		
		if ($arg -eq "--wakatimeApiKey" -or $arg -eq "-w") {
			$result.wakatimeApiKey = "$($nextArg)"
		}

		if ($arg -eq "--togglApiToken" -or $arg -eq "-t") {
			$result.togglApiToken = "$($nextArg)"
		}

		if ($arg -eq "--togglWorkspace" -or $arg -eq "-s") {
			$result.togglWorkspace = "$($nextArg)"
		}

		if ($arg -eq "--clockFile" -or $arg -eq "-c") {
			$result.clockFile = "$($nextArg)"
		}

		if ($arg -eq "--date" -or $arg -eq "-d") {
			$result.date = "$($nextArg)"
		}
	}

	return $result
}

# Check if the arguments used require the help to be printed
function CheckIfMustPrintHelp($printHelp) {
	if ($printHelp) {
		Write-Host ""
		Write-Host "--help `t`t`t -h `t Print usage options"
        Write-Host "--wakatimeApiKey `t`t`t -w `t Inform your wakatime api key"
		Write-Host "--togglApiToken `t`t -t `t Inform your toggl api token"
        Write-Host "--togglWorkspace `t`t -s `t Inform the workspace to save the projects on toggl"
		Write-Host "--clock-file `t`t`t -c `t Inform the path for your time clock excel file"
        Write-Host "--date `t`t`t -d `t Inform the date of evaluation (Default = current day)"
		Write-Host ""
		return $true
	}
	return $false
}

# Check, request and store mandatory parameters
function CheckRequestAndStoreMandatoryParameters($arguments) {
	$updateFile = $false

	# This command must be executed four times in order to the curl alias be successfully removed
	If (Test-Path Alias:curl) {Remove-Item Alias:curl}
	If (Test-Path Alias:curl) {Remove-Item Alias:curl}	
	If (Test-Path Alias:curl) {Remove-Item Alias:curl}	
	If (Test-Path Alias:curl) {Remove-Item Alias:curl}	
	
	$curl = Get-Command "curl" -ErrorAction SilentlyContinue
    if (Test-Path Alias:curl) {
        Write-Host 'You need to remove the curl alias in order to run this script!'
        return $false
    }
    if ($curl -eq $null) {
        Write-Host 'You need to install the real curl utility in order to run this script!'
        return $false
    }

	if ($arguments.wakatimeApiKey -eq $null) {
		Write-Host 'Informe your WakaTime API Key:'
		$arguments.wakatimeApiKey = Read-Host;
		$updateFile = $true;
	}
	if ($arguments.togglApiToken -eq $null) {
		Write-Host 'Informe your Toggl API Token:'
		$arguments.togglApiToken = Read-Host;
		$updateFile = $true;
	}
	if ($arguments.togglWorkspace -eq $null) {
		Write-Host 'Inform the workspace to save the projects on toggl:'
		$arguments.togglWorkspace = Read-Host;
		$updateFile = $true;
	}
	if ($arguments.clockFile -eq $null) {
		Write-Host 'Informe the path for your Time Clock File:'
		$arguments.clockFile = Read-Host;
		$updateFile = $true;
	}
	if ($updateFile) {
		if (Test-Path $arguments.fileName) {
			Remove-Item $arguments.fileName
		}
		New-Item $arguments.fileName -type file
		$arguments | ConvertTo-Json | out-file -filepath $arguments.fileName
	}

	if ($arguments.debug) {
		Write-Host ""
		Write-Host ($arguments | ConvertTo-Json)
		Write-Host ""
	}
	
	return $true
}

function GetWorkTimeEntriesFromWakaTime($arguments) {
	$contentType = 'Content-Type: application/json'
	$baseUri = 'https://wakatime.com/api/v1'
    $evaluationDate = $arguments.date
	$durationsUri = "$baseUri/users/current/durations?date=$evaluationDate&api_key=" + $arguments.wakatimeApiKey
	if ($arguments.debug) {
		Write-Host "baseUri: $baseUri" 
		Write-Host "contentType: $contentType" 
		Write-Host "durationsUri: $durationsUri" 
	}
    $response = curl -k -H $contentType $durationsUri 2> $null
	if ($arguments.debug) {
		Write-Host "response: $response" 
	}
	$durations = $response | ConvertFrom-Json 2> $null
	if ($durations -eq $null) {
		return $null
	}
	if ($arguments.debug) {
		Write-Host "durations: $durations" 
	}
    $durations = $durations | Select-Object -ExpandProperty data
	if ($durations -eq $null) {
		return $null
	}
	if ($arguments.debug) {
		Write-Host "durations: $durations" 
	}
    if ($durations -is [system.array]) {
        $durations = $durations
    }
    else {
        $durations = @($durations)
    }
	if ($arguments.debug) {
		Write-Host "durations: " (ConvertTo-Json $durations) 
	}

    $togglAuth = $arguments.togglApiToken + ":api_token"
    if ($arguments.debug) {
        Write-Host "togglAuth: $togglAuth" 
    }
    $workspacesUri = "https://www.toggl.com/api/v8/workspaces"
    if ($arguments.debug) {
        Write-Host "workspacesUri: $workspacesUri" 
    }
    $response = curl -k -v -u $togglAuth -X GET $workspacesUri 2> $null 
    if ($arguments.debug) {
        Write-Host "response: $response" 
    }
    $workspaces = $response | ConvertFrom-Json 2> $null
    $togglWorkspace = $arguments.togglWorkspace 
    $workspaceId = $workspaces | Where-Object -Property name -eq $togglWorkspace | Select-Object -ExpandProperty id
	if ($arguments.debug) {
		Write-Host "workspaceId: $workspaceId" 
	}

    $projectUri = "https://www.toggl.com/api/v8/workspaces/$workspaceId/projects"
    $response = curl -k -v -u $togglAuth -X GET $projectUri 2> $null
    $projects = $response | ConvertFrom-Json 2> $null
	if ($arguments.debug) {
		Write-Host $projectUri 
		Write-Host "projects: " (ConvertTo-Json $projects)  
	}
    $createProjectUri = "https://www.toggl.com/api/v8/projects"

	if ($arguments.debug) {
		Write-Host "durations.Length: " $durations.Length 
	}

    for ($i = 0; $i -lt $durations.Length; $i++) {
        $duration = $durations[$i]
        $projectName = $duration | Select-Object -ExpandProperty project 
        $project = $projects | Where-Object -Property name -eq $projectName
        if ($project -eq $null) {
           $createProjectPayload = '{\"project\":{\"name\":\"' + $projectName + '\",\"wid\":' + $workspaceId + '}}'
           if ($arguments.debug) {
        	   Write-Host $createProjectUri 
               Write-Host "createProjectPayload: $createProjectPayload" 
           }
           $response = curl -k -v -u $togglAuth -H $contentType -d $createProjectPayload -X POST $createProjectUri 2> $null
           if ($arguments.debug) {
               Write-Host "response: $response" 
           }
           $project = $response | ConvertFrom-Json
        } 

        #TODO: Save task for duration



    }


	if ($arguments.debug) {
		Write-Host "durations: " (ConvertTo-Json $durations) 
	}


	return $durations
}

function GetWorkTimeEntries($arguments) {
	if ($arguments.debug) {
		Set-PSDebug -Trace 1
	}
	# Check if the arguments used require the help to be printed
	$help = CheckIfMustPrintHelp $arguments.printHelp
	if ($help -ne $true) {
		# Check, request and store mandatory parameters
		$validated = CheckRequestAndStoreMandatoryParameters $arguments
		if ($validated -eq $true) {
			# Get the ids of the work items in progress
			$result = GetWorkTimeEntriesFromWakaTime $arguments
			# Return the ids
			return $result
		}
	}
}

function Get-WorkTime() {
	Set-PSDebug -Off
	$arguments = ParseArguments $args
    $entries = GetWorkTimeEntries $arguments
    return $entries
}

function Register-WorkTime() {
	Set-PSDebug -Off
	$arguments = ParseArguments $args
    $entries = GetWorkTimeEntries $arguments
    return $entries
}