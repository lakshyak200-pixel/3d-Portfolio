$listener = New-Object System.Net.HttpListener
$listener.Prefixes.Add("http://localhost:8080/")
$listener.Start()
Write-Host "Listening on http://localhost:8080/"

try {
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        $url = $request.Url.LocalPath
        if ($url -eq "/") { $url = "/index.html" }
        
        $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
        $filePath = Join-Path $scriptDir $url.Replace("/", "\")
        
        if (Test-Path $filePath -PathType Leaf) {
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            switch ($ext) {
                ".html" { $response.ContentType = "text/html" }
                ".jpg" { $response.ContentType = "image/jpeg" }
                ".png" { $response.ContentType = "image/png" }
                ".css" { $response.ContentType = "text/css" }
                ".js" { $response.ContentType = "application/javascript" }
                default { $response.ContentType = "application/octet-stream" }
            }

            $content = [System.IO.File]::ReadAllBytes($filePath)
            $response.ContentLength64 = $content.Length
            
            try {
                $response.OutputStream.Write($content, 0, $content.Length)
            } catch {
                # Ignore errors caused by the browser disconnecting early (e.g. rapid reloads)
            }
        } else {
            $response.StatusCode = 404
        }
        
        try {
            $response.Close()
        } catch {}
    }
} finally {
    $listener.Stop()
}
