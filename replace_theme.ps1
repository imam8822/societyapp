$directory = "C:\Users\imam\source\repos\imam8822\societyapp\lib"
$replacements = @{
    "AppTheme\.bgGrey" = "context.colors.bgGrey"
    "AppTheme\.primaryLight" = "context.colors.primaryLight"
    "AppTheme\.primary" = "context.colors.primary"
    "AppTheme\.accent" = "context.colors.accent"
    "AppTheme\.warning" = "context.colors.warning"
    "AppTheme\.error" = "context.colors.error"
    "AppTheme\.textDark" = "context.colors.textDark"
    "AppTheme\.textGrey" = "context.colors.textGrey"
    "AppTheme\.white" = "context.colors.surfaceWhite"
    "AppTheme\.divider" = "context.colors.divider"
    "AppTheme\.cardShadow" = "context.colors.cardShadow"
}

Get-ChildItem -Path $directory -Recurse -Filter "*.dart" | Where-Object { $_.Name -ne "constants.dart" -and $_.Name -ne "theme_provider.dart" } | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content -Path $file -Raw
    $original = $content

    foreach ($key in $replacements.Keys) {
        $content = [System.Text.RegularExpressions.Regex]::Replace($content, $key, $replacements[$key])
    }

    if ($original -ne $content) {
        Set-Content -Path $file -Value $content -NoNewline
        Write-Output "Updated: $file"
    }
}
Write-Output "Done replacing."
