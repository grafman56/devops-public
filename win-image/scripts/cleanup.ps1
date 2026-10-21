# Pre-sysprep cleanup. Runs as the last provisioning step, then Packer calls
# sysprep /generalize /oobe /shutdown.

#Requires -Version 5.1
$ErrorActionPreference = 'Stop'

Write-Output "cleanup start $(Get-Date -Format o)"

# Packer uploaded the deploy answer file. Sysprep looks for unattend.xml in its
# own directory, and it stays cached in the template for every clone.
$deploy = 'C:\Windows\Temp\unattend-deploy.xml'
if (Test-Path $deploy) {
    Copy-Item -Path $deploy -Destination 'C:\Windows\System32\Sysprep\unattend.xml' -Force
    Write-Output 'deploy answer file installed'
}
else {
    throw "missing $deploy, refusing to generalize without an OOBE answer file"
}

# Image hygiene.
Remove-Item -Path 'C:\Windows\Temp\*' -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path 'C:\Users\Administrator\AppData\Local\Temp\*' -Recurse -Force -ErrorAction SilentlyContinue

foreach ($l in 'System', 'Application') {
    & wevtutil cl $l 2>$null
}

# Leave a build record in the image. Ansible reads it back as evidence.
$marker = @(
    "image=win2025-gold",
    "built=$(Get-Date -Format o)",
    "build=$((Get-CimInstance Win32_OperatingSystem).BuildNumber)",
    "product=$((Get-CimInstance Win32_OperatingSystem).Caption)"
)
Set-Content -Path 'C:\image-build.txt' -Value $marker -Encoding ascii

Write-Output "cleanup done $(Get-Date -Format o)"
exit 0
