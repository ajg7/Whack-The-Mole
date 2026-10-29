$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
if (-not (Get-Command ruby -ErrorAction SilentlyContinue)) { $env:PATH = "C:\Ruby34-x64\bin;$env:PATH" }
bundle check *> $null
if ($LASTEXITCODE -ne 0) { bundle install }
bundle exec ruby bin/whack_the_mole
