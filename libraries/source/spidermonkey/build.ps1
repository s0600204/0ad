
$MOZBUILD_VERSION   = '3.3'
$MOZBUILD_EXE       = "MozillaBuildSetup-$MOZBUILD_VERSION.exe"
$MOZBUILD_URL       = "https://ftp.mozilla.org/pub/mozilla/libraries/win32/$MOZBUILD_EXE"
$MOZBUILD_DIRECTORY = 'mozilla-build'

$LLVM_VERSION       = '12.0.0'
$LLVM_EXE_64        = "LLVM-$LLVM_VERSION-win64.exe"
$LLVM_EXE_32        = "LLVM-$LLVM_VERSION-win32.exe"
$LLVM_URL           = "https://github.com/llvm/llvm-project/releases/download/llvmorg-$LLVM_VERSION/"
$LLVM_DIRECTORY     = 'llvm'

<#
Converts a Windows-style path ("C:\path\to\somewhere")
to a Unix-style path ("/c/path/to/somewhere").

There's probably a better way of doing this.
#>
function Convert-PathToUnix ($Path) {
  $SplitPath = (Resolve-Path $Path) -split ':'
  $SplitPath[0] =  $SplitPath[0].ToLower()
  $SplitPath[1] = ($SplitPath[1] -split '\\') -join '/'
  return '/' + ($SplitPath -join '')
}

Write-Output ""
Write-Output "Building SpiderMonkey"
Write-Output "======================================="
Push-Location $PSScriptRoot

Write-Output ""
Write-Output "Install Mozilla Build ($MOZBUILD_VERSION)"
Write-Output "---------------------------------------"
<#
The general idea when building pyrogenesis (and its dependencies) is that the process shouldn't
alter the host/build system. That is to say: everything should be handled within the build
folders, and the build process shouldn't install software globally.

(The user may decide to install the end result (0 A.D.) globally, but that's their choice.)

With Mozilla Build this is a little difficult: when running in "silent" (e.g. unattended mode),
it ignores the standard `/D=<path>` cli instruction that the NSIS-based installer should have
(as can be seen from the source https://hg.mozilla.org/mozilla-build/file/tip/installit.nsi).

As such, we let it install itself globally, then relocate the contents locally. As the installer
doesn't modify the Windows registry, this should be alright.

------------------------------------------------------------------------------------------------

An alternate approach would be to uncompress mozbuild.exe (as you might an archive - the
contents are stored using the LZMA algorithm).

The "recommended" way to do this would be with 7zip. And this does indeed work - when run by a
user on a system with 7zip installed. Doing it via the command line on system that doesn't have
7zip preinstalled is trickier.

A little research, and it looks like we would need two things: 7z.exe and 7z.dll.

So where to get these? Well:

* Use precompiled binaries from the official 7zip site
  - The binaries come within installers that make modifications to the build system's registry.
    Kinda goes against the whole "don't make modifications to the host" aim.

* Acquire the Source from the official 7zip site and build it ourselves
  - The code repository doesn't appear to be publically accessible.
  - An archive containing the source code *is* available - however it is in the .7z format,
    meaning we'd need to use 7zip to extract the source to build 7zip.

* Use 7zip portable from portableapps.com
  - The installer refuses to run in "unattended" mode, so is unsuitable for CLI usage.

* Install from chocolately
  - Installs 7zip globally. Again, we don't want to modify the host system.
  - Also requires chocolately to be preinstalled on the host system.

* Acquire from a nuget on nupkg
  - All nugets currently available either provide a limited-version of 7zip (7za.exe) that can't
    handle nsis archives, or just the 7z.dll file.

* Use `7Zip4Powershell` PowerShell module
  - Uses a C# wrapper around a limited version of 7zip which can't handle nsis archives

* Install from vcpkg
  - Builds 7z.dll, but not 7z.exe.

I suppose the answer is to either require the host to have 7zip installed, or to use a limited
version to uncompress the source and build a full version ourselves.
#>
Get-FileFromUrl -FileName $MOZBUILD_EXE -Url $MOZBUILD_URL

$MozBuildGlobalDir = "C:\$MOZBUILD_DIRECTORY"
$MozBuildTempDir = "C:\$MOZBUILD_DIRECTORY-temp"

$NameCollision = Test-Path $MozBuildGlobalDir
if ($NameCollision) {
  # If there's something already there, move it temporarily out the way
  Move-Item -Path $MozBuildGlobalDir -Destination $MozBuildTempDir
}

try {
  Write-Output "-- Installing"
  Start-Process -FilePath .\$MOZBUILD_EXE -ArgumentList "/S" -Wait -NoNewWindow
  Move-Item -Path $MozBuildGlobalDir -Destination .
}
catch {
  Remove-Item -Path $MozBuildGlobalDir -Recurse
  throw
}
finally {
  if ($NameCollision) {
    # Restore whatever was there previously
    Move-Item -Path $MozBuildTempDir -Destination $MozBuildGlobalDir
  }
}


#~ Write-Output ""
#~ Write-Output "Install LLVM ($LLVM_VERSION)"
#~ Write-Output "---------------------------------------"
#~ New-Item -Path . -Name $LLVM_DIRECTORY -ItemType Directory | Out-Null
#~ switch ([intptr]::Size)
#~ {
  #~ 4 { $LLVM_EXE = $LLVM_EXE_32 } # x86 system
  #~ 8 { $LLVM_EXE = $LLVM_EXE_64 } # x86_64 system
#~ }
#~ Get-FileFromUrl -FileName $LLVM_EXE -Url $LLVM_URL$LLVM_EXE
#~ Write-Output "-- Installing"
#~ Start-Process -FilePath .\$LLVM_EXE -ArgumentList "/S","/D=$PSScriptRoot\$LLVM_DIRECTORY" -Wait -NoNewWindow


#~ Write-Output ""
#~ Write-Output "Install & setup rust toolchains"
#~ Write-Output "---------------------------------------"
#~ # Note: These install to the user's directory (~\.rustup\toolchains)
#~ switch ([intptr]::Size)
#~ {
  #~ 4 { # x86 system
    #~ Write-Output "-- Installing stable-i686-pc-windows-msvc"
    #~ rustup toolchain install stable-i686-pc-windows-msvc
  #~ }

  #~ 8 { # x86_64 system
    #~ Write-Output "-- Installing stable-x86_64-pc-windows-msvc"
    #~ rustup toolchain install stable-x86_64-pc-windows-msvc
    #~ Write-Output "-- Adding i686-pc-windows-msvc as a target"
    #~ rustup target add i686-pc-windows-msvc
  #~ }
#~ }


Write-Output ""
Write-Output "Build SpiderMonkey"
Write-Output "---------------------------------------"
$CurrentUnixPath = Convert-PathToUnix .
#~ $LLVMUnixPath = Convert-PathToUnix $LLVM_DIRECTORY\bin
Start-Process cmd.exe `
  -NoNewWindow `
  -Wait `
  -ArgumentList `
    '/c', `
    ".\$MOZBUILD_DIRECTORY\start-shell.bat", `
    "cd $CurrentUnixPath; PATH=${LLVMUnixPath}:`$PATH; env"


Write-Output ""
Write-Output "Look at build artifacts"
Write-Output "---------------------------------------"
# List current directory items
(Get-ChildItem -Path .).FullName
echo ""
# List specific directory items, recursively
(Get-ChildItem -Path .\include -Recurse).FullName
echo ""
(Get-ChildItem -Path .\lib -Recurse).FullName
echo ""
(Get-ChildItem -Path '.\mozjs-78.6.0\build-release\dist\bin' -Recurse).FullName
echo ""
Get-Content -Path .\lib\pkgconfig\mozjs78-ps-debug.pc
echo ""
Get-Content -Path .\lib\pkgconfig\mozjs78-ps-release.pc

Write-Output ""
Write-Output "Export build artifacts"
Write-Output "---------------------------------------"
Merge-ChildItems -Path lib     -Include *.dll, *.pdb -Destination $env:INSTALL_DIR\bin
Merge-ChildItems -Path include -Include *.h          -Destination $env:INSTALL_DIR\include
Merge-ChildItems -Path lib     -Include *.lib, *.pc  -Destination $env:INSTALL_DIR\lib
Write-Output "Done."


Pop-Location
