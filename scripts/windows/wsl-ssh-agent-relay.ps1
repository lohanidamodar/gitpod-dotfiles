<#
.SYNOPSIS
    Make native Windows ssh.exe / git use the ssh-agent running inside WSL.

.DESCRIPTION
    Windows OpenSSH always talks to the named pipe \\.\pipe\openssh-ssh-agent.
    This script takes over that pipe name and forwards every connection into the
    WSL ssh-agent's unix socket (~/.ssh/agent.sock) via `wsl.exe ... socat`.
    Your private keys stay in WSL; Windows just asks the WSL agent to sign.

    Run scripts/wsl_ssh_agent_serve.sh inside WSL FIRST (starts the agent +
    installs socat), then run this on Windows.

.PARAMETER Distro
    WSL distro name. Omit to use your default distro.

.PARAMETER StopWindowsAgent
    Stop and disable the Windows OpenSSH Authentication Agent service so this
    relay can own the pipe (recommended; requires an elevated shell).

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File wsl-ssh-agent-relay.ps1 -StopWindowsAgent

.NOTES
    Auto-start at logon: create a shortcut in shell:startup (Win+R -> shell:startup)
    with target:
        powershell -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\path\to\wsl-ssh-agent-relay.ps1"
    (or run from \\wsl$\<distro>\home\<user>\.dotfiles\scripts\windows\)
#>
param(
    [string]$Distro = "",
    [switch]$StopWindowsAgent
)

$ErrorActionPreference = "Stop"
$pipeName = "openssh-ssh-agent"

$wslArgs = @()
if ($Distro) { $wslArgs += @("-d", $Distro) }

# Resolve the WSL home and the agent socket path.
$wslHome = (& wsl.exe @wslArgs -e sh -c 'echo $HOME') 2>$null
if ($wslHome) { $wslHome = $wslHome.Trim() }
if (-not $wslHome) { throw "Could not query WSL home. Is the distro installed and running?" }
$sock = "$wslHome/.ssh/agent.sock"

Write-Host "Relaying \\.\pipe\$pipeName  ->  WSL $sock"

if ($StopWindowsAgent) {
    try {
        Stop-Service ssh-agent -ErrorAction SilentlyContinue
        Set-Service  ssh-agent -StartupType Disabled -ErrorAction SilentlyContinue
        Write-Host "Stopped and disabled the Windows OpenSSH Authentication Agent service."
    } catch {
        Write-Warning "Could not stop the Windows ssh-agent service (run as Administrator). $_"
    }
}

# Build the wsl.exe argument string for the forwarding socat call.
$fwdArgs = ""
if ($Distro) { $fwdArgs = "-d `"$Distro`" " }
$fwdArgs += "-e socat - UNIX-CONNECT:`"$sock`""

Write-Host "Relay running. Press Ctrl+C to stop."

while ($true) {
    $server = New-Object System.IO.Pipes.NamedPipeServerStream(
        $pipeName,
        [System.IO.Pipes.PipeDirection]::InOut,
        16,
        [System.IO.Pipes.PipeTransmissionMode]::Byte,
        [System.IO.Pipes.PipeOptions]::Asynchronous)

    try {
        $server.WaitForConnection()

        $psi = New-Object System.Diagnostics.ProcessStartInfo
        $psi.FileName               = "wsl.exe"
        $psi.Arguments              = $fwdArgs
        $psi.UseShellExecute        = $false
        $psi.CreateNoWindow         = $true
        $psi.RedirectStandardInput  = $true
        $psi.RedirectStandardOutput = $true

        $proc = [System.Diagnostics.Process]::Start($psi)

        # Pump bytes both ways until either side closes.
        $toWsl   = $server.CopyToAsync($proc.StandardInput.BaseStream)
        $fromWsl = $proc.StandardOutput.BaseStream.CopyToAsync($server)
        [System.Threading.Tasks.Task]::WaitAny(@($toWsl, $fromWsl)) | Out-Null
    } catch {
        Write-Warning "connection error: $_"
    } finally {
        try { $proc.StandardInput.Close() } catch {}
        try { if ($proc -and -not $proc.HasExited) { $proc.Kill() } } catch {}
        try { if ($server.IsConnected) { $server.Disconnect() } } catch {}
        $server.Dispose()
    }
}
