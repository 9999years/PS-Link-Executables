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
		[Switch]$CD
	)

	Process {
		$To = Resolve-Path $To
		# dest. exe name with no path
		$exe = Split-Path -Leaf $To
		# remove extension (.exe, .bat, etc)
		$exe = $exe.Substring(0, $exe.LastIndexOf("."))

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
		[Switch]$CD
	)

	Begin {
		$From = Resolve-Path $From
		$extensions = $env:PATHEXT.split(";") | %{
			"*$_"
		}
		$Arguments = @{
			From = $From;
			CD = $CD
		}
		Write-Output "Linking executables to $From"
	}

	Process {
		ForEach($todir in $To) {
			$todir = Resolve-Path $todir
			Write-Output "Linking executables in $todir"
			(Get-ChildItem "$todir\*" `
				-Include $extensions) |
			Create-ExecutableLink @Arguments

			If($DLLs) {
				# we need admin...
				(Get-ChildItem "$todir\*" `
					-Include *.dll) | %{
					New-Item -ItemType SymbolicLink `
					-Path $From `
					-Name (Split-Path -Leaf $_) `
					-Value $_ `
					-ErrorAction SilentlyContinue
				} | Out-Null
			}
		}
	}
}
