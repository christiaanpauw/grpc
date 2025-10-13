[CmdletBinding()]
param(
    [string]$RtoolsPrefix = "C:\\rtools43",
    [switch]$ShowPaths
)

function Write-Heading {
    param([string]$Title)
    Write-Host "`n=== $Title ===" -ForegroundColor Cyan
}

function Resolve-ExistingPath {
    param([string[]]$Candidates)
    foreach ($candidate in $Candidates) {
        if (-not [string]::IsNullOrWhiteSpace($candidate) -and (Test-Path $candidate)) {
            return (Resolve-Path $candidate).Path
        }
    }
    return $null
}

function Invoke-Tool {
    param(
        [string]$Executable,
        [string[]]$Arguments
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Executable
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $Arguments | ForEach-Object { [void]$psi.ArgumentList.Add($_) }

    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi

    $stdout = ""
    $stderr = ""
    $exitCode = -1

    try {
        if ($proc.Start()) {
            $stdout = $proc.StandardOutput.ReadToEnd().Trim()
            $stderr = $proc.StandardError.ReadToEnd().Trim()
            $proc.WaitForExit()
            $exitCode = $proc.ExitCode
        }
    } catch {
        $stderr = $_.Exception.Message
    }

    return [PSCustomObject]@{
        ExitCode = $exitCode
        StdOut   = $stdout
        StdErr   = $stderr
    }
}

Write-Heading "Environment summary"
Write-Host ("Operating system : {0}" -f [System.Environment]::OSVersion.VersionString)
Write-Host ("64-bit OS       : {0}" -f [Environment]::Is64BitOperatingSystem)
Write-Host ("Rtools prefix   : {0}" -f $RtoolsPrefix)
Write-Host ("PKG_CONFIG_PATH : {0}" -f ($env:PKG_CONFIG_PATH ?? "<not set>"))

$pkgConfigCandidates = @(
    (Join-Path $RtoolsPrefix "ucrt64/bin/pkg-config.exe"),
    (Join-Path $RtoolsPrefix "ucrt64/bin/pkgconf.exe"),
    "pkg-config.exe",
    "pkgconf.exe"
)
$pkgConfigPath = Resolve-ExistingPath -Candidates $pkgConfigCandidates

$moduleResults = @{}

if (-not $pkgConfigPath) {
    Write-Heading "pkg-config lookup"
    Write-Warning "Unable to locate pkg-config. Install the mingw-w64-ucrt-x86_64-pkgconf package from the Rtools/MSYS2 environment."
} else {
    Write-Heading "pkg-config lookup"
    Write-Host ("Using pkg-config executable: {0}" -f $pkgConfigPath)
    if ($ShowPaths) {
        $pcPath = Invoke-Tool -Executable $pkgConfigPath -Arguments @("--variable", "pc_path", "pkg-config")
        if ($pcPath.ExitCode -eq 0) {
            Write-Host ("pkg-config search path : {0}" -f $pcPath.StdOut)
        }
    }

    foreach ($module in @("grpc", "protobuf", "gpr")) {
        Write-Heading ("Inspecting module '{0}'" -f $module)
        $moduleResults[$module] = -1

        $version = Invoke-Tool -Executable $pkgConfigPath -Arguments @("--modversion", $module)
        if ($version.ExitCode -ne 0) {
            Write-Warning ("pkg-config could not resolve '{0}'. Ensure the library is installed and the PKG_CONFIG_PATH includes its .pc file." -f $module)
            if (-not [string]::IsNullOrWhiteSpace($version.StdErr)) {
                Write-Host $version.StdErr
            }
            continue
        }
        $moduleResults[$module] = 0
        Write-Host ("Version : {0}" -f $version.StdOut)

        $cflags = Invoke-Tool -Executable $pkgConfigPath -Arguments @("--cflags", $module)
        if ($cflags.ExitCode -eq 0) {
            Write-Host ("CFLAGS  : {0}" -f ($cflags.StdOut -replace "\s+", " "))
        }

        $libs = Invoke-Tool -Executable $pkgConfigPath -Arguments @("--libs", $module)
        if ($libs.ExitCode -eq 0) {
            Write-Host ("LIBS    : {0}" -f ($libs.StdOut -replace "\s+", " "))
        }

        if ($ShowPaths) {
            $libdir = Invoke-Tool -Executable $pkgConfigPath -Arguments @("--variable", "libdir", $module)
            if ($libdir.ExitCode -eq 0) {
                Write-Host ("Library directory : {0}" -f $libdir.StdOut)
            }
        }
    }
}

$gccPath = Resolve-ExistingPath -Candidates @(
    (Join-Path $RtoolsPrefix "ucrt64/bin/gcc.exe"),
    (Join-Path $RtoolsPrefix "mingw64/bin/gcc.exe"),
    "gcc.exe"
)

Write-Heading "Toolchain"
if (-not $gccPath) {
    Write-Warning "Unable to locate gcc. Confirm that Rtools is installed and that you are running inside the Rtools UCRT64 shell."
} else {
    Write-Host ("Using gcc executable: {0}" -f $gccPath)
    $triplet = Invoke-Tool -Executable $gccPath -Arguments @("-dumpmachine")
    if ($triplet.ExitCode -eq 0) {
        Write-Host ("Target triple: {0}" -f $triplet.StdOut)
    }
}

Write-Heading "Actionable findings"
if (-not $pkgConfigPath) {
    Write-Host "- Install pkgconf in the Rtools UCRT64 environment (pacman -S mingw-w64-ucrt-x86_64-pkgconf)."
}

$missingModules = $moduleResults.GetEnumerator() | Where-Object { $_.Value -ne 0 }
if ($missingModules) {
    Write-Host "- Install the following libraries inside the Rtools UCRT64 shell:"
    foreach ($module in $missingModules) {
        switch ($module.Key) {
            "grpc" { Write-Host "    pacman -S mingw-w64-ucrt-x86_64-grpc" }
            "protobuf" { Write-Host "    pacman -S mingw-w64-ucrt-x86_64-protobuf" }
            "gpr" { Write-Host "    pacman -S mingw-w64-ucrt-x86_64-grpc" }
            default { Write-Host ("    {0}" -f $module.Key) }
        }
    }
}

if (-not $gccPath) {
    Write-Host "- Install Rtools 4.3 or newer and launch the UCRT64 shell before building the package."
}

Write-Host "- Re-run this script after installing missing components to verify the configuration."
