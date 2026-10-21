# First-logon bootstrap for the golden image.
#
# Runs once from the answer-file ISO, after OOBE, before Packer connects.
# Everything here is image-level and must stay stable across clones. Anything
# that differs per host belongs in Ansible.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'
$log = 'C:\Windows\Temp\bootstrap.log'
Start-Transcript -Path $log -Append | Out-Null

try {
    Write-Output "bootstrap start $(Get-Date -Format o)"

    # Private network profile, so firewall rules apply predictably.
    Get-NetConnectionProfile -ErrorAction SilentlyContinue |
        Set-NetConnectionProfile -NetworkCategory Private -ErrorAction SilentlyContinue

    # WinRM service plus HTTPS listener. Packer connects to 5986.
    Set-Service -Name WinRM -StartupType Automatic
    Start-Service -Name WinRM

    & winrm set winrm/config/service '@{AllowUnencrypted="false"}'
    & winrm set winrm/config/service/auth '@{Basic="true"}'
    & winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="2048"}'

    $cert = Get-ChildItem -Path Cert:\LocalMachine\My |
        Where-Object { $_.Subject -eq "CN=$env:COMPUTERNAME" } |
        Select-Object -First 1

    if (-not $cert) {
        $cert = New-SelfSignedCertificate `
            -DnsName $env:COMPUTERNAME `
            -CertStoreLocation Cert:\LocalMachine\My `
            -KeyExportPolicy Exportable `
            -NotAfter (Get-Date).AddYears(3)
    }

    $listener = Get-WSManInstance -ResourceURI winrm/config/Listener `
        -SelectorSet @{ Address = '*'; Transport = 'HTTPS' } `
        -ErrorAction SilentlyContinue

    if (-not $listener) {
        New-WSManInstance -ResourceURI winrm/config/Listener `
            -SelectorSet @{ Address = '*'; Transport = 'HTTPS' } `
            -ValueSet @{ Hostname = $env:COMPUTERNAME; CertificateThumbprint = $cert.Thumbprint }
    }

    New-NetFirewallRule -Name 'WinRM-HTTPS' `
        -DisplayName 'WinRM over HTTPS 5986' `
        -Protocol TCP -LocalPort 5986 -Direction Inbound `
        -Action Allow -Profile Any -ErrorAction SilentlyContinue

    # Virtio guest tools: qemu-guest-agent, balloon, and the remaining virtio
    # drivers. Terraform enables the agent, and Proxmox needs it for a clean
    # shutdown. The ISO is attached as a third disc.
    $virtio = Get-PSDrive -PSProvider FileSystem |
        Where-Object { Test-Path (Join-Path $_.Root 'virtio-win-gt-x64.msi') } |
        Select-Object -First 1

    if ($virtio) {
        $msi = Join-Path $virtio.Root 'virtio-win-gt-x64.msi'
        Write-Output "installing $msi"
        $p = Start-Process -FilePath msiexec.exe `
            -ArgumentList "/i `"$msi`" /qn /norestart" `
            -Wait -PassThru -NoNewWindow
        Write-Output "virtio guest tools exit code $($p.ExitCode)"
    }
    else {
        Write-Warning 'virtio-win guest tools MSI not found on any attached disc'
    }

    # RDP stays closed. Access is WinRM only, and hardening enforces it later.
    Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' `
        -Name 'fDenyTSConnections' -Value 1 -Type DWord

    # High performance power plan, no hibernation, predictable pagefile.
    & powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    & powercfg /h off

    Write-Output "bootstrap done $(Get-Date -Format o)"
}
catch {
    Write-Error $_
    Stop-Transcript
    throw
}

Stop-Transcript
exit 0
