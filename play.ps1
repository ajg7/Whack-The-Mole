$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not (Get-Command ruby -ErrorAction SilentlyContinue) -and (Test-Path 'C:\Ruby33-x64\bin')) {
    $env:Path = "C:\Ruby33-x64\bin;$env:Path"
}
if (-not (Get-Command bundle -ErrorAction SilentlyContinue)) {
    throw 'Ruby is not installed. Get Ruby+Devkit 3.3+ from https://rubyinstaller.org'
}

bundle check *> $null
if ($LASTEXITCODE -ne 0) { bundle install }

bundle exec ruby bin/whack_the_mole
