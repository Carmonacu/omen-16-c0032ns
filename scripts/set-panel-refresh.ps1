# Sets only the internal 1920x1080 panel refresh rate:
#   AC (plugged in) -> 144 Hz
#   DC (battery)    -> 60 Hz, or the lowest advertised 1920x1080 rate if 60 Hz is absent
# External monitors are never passed to ChangeDisplaySettingsEx.
# The script aborts unless it finds exactly one INTERNAL 1920x1080 panel
# whose source is not cloned to another output.
# A run log, refresh-run.log, is written next to this file. Keep that log local.
#
# Register the logon and power-source task with register-panel-refresh-task.ps1
# (same folder). Disable or remove it later:
#   Disable-ScheduledTask -TaskName 'EquipoPanelRefresh'
#   Unregister-ScheduledTask -TaskName 'EquipoPanelRefresh' -Confirm:$false
# After disabling, run this script once while plugged in to return to 144 Hz.
# It follows the current power source; it does not force 60 Hz on AC.
# Query without changing the mode:
#   powershell -NoProfile -ExecutionPolicy Bypass -File .\set-panel-refresh.ps1 -Query
#Requires -Version 5.1
[CmdletBinding()]
param(
    [switch]$Query
)

$ErrorActionPreference = 'Stop'
$LogPath = Join-Path (Split-Path -Parent $PSCommandPath) 'refresh-run.log'

function Write-RunLog {
    param([string]$Message)
    $line = '{0} {1}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Message
    Add-Content -LiteralPath $LogPath -Value $line -Encoding UTF8
    Write-Output $line
}

if (-not ('EquipoBenchmark.DisplayNative' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace EquipoBenchmark {
    [StructLayout(LayoutKind.Sequential)]
    public struct Luid {
        public uint LowPart;
        public int HighPart;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigRational {
        public uint Numerator;
        public uint Denominator;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigPathSourceInfo {
        public Luid AdapterId;
        public uint Id;
        public uint ModeInfoIdx;
        public uint StatusFlags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigPathTargetInfo {
        public Luid AdapterId;
        public uint Id;
        public uint ModeInfoIdx;
        public uint OutputTechnology;
        public uint Rotation;
        public uint Scaling;
        public DisplayConfigRational RefreshRate;
        public uint ScanLineOrdering;
        public bool TargetAvailable;
        public uint StatusFlags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigPathInfo {
        public DisplayConfigPathSourceInfo SourceInfo;
        public DisplayConfigPathTargetInfo TargetInfo;
        public uint Flags;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfig2DRegion {
        public uint Cx;
        public uint Cy;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigVideoSignalInfo {
        public ulong PixelRate;
        public DisplayConfigRational HSyncFreq;
        public DisplayConfigRational VSyncFreq;
        public DisplayConfig2DRegion ActiveSize;
        public DisplayConfig2DRegion TotalSize;
        public uint VideoStandard;
        public uint ScanLineOrdering;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigTargetMode {
        public DisplayConfigVideoSignalInfo TargetVideoSignalInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigSourceMode {
        public uint Width;
        public uint Height;
        public uint PixelFormat;
        public int PositionX;
        public int PositionY;
    }

    [StructLayout(LayoutKind.Explicit)]
    public struct DisplayConfigModeInfoUnion {
        [FieldOffset(0)] public DisplayConfigTargetMode TargetMode;
        [FieldOffset(0)] public DisplayConfigSourceMode SourceMode;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigModeInfo {
        public uint InfoType;
        public uint Id;
        public Luid AdapterId;
        public DisplayConfigModeInfoUnion ModeInfo;
    }

    [StructLayout(LayoutKind.Sequential)]
    public struct DisplayConfigDeviceInfoHeader {
        public int Type;
        public int Size;
        public Luid AdapterId;
        public uint Id;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DisplayConfigSourceDeviceName {
        public DisplayConfigDeviceInfoHeader Header;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string ViewGdiDeviceName;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DisplayConfigTargetDeviceName {
        public DisplayConfigDeviceInfoHeader Header;
        public uint Flags;
        public uint OutputTechnology;
        public ushort EdidManufactureId;
        public ushort EdidProductCodeId;
        public uint ConnectorInstance;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 64)]
        public string MonitorFriendlyDeviceName;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)]
        public string MonitorDevicePath;
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct DevMode {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmDeviceName;
        public ushort dmSpecVersion;
        public ushort dmDriverVersion;
        public ushort dmSize;
        public ushort dmDriverExtra;
        public uint dmFields;
        public int dmPositionX;
        public int dmPositionY;
        public uint dmDisplayOrientation;
        public uint dmDisplayFixedOutput;
        public short dmColor;
        public short dmDuplex;
        public short dmYResolution;
        public short dmTTOption;
        public short dmCollate;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)]
        public string dmFormName;
        public ushort dmLogPixels;
        public uint dmBitsPerPel;
        public uint dmPelsWidth;
        public uint dmPelsHeight;
        public uint dmDisplayFlags;
        public uint dmDisplayFrequency;
        public uint dmICMMethod;
        public uint dmICMIntent;
        public uint dmMediaType;
        public uint dmDitherType;
        public uint dmReserved1;
        public uint dmReserved2;
        public uint dmPanningWidth;
        public uint dmPanningHeight;
    }

    public static class DisplayNative {
        const uint DmBitsPerPel = 0x00040000;
        const uint DmPelsWidth = 0x00080000;
        const uint DmPelsHeight = 0x00100000;
        const uint DmDisplayFrequency = 0x00400000;
        const int EnumCurrentSettings = -1;
        const uint CdsUpdateRegistry = 0x00000001;
        const uint CdsTest = 0x00000002;
        const int DisplayConfigGetSourceName = 1;
        const int DisplayConfigGetTargetName = 2;
        const uint QdcOnlyActivePaths = 0x00000002;
        const uint QdcVirtualModeAware = 0x00000010;
        const uint TechnologyInternal = 0x80000000;

        [DllImport("user32.dll")]
        static extern int GetDisplayConfigBufferSizes(uint flags, out uint numPathArrayElements, out uint numModeInfoArrayElements);

        [DllImport("user32.dll")]
        static extern int QueryDisplayConfig(
            uint flags,
            ref uint numPathArrayElements,
            [Out] DisplayConfigPathInfo[] pathArray,
            ref uint numModeInfoArrayElements,
            [Out] DisplayConfigModeInfo[] modeInfoArray,
            IntPtr currentTopologyId);

        [DllImport("user32.dll")]
        static extern int DisplayConfigGetDeviceInfo(ref DisplayConfigSourceDeviceName requestPacket);

        [DllImport("user32.dll")]
        static extern int DisplayConfigGetDeviceInfo(ref DisplayConfigTargetDeviceName requestPacket);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        static extern bool EnumDisplaySettingsEx(string deviceName, int modeNum, ref DevMode devMode, uint flags);

        [DllImport("user32.dll", CharSet = CharSet.Unicode)]
        static extern int ChangeDisplaySettingsEx(string deviceName, ref DevMode devMode, IntPtr hwnd, uint flags, IntPtr lParam);

        public static string SizeReport() {
            return "path=" + Marshal.SizeOf(typeof(DisplayConfigPathInfo))
                + " mode=" + Marshal.SizeOf(typeof(DisplayConfigModeInfo))
                + " sourceName=" + Marshal.SizeOf(typeof(DisplayConfigSourceDeviceName))
                + " targetName=" + Marshal.SizeOf(typeof(DisplayConfigTargetDeviceName))
                + " devmode=" + Marshal.SizeOf(typeof(DevMode));
        }

        public static string TechnologyName(uint technology) {
            if (technology == TechnologyInternal) return "INTERNAL";
            switch (technology) {
                case 0: return "OTHER";
                case 5: return "HDMI";
                case 10: return "DISPLAYPORT_EXTERNAL";
                case 11: return "DISPLAYPORT_EMBEDDED";
                case 15: return "MIRACAST";
                case 16: return "INDIRECT_WIRED";
                default: return "TECH_" + technology.ToString("X");
            }
        }

        static DevMode EmptyMode() {
            DevMode mode = new DevMode();
            mode.dmSize = (ushort)Marshal.SizeOf(typeof(DevMode));
            return mode;
        }

        public static string CurrentMode(string deviceName) {
            DevMode mode = EmptyMode();
            if (!EnumDisplaySettingsEx(deviceName, EnumCurrentSettings, ref mode, 0)) {
                throw new InvalidOperationException("EnumDisplaySettingsEx current failed for " + deviceName);
            }
            return mode.dmPelsWidth + "," + mode.dmPelsHeight + "," + mode.dmBitsPerPel + "," + mode.dmDisplayFrequency;
        }

        public static string[] ModesAt(string deviceName, uint width, uint height, uint bits) {
            List<string> found = new List<string>();
            HashSet<uint> seen = new HashSet<uint>();
            for (int i = 0; i < 500; i++) {
                DevMode mode = EmptyMode();
                if (!EnumDisplaySettingsEx(deviceName, i, ref mode, 0)) break;
                if (mode.dmPelsWidth == width && mode.dmPelsHeight == height && mode.dmBitsPerPel == bits) {
                    if (seen.Add(mode.dmDisplayFrequency)) found.Add(mode.dmDisplayFrequency.ToString());
                }
            }
            return found.ToArray();
        }

        public static string ApplyHz(string deviceName, uint targetHz) {
            DevMode before = EmptyMode();
            if (!EnumDisplaySettingsEx(deviceName, EnumCurrentSettings, ref before, 0)) {
                throw new InvalidOperationException("Cannot read current mode for " + deviceName);
            }
            if (before.dmDisplayFrequency == targetHz) {
                return "unchanged " + before.dmPelsWidth + "x" + before.dmPelsHeight + "@" + before.dmDisplayFrequency;
            }

            bool found = false;
            DevMode chosen = new DevMode();
            for (int i = 0; i < 500; i++) {
                DevMode mode = EmptyMode();
                if (!EnumDisplaySettingsEx(deviceName, i, ref mode, 0)) break;
                if (mode.dmPelsWidth == before.dmPelsWidth
                    && mode.dmPelsHeight == before.dmPelsHeight
                    && mode.dmBitsPerPel == before.dmBitsPerPel
                    && mode.dmDisplayFrequency == targetHz) {
                    chosen = mode;
                    found = true;
                    break;
                }
            }
            if (!found) {
                throw new InvalidOperationException("Refresh " + targetHz + " Hz is not advertised at "
                    + before.dmPelsWidth + "x" + before.dmPelsHeight + " for " + deviceName);
            }

            chosen.dmFields |= DmBitsPerPel | DmPelsWidth | DmPelsHeight | DmDisplayFrequency;
            int test = ChangeDisplaySettingsEx(deviceName, ref chosen, IntPtr.Zero, CdsTest, IntPtr.Zero);
            if (test != 0) {
                throw new InvalidOperationException("CDS_TEST returned " + test + " for " + deviceName + " @" + targetHz);
            }
            int applied = ChangeDisplaySettingsEx(deviceName, ref chosen, IntPtr.Zero, CdsUpdateRegistry, IntPtr.Zero);
            DevMode after = EmptyMode();
            bool readAfter = EnumDisplaySettingsEx(deviceName, EnumCurrentSettings, ref after, 0);
            if (applied != 0 || !readAfter || after.dmDisplayFrequency != targetHz
                || after.dmPelsWidth != before.dmPelsWidth || after.dmPelsHeight != before.dmPelsHeight) {
                ChangeDisplaySettingsEx(deviceName, ref before, IntPtr.Zero, CdsUpdateRegistry, IntPtr.Zero);
                throw new InvalidOperationException("Apply returned " + applied + " after="
                    + (readAfter ? after.dmPelsWidth + "x" + after.dmPelsHeight + "@" + after.dmDisplayFrequency : "unreadable")
                    + "; restored previous mode");
            }
            return "set " + after.dmPelsWidth + "x" + after.dmPelsHeight + "@" + after.dmDisplayFrequency;
        }

        public static string[] QueryPaths() {
            uint flags = QdcOnlyActivePaths | QdcVirtualModeAware;
            uint pathCount;
            uint modeCount;
            int err = GetDisplayConfigBufferSizes(flags, out pathCount, out modeCount);
            if (err != 0) {
                flags = QdcOnlyActivePaths;
                err = GetDisplayConfigBufferSizes(flags, out pathCount, out modeCount);
            }
            if (err != 0) throw new InvalidOperationException("GetDisplayConfigBufferSizes failed: " + err);

            DisplayConfigPathInfo[] paths = new DisplayConfigPathInfo[pathCount];
            DisplayConfigModeInfo[] modes = new DisplayConfigModeInfo[Math.Max(modeCount, 1)];
            err = QueryDisplayConfig(flags, ref pathCount, paths, ref modeCount, modes, IntPtr.Zero);
            if (err != 0) {
                throw new InvalidOperationException("QueryDisplayConfig failed: " + err + " (" + SizeReport() + ")");
            }

            List<string> rows = new List<string>();
            for (int i = 0; i < pathCount; i++) {
                DisplayConfigPathInfo path = paths[i];
                DisplayConfigSourceDeviceName source = new DisplayConfigSourceDeviceName();
                source.Header.Type = DisplayConfigGetSourceName;
                source.Header.Size = Marshal.SizeOf(typeof(DisplayConfigSourceDeviceName));
                source.Header.AdapterId = path.SourceInfo.AdapterId;
                source.Header.Id = path.SourceInfo.Id;
                int sourceErr = DisplayConfigGetDeviceInfo(ref source);

                DisplayConfigTargetDeviceName target = new DisplayConfigTargetDeviceName();
                target.Header.Type = DisplayConfigGetTargetName;
                target.Header.Size = Marshal.SizeOf(typeof(DisplayConfigTargetDeviceName));
                target.Header.AdapterId = path.TargetInfo.AdapterId;
                target.Header.Id = path.TargetInfo.Id;
                int targetErr = DisplayConfigGetDeviceInfo(ref target);

                string gdi = sourceErr == 0 ? source.ViewGdiDeviceName : "";
                string friendly = targetErr == 0 ? target.MonitorFriendlyDeviceName : "";
                uint tech = path.TargetInfo.OutputTechnology;
                string sourceKey = path.SourceInfo.AdapterId.LowPart + ":" + path.SourceInfo.AdapterId.HighPart + ":" + path.SourceInfo.Id;
                string mode = "";
                if (!string.IsNullOrEmpty(gdi)) {
                    try { mode = CurrentMode(gdi); } catch (Exception ex) { mode = "ERR " + ex.Message; }
                }
                rows.Add(string.Join("\t", new string[] {
                    sourceKey,
                    TechnologyName(tech),
                    tech.ToString(),
                    gdi ?? "",
                    friendly ?? "",
                    mode,
                    "sourceErr=" + sourceErr,
                    "targetErr=" + targetErr
                }));
            }
            return rows.ToArray();
        }
    }
}
'@ -Language CSharp
}

function Get-PowerLine {
    Add-Type -AssemblyName System.Windows.Forms
    $forms = [System.Windows.Forms.SystemInformation]::PowerStatus.PowerLineStatus.ToString()
    $wmiOnline = $null
    try {
        $battery = Get-CimInstance -Namespace root\wmi -ClassName BatteryStatus -ErrorAction Stop
        $wmiOnline = [bool]$battery.PowerOnline
    } catch {
        $wmiOnline = $null
    }
    if ($forms -eq 'Unknown') {
        throw 'Power line status is Unknown. No display change was made.'
    }
    $onAc = $forms -eq 'Online'
    if ($null -ne $wmiOnline -and $wmiOnline -ne $onAc) {
        throw "Power source disagreement: SystemInformation=$forms WmiPowerOnline=$wmiOnline. No display change was made."
    }
    [pscustomobject]@{ OnAc = $onAc; Forms = $forms; WmiOnline = $wmiOnline }
}

function Get-PanelRows {
    $raw = [EquipoBenchmark.DisplayNative]::QueryPaths()
    foreach ($line in $raw) {
        $p = $line -split "`t", -1
        $mode = $p[5] -split ','
        [pscustomobject]@{
            SourceKey  = $p[0]
            Technology = $p[1]
            TechCode   = $p[2]
            Gdi        = $p[3]
            Friendly   = $p[4]
            Width      = $(if ($mode.Length -ge 4) { [int]$mode[0] } else { 0 })
            Height     = $(if ($mode.Length -ge 4) { [int]$mode[1] } else { 0 })
            Bits       = $(if ($mode.Length -ge 4) { [int]$mode[2] } else { 0 })
            Hz         = $(if ($mode.Length -ge 4) { [int]$mode[3] } else { 0 })
            ModeText   = $p[5]
            Detail     = $line
        }
    }
}

try {
    Write-RunLog ("sizes " + [EquipoBenchmark.DisplayNative]::SizeReport())
    $power = Get-PowerLine
    $rows = @(Get-PanelRows)
    if ($rows.Count -eq 0) { throw 'QueryDisplayConfig returned no active paths.' }

    foreach ($row in $rows) {
        $advertised = @()
        if ($row.Gdi -and $row.Width -gt 0) {
            $advertised = @([EquipoBenchmark.DisplayNative]::ModesAt($row.Gdi, [uint32]$row.Width, [uint32]$row.Height, [uint32]$row.Bits))
        }
        $row | Add-Member -NotePropertyName AdvertisedHz -NotePropertyValue ($advertised -join ',')
        Write-RunLog ("PATH tech=$($row.Technology) gdi=$($row.Gdi) name=$($row.Friendly) mode=$($row.Width)x$($row.Height)@$($row.Hz) advertised=[$($row.AdvertisedHz)] source=$($row.SourceKey)")
    }

    # Extra abort if a friendly name looks like an external or virtual display.
    # The binding rule is output technology INTERNAL, above. Edit this pattern
    # if it matches your internal panel.
    $blockedName = '(?i)Dell|Samsung|Parsec|P2423|LU28'
    $internal = @($rows | Where-Object { $_.Technology -eq 'INTERNAL' -and $_.Friendly -notmatch $blockedName })
    if ($internal.Count -ne 1) {
        throw "Expected exactly one internal panel, found $($internal.Count). No display was changed."
    }
    $panel = $internal[0]
    $shared = @($rows | Where-Object { $_.SourceKey -eq $panel.SourceKey -and $_.Gdi -ne $panel.Gdi })
    if ($shared.Count -gt 0) {
        throw "Internal panel source is cloned with another output. No display was changed."
    }
    if ($panel.Width -ne 1920 -or $panel.Height -ne 1080) {
        throw "Internal panel is $($panel.Width)x$($panel.Height), not 1920x1080. Resolution was not changed."
    }

    $hzList = @()
    if ($panel.AdvertisedHz) { $hzList = @($panel.AdvertisedHz -split ',' | ForEach-Object { [int]$_ }) }
    $target = $null
    $targetNote = '144'
    if ($power.OnAc) {
        if ($hzList -notcontains 144) {
            throw '144 Hz is not an advertised 1920x1080 mode on the internal panel. No display was changed.'
        }
        $target = 144
    } else {
        if ($hzList -contains 60) {
            $target = 60
            $targetNote = '60'
        } else {
            if ($hzList.Count -eq 0) { throw 'No advertised 1920x1080 modes on the internal panel. No display was changed.' }
            $target = ($hzList | Measure-Object -Minimum).Minimum
            $targetNote = "lowest-advertised $target (60 Hz was not advertised)"
        }
    }

    Write-RunLog ("POWER forms=$($power.Forms) wmiOnline=$($power.WmiOnline) target=$targetNote panel=$($panel.Gdi)")
    if ($Query) {
        Write-RunLog 'QUERY only. No mode change.'
        exit 0
    }

    $result = [EquipoBenchmark.DisplayNative]::ApplyHz($panel.Gdi, [uint32]$target)
    Write-RunLog ("APPLY $($panel.Gdi) $result")

    $after = @(Get-PanelRows)
    foreach ($row in $after) {
        Write-RunLog ("AFTER tech=$($row.Technology) gdi=$($row.Gdi) name=$($row.Friendly) mode=$($row.Width)x$($row.Height)@$($row.Hz)")
    }
    $panelAfter = @($after | Where-Object { $_.Gdi -eq $panel.Gdi -and $_.Technology -eq 'INTERNAL' })
    if ($panelAfter.Count -ne 1 -or $panelAfter[0].Hz -ne $target -or $panelAfter[0].Width -ne 1920 -or $panelAfter[0].Height -ne 1080) {
        throw "Verification failed after apply. Internal mode is not ${target} Hz at 1920x1080."
    }
    exit 0
} catch {
    Write-RunLog ("ERROR " + $_.Exception.Message)
    exit 1
}
