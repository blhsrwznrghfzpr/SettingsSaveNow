# Optional Windows-only regeneration of the geometric package icon.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$bitmap = New-Object Drawing.Bitmap(256, 256)
$graphics = [Drawing.Graphics]::FromImage($bitmap)
$graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
$background = [Drawing.ColorTranslator]::FromHtml('#111C30')
$paper = New-Object Drawing.SolidBrush([Drawing.ColorTranslator]::FromHtml('#E7F1FF'))
$dark = New-Object Drawing.SolidBrush($background)
$accent = New-Object Drawing.SolidBrush([Drawing.ColorTranslator]::FromHtml('#38DEB5'))
$pen = New-Object Drawing.Pen($background, 9)
$pen.StartCap = [Drawing.Drawing2D.LineCap]::Round
$pen.EndCap = [Drawing.Drawing2D.LineCap]::Round
try {
    $graphics.Clear($background)
    $points = [Drawing.Point[]]@(
        [Drawing.Point]::new(52, 40), [Drawing.Point]::new(165, 40),
        [Drawing.Point]::new(204, 79), [Drawing.Point]::new(204, 210),
        [Drawing.Point]::new(52, 210)
    )
    $graphics.FillPolygon($paper, $points)
    $graphics.FillRectangle($dark, 80, 40, 68, 59)
    $graphics.FillRectangle($accent, 119, 49, 19, 39)
    $graphics.FillRectangle($dark, 73, 124, 108, 67)
    $graphics.FillRectangle($paper, 86, 137, 67, 6)
    $graphics.FillRectangle($paper, 86, 153, 48, 6)
    $graphics.FillEllipse($dark, 145, 149, 87, 87)
    $graphics.FillEllipse($accent, 151, 155, 75, 75)
    $graphics.DrawLines($pen, [Drawing.Point[]]@(
        [Drawing.Point]::new(168, 192), [Drawing.Point]::new(183, 207),
        [Drawing.Point]::new(210, 179)
    ))
    $bitmap.Save((Join-Path (Split-Path $PSScriptRoot -Parent) 'icon.png'), [Drawing.Imaging.ImageFormat]::Png)
} finally {
    $pen.Dispose()
    $accent.Dispose()
    $dark.Dispose()
    $paper.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}
