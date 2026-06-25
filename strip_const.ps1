$directory = "C:\Users\imam\source\repos\imam8822\societyapp\lib"
$pattern = "\bconst\s+(Icon|Text|Padding|Center|SizedBox|BoxDecoration|TextStyle|Border|BorderRadius|EdgeInsets|Color|Row|Column|Container|Align|Positioned|Expanded|Flexible|Divider|WidgetStateProperty|IconThemeData|NavigationBarThemeData|CircularProgressIndicator)\b"

Get-ChildItem -Path $directory -Recurse -Filter "*.dart" | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content -Path $file -Raw
    $original = $content

    $content = [System.Text.RegularExpressions.Regex]::Replace($content, $pattern, '$1')

    if ($original -ne $content) {
        Set-Content -Path $file -Value $content -NoNewline
        Write-Output "Stripped const from: $file"
    }
}
Write-Output "Done stripping const."
