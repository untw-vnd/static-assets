<#
.SYNOPSIS
K-ERP shipping management script

.DESCRIPTION
USAGE
    .\kerp-shipping.ps1 <command>

COMMANDS
    setup             Setup the integration.
    update            Update the integration.
#>
param(
    [Parameter(Position = 0)]
    [ValidateSet("setup", "update")]
    [string]$Command
)

$configFolder = "C:\knights-apparel"
$envFile = "kassistant.env"
$envKeys = "KERP_API_KEY", "FEDEX_ACCOUNT", "FEDEX_CLIENT_ID", "FEDEX_CLIENT_SECRET"

function Sync-ComposeFile {
    try {
        Write-Host "Syncing Compose file"
        Invoke-WebRequest -Uri "https://untw-vnd.github.io/ka-shipping/compose.yaml" -OutFile "$configFolder\compose.yaml"
    }
    catch {
        Write-Error "Failed to sync compose.yaml: $_"
        throw
    }
}

function Sync-Containers {
    try {
        Write-Host "Syncing containers"
        docker compose --file "$configFolder\compose.yaml" up --detach --remove-orphans
    }
    catch {
        Write-Error "Failed to sync containers: $_"
        throw
    }
}

function Remove-OldImages {
    try {
        Write-Host "Removing old images"
        docker image prune --all --force
    }
    catch {
        Write-Error "Failed to remove old images: $_"
        throw
    }
}

function Initialize-Configuration {
    if (Test-Path $configFolder) {
        throw "Config already initialized!"
    }

    New-Item -Path $configFolder -ItemType Directory
    New-Item -Path $configFolder -Name $envFile -ItemType "file"
    foreach ($key in $envKeys) {
        $value = Read-Host -Prompt "Enter the value for $key"
        Add-Content -Path "$configFolder\$envFile" -Value "$key=$value"
    }

    Sync-ComposeFile
    Sync-Containers
}

function Update-Application {
    Sync-ComposeFile
    Sync-Containers
    Remove-OldImages
}

switch ($Command) {
    "setup" {
        Initialize-Configuration
    }
    "update" {
        Update-Application
    }
    default
    {
        Initialize-Configuration
    }
}
