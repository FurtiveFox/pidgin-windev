# Resources:
# https://github.com/tianon/dockerfiles/blob/master/cygwin/Dockerfile.template
# https://www.powershellgallery.com/packages/AppVeyorBYOC/1.0.21/Content/scripts%5CWindows%5Cinstall_cygwin.ps1
# https://www.cygwin.com/faq/faq.html#faq.setup.cli


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
    Write-Host "Deleting existing installation..."
    Remove-Item $folderCygwinBase -Recurse -Force
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

Start-Process -FilePath (Join-Path $folderCygwinBase $fileCygwin64) -ArgumentList $cygInstallArgs




