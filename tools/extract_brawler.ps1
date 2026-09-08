Add-Type -AssemblyName System.Drawing

$source = 'C:\Users\petsk\AppData\Local\Temp\codex-clipboard-466a6a70-b870-4565-b5f4-c8aa8dcf6e84.png'
$destination = 'C:\Users\petsk\Documents\ChatGPT\GoDot Project\assets\enemies\brawler'
New-Item -ItemType Directory -Force -Path $destination | Out-Null

$sheet = [System.Drawing.Bitmap]::FromFile($source)
$rows = @{
    idle = 368
    walk = 441
    jab = 513
    cross = 585
    hit = 657
    guard = 730
    hurt = 802
    ko = 875
}

foreach ($entry in $rows.GetEnumerator()) {
    $frame = New-Object System.Drawing.Bitmap 70,70,([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($frame)
    $graphics.DrawImage($sheet, [System.Drawing.Rectangle]::new(0,0,70,70), [System.Drawing.Rectangle]::new(55,$entry.Value,70,70), [System.Drawing.GraphicsUnit]::Pixel)
    $graphics.Dispose()

    # Remove only the cream background connected to the crop border. This keeps
    # light pixels inside the character (wraps, shoes and highlights) intact.
    $queue = New-Object System.Collections.Generic.Queue[System.Drawing.Point]
    $seen = New-Object 'bool[,]' 70,70
    for ($x = 0; $x -lt 70; $x++) {
        $queue.Enqueue([System.Drawing.Point]::new($x,0))
        $queue.Enqueue([System.Drawing.Point]::new($x,69))
    }
    for ($y = 1; $y -lt 69; $y++) {
        $queue.Enqueue([System.Drawing.Point]::new(0,$y))
        $queue.Enqueue([System.Drawing.Point]::new(69,$y))
    }
    while ($queue.Count -gt 0) {
        $point = $queue.Dequeue()
        if ($point.X -lt 0 -or $point.X -ge 70 -or $point.Y -lt 0 -or $point.Y -ge 70 -or $seen[$point.X,$point.Y]) { continue }
        $seen[$point.X,$point.Y] = $true
        $pixel = $frame.GetPixel($point.X,$point.Y)
        $distance = [Math]::Abs($pixel.R - 242) + [Math]::Abs($pixel.G - 237) + [Math]::Abs($pixel.B - 220)
        if ($distance -gt 72) { continue }
        $frame.SetPixel($point.X,$point.Y,[System.Drawing.Color]::FromArgb(0,$pixel.R,$pixel.G,$pixel.B))
        $queue.Enqueue([System.Drawing.Point]::new($point.X + 1,$point.Y))
        $queue.Enqueue([System.Drawing.Point]::new($point.X - 1,$point.Y))
        $queue.Enqueue([System.Drawing.Point]::new($point.X,$point.Y + 1))
        $queue.Enqueue([System.Drawing.Point]::new($point.X,$point.Y - 1))
    }
    $frame.Save((Join-Path $destination ($entry.Name + '.png')), [System.Drawing.Imaging.ImageFormat]::Png)
    $frame.Dispose()
}
$sheet.Dispose()
