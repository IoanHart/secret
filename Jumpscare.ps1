Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$imgPath = Join-Path $PSScriptRoot "jumpscare.jpg"
$wavPath = Join-Path $env:TEMP "jumpscare_creepy.wav"

# ============================================================
# CREATE A CREEPY WAV SOUND
# ============================================================

$sampleRate = 11025
$duration = 20
$numSamples = $sampleRate * $duration

$stream = [System.IO.File]::Create($wavPath)
$writer = New-Object System.IO.BinaryWriter($stream)

# WAV header
$writer.Write([System.Text.Encoding]::ASCII.GetBytes("RIFF"))
$writer.Write([int](36 + $numSamples * 2))
$writer.Write([System.Text.Encoding]::ASCII.GetBytes("WAVE"))
$writer.Write([System.Text.Encoding]::ASCII.GetBytes("fmt "))
$writer.Write([int]16)
$writer.Write([int16]1)
$writer.Write([int16]1)
$writer.Write([int32]$sampleRate)
$writer.Write([int32]($sampleRate * 2))
$writer.Write([int16]2)
$writer.Write([int16]16)
$writer.Write([System.Text.Encoding]::ASCII.GetBytes("data"))
$writer.Write([int]($numSamples * 2))

$random = New-Object System.Random

# Generate eerie drone + distorted tones + noise
for ($i = 0; $i -lt $numSamples; $i++) {

    $t = $i / $sampleRate

    # Deep drone
    $a = [Math]::Sin(2 * [Math]::PI * 55 * $t)

    # Slowly changing second tone
    $freq = 110 + (35 * [Math]::Sin(2 * [Math]::PI * 0.17 * $t))
    $b = [Math]::Sin(2 * [Math]::PI * $freq * $t)

    # Higher creepy tone
    $c = [Math]::Sin(
        2 * [Math]::PI *
        (420 + 80 * [Math]::Sin(2 * [Math]::PI * 0.31 * $t)) *
        $t
    )

    # Random noise
    $noise = ($random.NextDouble() * 2) - 1

    # Make the sound pulse
    $pulse = 0.5 + 0.5 * [Math]::Sin(2 * [Math]::PI * 1.7 * $t)

    $sample = (
        ($a * 0.35) +
        ($b * 0.25) +
        ($c * 0.12) +
        ($noise * 0.08 * $pulse)
    )

    # Occasional harsh distortion
    if (([Math]::Floor($t * 4) % 7) -eq 0) {
        $sample *= 1.7
    }

    # Clamp
    if ($sample -gt 1) { $sample = 1 }
    if ($sample -lt -1) { $sample = -1 }

    $value = [int16]($sample * 30000)
    $writer.Write($value)
}

$writer.Close()
$stream.Close()

# ============================================================
# CREATE FULLSCREEN WINDOW
# ============================================================

$form = New-Object System.Windows.Forms.Form
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$form.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
$form.TopMost = $true
$form.BackColor = [System.Drawing.Color]::Black
$form.ShowInTaskbar = $false

# ============================================================
# SHOW CREEPY IMAGE + DIAGONAL IMAGE TABS
# ============================================================

$tabImages = New-Object System.Collections.ArrayList

if (Test-Path $imgPath) {
    $img = [System.Drawing.Image]::FromFile($imgPath)
    $form.BackgroundImage = $img
    $form.BackgroundImageLayout = [System.Windows.Forms.ImageLayout]::Zoom
}

$form.Show()
$form.Refresh()

# Create small copies of jumpscare.jpg and place them on a diagonal.
if (Test-Path $imgPath) {
    for ($i = 0; $i -lt 9; $i++) {
        $pic = New-Object System.Windows.Forms.PictureBox
        $pic.Size = New-Object System.Drawing.Size(150,105)
        $pic.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
        $pic.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $pic.BackColor = [System.Drawing.Color]::Black
        $pic.Image = $img
        $form.Controls.Add($pic)
        $pic.BringToFront()
        [void]$tabImages.Add($pic)
    }
}

$form.Refresh()

# Image stays up for 10 seconds. The little image tabs drift down
# and to the right so they form a moving diagonal trail.
$timer = [System.Diagnostics.Stopwatch]::StartNew()
$diagonalStart = -180

while ($timer.Elapsed.TotalSeconds -lt 15) {
    [System.Windows.Forms.Application]::DoEvents()

    $step = [int](($timer.Elapsed.TotalMilliseconds / 55) % 1200)
    $width = $form.ClientSize.Width
    $height = $form.ClientSize.Height

    for ($i = 0; $i -lt $tabImages.Count; $i++) {
        $pic = $tabImages[$i]
        $offset = ($i * 145)
        $x = (($diagonalStart + $step + $offset) % ($width + 220)) - 110
        $y = (($diagonalStart + $step + $offset) % ($height + 180)) - 90
        $pic.Location = New-Object System.Drawing.Point([int]$x,[int]$y)
        $pic.BringToFront()
    }

    $form.Refresh()
    Start-Sleep -Milliseconds 20
}

# Remove the diagonal tabs before switching to the text screen.
foreach ($pic in $tabImages) {
    $form.Controls.Remove($pic)
    $pic.Dispose()
}
$tabImages.Clear()

# ============================================================
# SWITCH TO TEXT
# ============================================================

$form.BackgroundImage = $null
$form.BackColor = [System.Drawing.Color]::Black

$text = @"
YOUR COMPUTER HAS BEEN TOOKEN OVER BY

A̴̡̱̭̖͎̟͕͎̬͚͙̩̺̥̓͑̎́́͂̍͋̏̚͘͜Ś̸̢̛̳̹̮͙̬̮̟̰̞̫̐̈́̈́Ḑ̶̼͈͖͊͂̈́̚A̷̙̻͚̼͇̿͊͒̑͐̑̚͘͠W̷͓̟̘̘̤̐͐̾̃͊̀͂̌͆͛͐̃͘I̸̳͕̰̙̦͎̝͈̻̲̱̥͗͐̓̔̓͗̀̔͘̚̚͠͝ͅͅA̸̛̟̗̯͕̋̎̀̽̀̔̏̿͊͘͠A̴̛̞͉̽̔͊̀D̵̜̗͐̄͌̉̒̈́́͘A̵̢̤͙͇͓̗̮̝̞̖̐́̍̇́̒́̏͋͘͘̚ͅͅD̶̢̡̢̳͔̝̪̭̹̻̥͍͋̈̆͂̾̋͂̈́̓͘ͅA̵̧̡͉̗̗̠͓̟͙͎̭̭͒̓͗̈́̉͌͊̆͝͝͝ͅŞ̷͙͎͚̗̘̝̥̲̱͔͍̳̝̺̀̆̃̈́͑̌̒͐͝͝N̵̨̡̗̙̖̱͚̞̠͉͈̆̂͑̊͑.
"@

$label = New-Object System.Windows.Forms.Label
$label.Text = $text
$label.ForeColor = [System.Drawing.Color]::Red
$label.BackColor = [System.Drawing.Color]::Black
$label.Font = New-Object System.Drawing.Font(
    "Consolas",
    20,
    [System.Drawing.FontStyle]::Bold
)
$label.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
$label.AutoSize = $false
$label.Size = New-Object System.Drawing.Size(1100,350)

$form.Controls.Add($label)

# ============================================================
# RANDOM IMAGE TABS DURING TEXT
# ============================================================

# Keep these small and random so the red text remains visible.
$textTabs = New-Object System.Collections.ArrayList

if (Test-Path $imgPath) {
    for ($i = 0; $i -lt 7; $i++) {
        $pic = New-Object System.Windows.Forms.PictureBox
        $pic.Size = New-Object System.Drawing.Size(120,85)
        $pic.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
        $pic.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
        $pic.BackColor = [System.Drawing.Color]::Black
        $pic.Image = $img
        $form.Controls.Add($pic)
        $pic.BringToFront()
        [void]$textTabs.Add($pic)
    }
}

# ============================================================
# START ACTUAL CREEPY SOUND
# ============================================================

$player = New-Object System.Media.SoundPlayer
$player.SoundLocation = $wavPath

try {
    $player.Load()
    $player.PlayLooping()
}
catch {
    # Continue even if audio cannot be initialized
}

# ============================================================
# MOVE TEXT FOR 20 SECONDS
# ============================================================

$timer.Restart()
$random = New-Object System.Random

while ($timer.Elapsed.TotalSeconds -lt 20) {

    [System.Windows.Forms.Application]::DoEvents()

    $maxX = [Math]::Max(1, $form.ClientSize.Width - $label.Width)
    $maxY = [Math]::Max(1, $form.ClientSize.Height - $label.Height)

    $x = $random.Next(0, $maxX)
    $y = $random.Next(0, $maxY)

    $label.Location = New-Object System.Drawing.Point($x,$y)

    # Pop the little image tabs into random positions while the text moves.
    foreach ($pic in $textTabs) {
        $tabMaxX = [Math]::Max(1, $form.ClientSize.Width - $pic.Width)
        $tabMaxY = [Math]::Max(1, $form.ClientSize.Height - $pic.Height)
        $tabX = $random.Next(0, $tabMaxX)
        $tabY = $random.Next(0, $tabMaxY)
        $pic.Location = New-Object System.Drawing.Point($tabX,$tabY)
        $pic.BringToFront()
    }

    $form.Refresh()

    Start-Sleep -Milliseconds 100
}

# Remove the random image tabs before cleanup.
foreach ($pic in $textTabs) {
    $form.Controls.Remove($pic)
    $pic.Dispose()
}
$textTabs.Clear()

# ============================================================
# STOP SOUND AND RETURN TO DESKTOP
# ============================================================

try { $player.Stop() } catch {}
$form.Close()
$form.Dispose()

# Give the desktop a moment to appear.
Start-Sleep -Seconds 5

# Show a translucent red overlay for 5 seconds, then clear it for
# 5 seconds. Repeat the tint / normal cycle three times.
for ($cycle = 0; $cycle -lt 3; $cycle++) {
    $tintForm = New-Object System.Windows.Forms.Form
    $tintForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $tintForm.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $tintForm.StartPosition = [System.Windows.Forms.FormStartPosition]::Manual
    $tintForm.TopMost = $true
    $tintForm.ShowInTaskbar = $false
    $tintForm.BackColor = [System.Drawing.Color]::Red
    $tintForm.Opacity = 0.35
    $tintForm.Show()
    $tintForm.Refresh()

    $tintEnd = [DateTime]::UtcNow.AddSeconds(5)
    while ([DateTime]::UtcNow -lt $tintEnd) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 50
    }
    $tintForm.Close()
    $tintForm.Dispose()

    Start-Sleep -Seconds 5
}

# Final message: green for 3 seconds, then red for 2 seconds.
function Show-FinalMessage([string]$message, [System.Drawing.Color]$color, [int]$seconds) {
    $finalForm = New-Object System.Windows.Forms.Form
    $finalForm.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
    $finalForm.WindowState = [System.Windows.Forms.FormWindowState]::Maximized
    $finalForm.TopMost = $true
    $finalForm.BackColor = [System.Drawing.Color]::Black
    $finalForm.ShowInTaskbar = $false

    $finalLabel = New-Object System.Windows.Forms.Label
    $finalLabel.Dock = [System.Windows.Forms.DockStyle]::Fill
    $finalLabel.Text = $message
    $finalLabel.ForeColor = $color
    $finalLabel.BackColor = [System.Drawing.Color]::Black
    $finalLabel.Font = New-Object System.Drawing.Font("Consolas", 48, [System.Drawing.FontStyle]::Bold)
    $finalLabel.TextAlign = [System.Drawing.ContentAlignment]::MiddleCenter
    $finalForm.Controls.Add($finalLabel)

    $finalForm.Show()
    $finalForm.Refresh()
    $endTime = [DateTime]::UtcNow.AddSeconds($seconds)
    while ([DateTime]::UtcNow -lt $endTime) {
        [System.Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 50
    }
    $finalForm.Close()
    $finalForm.Dispose()
}

Show-FinalMessage "You're free..." ([System.Drawing.Color]::Lime) 3
Show-FinalMessage "FOR NOW." ([System.Drawing.Color]::Red) 2

# Wait three seconds after the final text disappears, then play the
# supplied MP3 from the same folder as this script.
Start-Sleep -Seconds 3
$audioPath = Join-Path $PSScriptRoot "laughcreepy.mp3"
if (Test-Path -LiteralPath $audioPath) {
    try {
        # Use Windows' built-in Multimedia Control Interface. Unlike the
        # Media Player COM object, this waits for playback to actually start.
        if (-not ("MciAudio" -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public static class MciAudio {
    [DllImport("winmm.dll", CharSet = CharSet.Auto)]
    public static extern int mciSendString(string command, System.Text.StringBuilder response, int length, IntPtr callback);
}
"@
        }

        $alias = "finalLaugh"
        $escapedPath = $audioPath.Replace('"', '""')
        $openResult = [MciAudio]::mciSendString("open `"$escapedPath`" type mpegvideo alias $alias", $null, 0, [IntPtr]::Zero)
        if ($openResult -eq 0) {
            [void][MciAudio]::mciSendString("play $alias", $null, 0, [IntPtr]::Zero)
            # Allow the decoder to initialize, then wait for the sound to finish.
            Start-Sleep -Milliseconds 500
            $mode = New-Object System.Text.StringBuilder 128
            do {
                Start-Sleep -Milliseconds 200
                $mode.Clear() | Out-Null
                [void][MciAudio]::mciSendString("status $alias mode", $mode, $mode.Capacity, [IntPtr]::Zero)
            } while ($mode.ToString() -eq "playing")
            [void][MciAudio]::mciSendString("close $alias", $null, 0, [IntPtr]::Zero)
        }
    } catch {
        # Continue cleanup if audio playback is unavailable.
    }
} else {
    Write-Warning "Audio file not found: $audioPath"
}

if ($img) { $img.Dispose() }
$player.Dispose()
Start-Sleep -Milliseconds 200

if (Test-Path $wavPath) {
    Remove-Item $wavPath -Force -ErrorAction SilentlyContinue
}

exit
