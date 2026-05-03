#Requires -RunAsAdministrator
$ErrorActionPreference = 'Stop'

Write-Host "Setting OLLAMA_HOST=0.0.0.0:11434 (User scope)"
[Environment]::SetEnvironmentVariable('OLLAMA_HOST', '0.0.0.0:11434', 'User')

Write-Host "Setting OLLAMA_ORIGINS=* (User scope)"
[Environment]::SetEnvironmentVariable('OLLAMA_ORIGINS', '*', 'User')

$ruleName = 'Ollama (WSL)'
$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Firewall rule '$ruleName' already exists; leaving as-is"
} else {
    Write-Host "Adding firewall rule '$ruleName' (TCP 11434 inbound, Private/Domain profiles)"
    New-NetFirewallRule -DisplayName $ruleName `
        -Direction Inbound -Protocol TCP -LocalPort 11434 `
        -Action Allow -Profile Private,Domain | Out-Null
}

Write-Host ""
Write-Host "Next steps:"
Write-Host "  1. Quit Ollama from the system tray (right-click -> Quit)"
Write-Host "  2. Relaunch Ollama from the Start menu"
Write-Host "  3. In WSL: bash ~/.dotfiles/scripts/setup_ollama_wsl.sh"
Write-Host ""
Write-Host "If the WSL vEthernet adapter is classified as Public, add Public to the rule:"
Write-Host "  Set-NetFirewallRule -DisplayName '$ruleName' -Profile Private,Domain,Public"
