# Registers EquipoPanelRefresh for the current interactive user (not SYSTEM).
# Triggers: at logon, and System log Microsoft-Windows-Kernel-Power event 105
# (power source change). The task may start on battery and is not stopped
# when switching to battery. External monitors are not mode-switched; that
# rule lives in set-panel-refresh.ps1, which must sit in this same folder.
#
# Re-running this script replaces an existing task of the same name.
#
# Disable:
#   Disable-ScheduledTask -TaskName 'EquipoPanelRefresh'
# Remove:
#   Unregister-ScheduledTask -TaskName 'EquipoPanelRefresh' -Confirm:$false
# After disabling, run set-panel-refresh.ps1 once while plugged in if the
# internal panel should return to 144 Hz.
#Requires -Version 5.1
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Escape-XmlText {
    param([string]$Value)
    return [System.Security.SecurityElement]::Escape($Value)
}

if ([string]::IsNullOrWhiteSpace($env:USERNAME)) {
    throw 'USERNAME is empty. Refusing to register a task without a user.'
}

$panelScript = Join-Path $PSScriptRoot 'set-panel-refresh.ps1'
if (-not (Test-Path -LiteralPath $panelScript)) {
    throw 'set-panel-refresh.ps1 was not found next to this script.'
}

$panelScript = (Resolve-Path -LiteralPath $panelScript).Path
$userId = if ([string]::IsNullOrWhiteSpace($env:USERDOMAIN)) {
    $env:USERNAME
} else {
    "$env:USERDOMAIN\$env:USERNAME"
}

$arguments = "-NoProfile -NonInteractive -WindowStyle Hidden -ExecutionPolicy Bypass -File `"$panelScript`""
$subscription = "<QueryList><Query Id=`"0`" Path=`"System`"><Select Path=`"System`">*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and (EventID=105)]]</Select></Query></QueryList>"

$xml = @"
<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Description>Sets the internal 1920x1080 panel to 144 Hz on AC and 60 Hz on battery. External monitors are not changed.</Description>
  </RegistrationInfo>
  <Triggers>
    <LogonTrigger>
      <Enabled>true</Enabled>
      <UserId>$(Escape-XmlText $userId)</UserId>
    </LogonTrigger>
    <EventTrigger>
      <Enabled>true</Enabled>
      <Subscription>$(Escape-XmlText $subscription)</Subscription>
    </EventTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$(Escape-XmlText $userId)</UserId>
      <LogonType>InteractiveToken</LogonType>
      <RunLevel>LeastPrivilege</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <ExecutionTimeLimit>PT5M</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>$(Escape-XmlText $arguments)</Arguments>
    </Exec>
  </Actions>
</Task>
"@

Register-ScheduledTask -TaskName 'EquipoPanelRefresh' -Xml $xml -Force | Out-Null
Write-Output 'Registered EquipoPanelRefresh for the current user.'
Write-Output 'Disable-ScheduledTask -TaskName EquipoPanelRefresh'
