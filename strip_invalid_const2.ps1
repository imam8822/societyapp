$analyzeLog = "C:\Users\imam\source\repos\imam8822\societyapp\analyze_output.txt"
$errors = Get-Content $analyzeLog | Select-String "invalid_constant|non_constant_list_element"

foreach ($error in $errors) {
    if ($error -match "lib\\(.+?):(\d+):(\d+)") {
        $file = "C:\Users\imam\source\repos\imam8822\societyapp\lib\" + $matches[1]
        $lineNum = [int]$matches[2]
        
        if (Test-Path $file) {
            $lines = Get-Content $file
            $idx = $lineNum - 1
            
            # Check up to 5 lines above
            for ($i = 0; $i -le 5; $i++) {
                $target = $idx - $i
                if ($target -ge 0 -and $lines[$target] -match "const ") {
                    $lines[$target] = $lines[$target] -replace "\bconst\s+", ""
                    break
                }
            }
            
            Set-Content -Path $file -Value $lines
        }
    }
}
Write-Output "Done"
