# Kenai Switch (Windows side)
# Fullscreen, controller-first screen that restarts the PC into Kenai OS for one boot.
# A = restart (3-second countdown, B cancels), B = close. Keyboard: Enter / Esc.
# The actual restart runs through the "Kenai Switch" scheduled task created by the
# installer, so no admin prompt interrupts you mid-controller.

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class KenaiXInput {
    [StructLayout(LayoutKind.Sequential)]
    public struct GAMEPAD { public ushort Buttons; public byte LT; public byte RT; public short LX; public short LY; public short RX; public short RY; }
    [StructLayout(LayoutKind.Sequential)]
    public struct STATE { public uint Packet; public GAMEPAD Pad; }
    [DllImport("xinput1_4.dll", EntryPoint = "XInputGetState")]
    static extern uint GetState(uint index, out STATE state);
    // Returns the OR of buttons held on any connected controller (0 if none).
    public static ushort Buttons() {
        ushort all = 0;
        for (uint i = 0; i < 4; i++) {
            STATE s;
            try { if (GetState(i, out s) == 0) all |= s.Pad.Buttons; } catch { return all; }
        }
        return all;
    }
}
"@

$here      = Split-Path -Parent $MyInvocation.MyCommand.Path
$TaskName  = 'Kenai Switch'
$Countdown = 3.0
$BtnA      = 0x1000
$BtnB      = 0x2000

function Load-Image($path) {
    $bmp = New-Object System.Windows.Media.Imaging.BitmapImage
    $bmp.BeginInit()
    $bmp.UriSource = New-Object System.Uri($path)
    $bmp.CacheOption = 'OnLoad'
    $bmp.EndInit()
    return $bmp
}

$mainImg = Load-Image (Join-Path $here 'assets\from-windows.png')
$restImg = Load-Image (Join-Path $here 'assets\from-windows-restart.png')

$window = New-Object System.Windows.Window
$window.WindowStyle = 'None'
$window.ResizeMode = 'NoResize'
$window.WindowState = 'Maximized'
$window.Topmost = $true
$window.Background = [System.Windows.Media.Brushes]::Black
$window.Cursor = [System.Windows.Input.Cursors]::None
$window.Title = 'Kenai Switch'

$grid = New-Object System.Windows.Controls.Grid
$view = New-Object System.Windows.Controls.Viewbox
$view.Stretch = 'Uniform'
$canvas = New-Object System.Windows.Controls.Canvas
$canvas.Width = 1920; $canvas.Height = 1080

$image = New-Object System.Windows.Controls.Image
$image.Source = $mainImg
$image.Width = 1920; $image.Height = 1080
$canvas.Children.Add($image) | Out-Null

# Countdown bar (drawn over the "Restarting" screen)
$track = New-Object System.Windows.Shapes.Rectangle
$track.Width = 576; $track.Height = 8; $track.RadiusX = 4; $track.RadiusY = 4
$track.Fill = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(60, 30, 32))
[System.Windows.Controls.Canvas]::SetLeft($track, 672); [System.Windows.Controls.Canvas]::SetTop($track, 605)
$fill = New-Object System.Windows.Shapes.Rectangle
$fill.Width = 0; $fill.Height = 8; $fill.RadiusX = 4; $fill.RadiusY = 4
$fill.Fill = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(255, 90, 72))
[System.Windows.Controls.Canvas]::SetLeft($fill, 672); [System.Windows.Controls.Canvas]::SetTop($fill, 605)
$track.Visibility = 'Hidden'; $fill.Visibility = 'Hidden'
$canvas.Children.Add($track) | Out-Null
$canvas.Children.Add($fill) | Out-Null

# Error message
$msg = New-Object System.Windows.Controls.TextBlock
$msg.Foreground = [System.Windows.Media.Brushes]::White; $msg.FontSize = 30; $msg.FontWeight = [System.Windows.FontWeights]::SemiBold
$msg.Background = New-Object System.Windows.Media.SolidColorBrush ([System.Windows.Media.Color]::FromRgb(120, 18, 24))
$msg.Padding = New-Object System.Windows.Thickness(24, 12, 24, 12); $msg.Visibility = 'Hidden'
[System.Windows.Controls.Canvas]::SetTop($msg, 900)
$canvas.Children.Add($msg) | Out-Null

$view.Child = $canvas
$grid.Children.Add($view) | Out-Null
$window.Content = $grid

$script:state     = 'main'
$script:t0        = [datetime]::Now
$script:opened    = [datetime]::Now
$script:prev      = [uint16]0xFFFF   # treat everything as "held" until released once
$script:lastKey   = $null

function Show-Error($text) {
    $msg.Text = $text
    $msg.Visibility = 'Visible'
    $msg.Measure([System.Windows.Size]::new([double]::PositiveInfinity, [double]::PositiveInfinity))
    [System.Windows.Controls.Canvas]::SetLeft($msg, (1920 - $msg.DesiredSize.Width) / 2)
    $script:state = 'error'
}

function Do-Action($a) {
    if (([datetime]::Now - $script:opened).TotalSeconds -lt 0.4) { return }
    switch ($script:state) {
        'main' {
            if ($a -eq 'A') {
                $script:state = 'restart'; $script:t0 = [datetime]::Now
                $image.Source = $restImg; $track.Visibility = 'Visible'; $fill.Visibility = 'Visible'
            } elseif ($a -eq 'B') { $window.Close() }
        }
        'restart' {
            if ($a -eq 'B') {
                $script:state = 'main'; $image.Source = $mainImg
                $track.Visibility = 'Hidden'; $fill.Visibility = 'Hidden'; $fill.Width = 0
            }
        }
        'error' { $window.Close() }
    }
}

$window.Add_KeyDown({
    param($s, $e)
    switch ($e.Key) {
        'Return' { Do-Action 'A' }
        'Space'  { Do-Action 'A' }
        'Escape' { Do-Action 'B' }
        'Back'   { Do-Action 'B' }
    }
})

$timer = New-Object System.Windows.Threading.DispatcherTimer
$timer.Interval = [TimeSpan]::FromMilliseconds(16)
$timer.Add_Tick({
    $now = [KenaiXInput]::Buttons()
    $pressed = $now -band (-bnot $script:prev) -band 0xFFFF
    $script:prev = $now
    if ($pressed -band $BtnA) { Do-Action 'A' }
    elseif ($pressed -band $BtnB) { Do-Action 'B' }

    if ($script:state -eq 'restart') {
        $p = [Math]::Min(1.0, ([datetime]::Now - $script:t0).TotalSeconds / $Countdown)
        $fill.Width = 576 * $p
        if ($p -ge 1.0) {
            $script:state = 'rebooting'
            schtasks.exe /run /tn "$TaskName" | Out-Null
            if ($LASTEXITCODE -ne 0) {
                $image.Source = $mainImg; $track.Visibility = 'Hidden'; $fill.Visibility = 'Hidden'
                Show-Error "Couldn't start the restart task. Run Install.cmd again. Press any button to close."
            }
        }
    }
})

$window.Add_Loaded({ $timer.Start(); $window.Activate() | Out-Null })
$window.Add_Closed({ $timer.Stop() })
$window.ShowDialog() | Out-Null
