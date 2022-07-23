
<#

.SYNOPSIS
    A script to install cygwin64 bit in the default directory from scratch and the tools required
    for the pidgin V2 build process.

.DESCRIPTION
    This script will download the cygwin installer and verify it with the file has from the cygwin website.
    It will then launch the installer and automatically select the packages necessary for the windows
    pidgin build setup script (pidgin-windev.sh)

.NOTES
    The following resources were used in developing this script
    # https://github.com/tianon/dockerfiles/blob/master/cygwin/Dockerfile.template
    # https://www.powershellgallery.com/packages/AppVeyorBYOC/1.0.21/Content/scripts%5CWindows%5Cinstall_cygwin.ps1
    # https://www.cygwin.com/faq/faq.html#faq.setup.cli



#>




$folderCygwinBase = "C:\cygwin64\"
$folderCygwinCache = "C:\cygwin64\var\cache\setup"

$fileCygwin64 = "setup-x86_64.exe"
$fileCygwinHash = "sha512.sum"

$cygInstallArgs = ("-R " + $folderCygwinBase), `
"-s https://cygwin.mirror.constant.com", `
("-l " + $folderCygwinCache), `
"-W", `
"-q", `
"-P bsdtar", `
"-P ca-certificates", `
"-P gnupg", `
"-P libiconv", `
"-P make", `
"-P patch", `
"-P unzip", `
"-P wget", `
"-P zip"
                

$hashCygwin64Public = ""
$hashCygwin64Local = ""

[regex]$regParseHash = '(.*)(?=  setup-x86_64.exe)'

$installerVerified = $false


Write-Host "Installing Cygwin x64..." -ForegroundColor Cyan

if(Test-Path $folderCygwinBase) {

    #If folder exists, ask user to continue
    #else cancel script

    Write-Host "Cygwin installation folder already exists."
    Write-Host "Continuing will delete existing folder."
    $confirm = Read-Host "Enter Y to continue: "
 
    if ($confirm.ToUpper() -eq 'Y'){
        Write-Host "Removing Cygwin folder..."
        Remove-Item $folderCygwinBase -Recurse -Force
    } else {
        Write-Host "Canceling installation..."
        Start-Sleep -Seconds 3
        Exit
    }

}

# download installer
New-Item -Path $folderCygwinBase -ItemType Directory -Force

(New-Object Net.WebClient).DownloadFile('https://cygwin.com/setup-x86_64.exe', (Join-Path $folderCygwinBase $fileCygwin64))
(New-Object Net.WebClient).DownloadFile('https://cygwin.com/sha512.sum', (Join-Path $folderCygwinBase $fileCygwinHash))

$hashCygwin64Local = (Get-FileHash (Join-Path $folderCygwinBase $fileCygwin64) -Algorithm SHA512).Hash

$file = [System.IO.File]::OpenText((Join-Path $folderCygwinBase $fileCygwinHash))
while (!$file.EndOfStream){
    $text = $file.ReadLine()
    if ($regParseHash.Matches($text).Success){
        $hashCygwin64Public = $regParseHash.Matches($text).Groups[0].Value.ToUpper()   
        Write-Host "Public Hash: " $hashCygwin64Public
        Write-Host "Local Hash: " $hashCygwin64Local

        if ($hashCygwin64Public -eq $hashCygwin64Local) {
            Write-Host "Cygwin Installer verified"
            $installerVerified = $true
        } else {
            Write-Host "Cygwin Installer Hash missmatch"
        }
    } else {
        Write-Host "Could not find public Cygwin installer hash"
    }
}
$file.Close()

if (!$installerVerified){
    Write-Host "Aborting"
    exit 1
}

Start-Process -FilePath (Join-Path $folderCygwinBase $fileCygwin64) -ArgumentList $cygInstallArgs -Wait

Write-Host "Cygwin installation complete."







