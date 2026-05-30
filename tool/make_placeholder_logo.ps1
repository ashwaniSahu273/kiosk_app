Add-Type -AssemblyName System.Drawing
$size = 512
$bmp = New-Object System.Drawing.Bitmap($size, $size)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias

# Background: palos primary green
$bg = [System.Drawing.Color]::FromArgb(255, 46, 125, 50)
$g.Clear($bg)

# Rounded inner surface
$inner = [System.Drawing.Color]::FromArgb(255, 88, 186, 71)
$brush = New-Object System.Drawing.SolidBrush($inner)
$g.FillEllipse($brush, 96, 96, 320, 320)

# Letter K in the center
$fg = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
$textBrush = New-Object System.Drawing.SolidBrush($fg)
$font = New-Object System.Drawing.Font("Arial", 220, [System.Drawing.FontStyle]::Bold)
$fmt = New-Object System.Drawing.StringFormat
$fmt.Alignment = [System.Drawing.StringAlignment]::Center
$fmt.LineAlignment = [System.Drawing.StringAlignment]::Center
$rect = New-Object System.Drawing.RectangleF(0, 0, $size, $size)
$g.DrawString("K", $font, $textBrush, $rect, $fmt)

$g.Dispose()
$out = Join-Path $PSScriptRoot "..\assets\images\kiosk_default_logo.png"
$bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
Write-Output "Wrote $out"
