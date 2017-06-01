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
		[String]$From = ".\"
	)

	Process {
		$To = Resolve-Path $To
		# dest. exe name with no path
		$exe = Split-Path -Leaf $To
		# remove extension (.exe, .bat, etc)
		$exe = $exe.Substring(0, $exe.LastIndexOf("."))

		[IO.File]::WriteAllLines(
			$ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("$From\$exe.bat"),
			"@cd `"$(
				Split-Path -Parent $To
			)`"`n@`"$To`" %*",
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
		[String]$From = ".\"
	)

	Begin {
		$From = Resolve-Path $From
		$extensions = $env:PATHEXT.split(";") | %{
			"*$_"
		}
		Write-Output "Linking executables to $From"
	}

	Process {
		ForEach($todir in $To) {
			$todir = Resolve-Path $todir
			Write-Output "Linking executables in $todir"
			(Get-ChildItem "$todir\*" `
				-Include $extensions) |
			Create-ExecutableLink -From $From
		}
	}
}
