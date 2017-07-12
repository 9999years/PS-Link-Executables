function Get-PotentialExecutables {
	[CmdletBinding()]
	Param(
		# Director(ies) to search executables for
		# Defaults to $PATH, excluding system32
		[Parameter(
			ValueFromPipeline=$True,
			Mandatory=$True
		)]
		[String[]]$Directories,
		[Switch]$DLLs
	)

	Begin {
		$extensions = $env:PATHEXT.split(";") | %{
			"*$_"
		}
		If($DLLs) {
			$extensions += "*.dll"
		}
	}

	Process {
		ForEach($todir in $Directories) {
			return Get-ChildItem "$todir\*" -Include $extensions
		}
	}
}

function Regenerate-Links {
	[CmdletBinding()]
	Param(
		[Parameter(
			HelpMessage="The path of a text file containing one directory of executables to link per line",
			Mandatory=$True)]
		[String]$BinDirectories
	)

	# ensure shimgen works
	$helpersPath = "$($env:ChocolateyInstall)\helpers"
	If(Test-Path $helpersPath) {
		# https://github.com/chocolatey/choco/blob/stable/src/chocolatey.resources/helpers/chocolateyInstaller.psm1#L40
		Get-Item "$helpersPath\functions\*.ps1" |
			? { -not ($_.Name.Contains(".Tests.")) } |
				ForEach-Object {
					. $_.FullName
				}
	} Else {
		Write-Error 'Chocolatey helper functions not found!'
	}

	$paths = (cat $BinDirectories)
	ForEach($loc in $paths) {
		$exes = Get-PotentialExecutables $loc
		ForEach($exe in $exes) {
			# make name like
			# executable.exe => executable
			# IF it has a dot
			# split-path for
			# full path => file name
			$name = Split-Path $exe -Leaf
			$last_dot = $name.LastIndexOf(".")
			If($last_dot -ne -1) {
				$name = $name.Substring(0, $last_dot)
			}
			Install-BinFile -Name $name -Path $exe
		}
	}
}
