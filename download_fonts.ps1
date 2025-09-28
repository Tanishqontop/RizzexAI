$fonts = @(
    @{
        "url" = "https://github.com/google/fonts/raw/main/ofl/playfairdisplay/static/PlayfairDisplay-Regular.ttf"
        "output" = "assets/fonts/PlayfairDisplay-Regular.ttf"
    },
    @{
        "url" = "https://github.com/google/fonts/raw/main/ofl/playfairdisplay/static/PlayfairDisplay-Bold.ttf"
        "output" = "assets/fonts/PlayfairDisplay-Bold.ttf"
    }
)

foreach ($font in $fonts) {
    Invoke-WebRequest -Uri $font.url -OutFile $font.output
    Write-Host "Downloaded $($font.output)"
} 