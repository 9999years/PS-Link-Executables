function Create-ExecutableLink {
	[CmdletBinding()]
	Param(
		# Where to point the link (an executable)
		[Parameter(
			ValueFromPipeline=$True,
			Mandatory=$True
		)]
		[String]$To,
		# Where to create the link (a directory)
		[String]$From = ".\",
		[Switch]$CD,
		[Switch]$SymbolicLink
	)

	Process {
		$To = Resolve-Path $To
		# dest. exe name with no path
		$exe = Split-Path -Leaf $To
		# remove extension (.exe, .bat, etc)
		$exe = $exe.Substring(0, $exe.LastIndexOf("."))

		If($SymbolicLink) {
			New-Item -ItemType SymbolicLink `
				-Force -Path $From `
				-Name (Split-Path -Leaf $To) `
				-Value $To |
			Out-Null
			return
		}

		$bat = ""

		If($CD) {
			$bat = "@cd `"$(
				Split-Path -Parent $To
			)`"`n"
		}
		
		$bat += "@`"$To`" %*"

		[IO.File]::WriteAllLines(
			$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$From\$exe.bat"),
			$bat,
			(New-Object System.Text.UTF8Encoding $False)
		)
	}
}

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

function Link-Executables {
	[CmdletBinding()]
	Param(
		# Director(ies) to search executables for
		# Defaults to $PATH, excluding system32
		[Parameter(
			ValueFromPipeline=$True,
			Mandatory=$True
		)]
		[String[]]$To,
		# Where to create the links (a directory)
		[String]$From = ".\",
		[Switch]$DLLs,
		[Switch]$CD,
		[Switch]$BATs
	)

	Begin {
		$From = Resolve-Path $From
		$Arguments = @{
			From = $From;
			CD = $CD;
			SymbolicLink = !$BATs;
		}
		Write-Output "Linking executables to $From"
	}

	Process {
		ForEach($todir in $To) {
			$todir = Resolve-Path $todir
			Write-Output "Linking executables in $todir"
			Get-PotentialExecutables $todir -DLLs:$DLLs |
				Create-ExecutableLink @Arguments
		}
	}
}
