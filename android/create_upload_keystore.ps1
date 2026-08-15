# Creates an Android upload keystore and key.properties for Play Store release builds.
# Run from repo root:  powershell -ExecutionPolicy Bypass -File android/create_upload_keystore.ps1

$ErrorActionPreference = "Stop"
$androidDir = $PSScriptRoot
$keystorePath = Join-Path $androidDir "upload-keystore.jks"
$keyPropsPath = Join-Path $androidDir "key.properties"

if (Test-Path $keystorePath) {
    Write-Host "Keystore already exists at $keystorePath"
    Write-Host "Delete it first if you want to create a new one."
    exit 1
}

Write-Host ""
Write-Host "RizzexAI - Play Store upload keystore setup"
Write-Host "Store these passwords safely. You need them for every release."
Write-Host ""

$storePass = Read-Host "Keystore password" -AsSecureString
$keyPass = Read-Host "Key password (press Enter to reuse keystore password)" -AsSecureString

$storePassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
    [Runtime.InteropServices.Marshal]::SecureStringToBSTR($storePass))

if ($keyPass.Length -eq 0) {
    $keyPassPlain = $storePassPlain
} else {
    $keyPassPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($keyPass))
}

$dname = "CN=RizzexAI, OU=Mobile, O=RizzexAI, L=Unknown, ST=Unknown, C=US"

& keytool -genkey -v `
    -keystore $keystorePath `
    -keyalg RSA `
    -keysize 2048 `
    -validity 10000 `
    -alias upload `
    -storepass $storePassPlain `
    -keypass $keyPassPlain `
    -dname $dname

$lines = @(
    "storePassword=$storePassPlain",
    "keyPassword=$keyPassPlain",
    "keyAlias=upload",
    "storeFile=upload-keystore.jks"
)
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllLines($keyPropsPath, $lines, $utf8NoBom)

Write-Host ""
Write-Host "Created:"
Write-Host "  $keystorePath"
Write-Host "  $keyPropsPath"
Write-Host ""
Write-Host "Next: flutter build appbundle --release"
Write-Host "Upload: build/app/outputs/bundle/release/app-release.aab"
