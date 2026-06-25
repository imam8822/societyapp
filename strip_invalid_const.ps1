$analyzeLog = "C:\Users\imam\source\repos\imam8822\societyapp\analyze_output.txt"
$errors = Get-Content $analyzeLog | Select-String "invalid_constant|non_constant_list_element"

foreach ($error in $errors) {
    # Extract file path and line number
    if ($error -match "lib\\(.+?):(\d+):(\d+)") {
        $file = "C:\Users\imam\source\repos\imam8822\societyapp\lib\" + $matches[1]
        $lineNum = [int]$matches[2]
        
        if (Test-Path $file) {
            $lines = Get-Content $file
            # Line number is 1-based, array is 0-based
            $idx = $lineNum - 1
            
            # Check the line and the previous line for 'const '
            if ($lines[$idx] -match "const ") {
                $lines[$idx] = $lines[$idx] -replace "\bconst\s+", ""
            }
            elseif ($idx -gt 0 -and $lines[$idx-1] -match "const ") {
                $lines[$idx-1] = $lines[$idx-1] -replace "\bconst\s+", ""
            }
            
            Set-Content -Path $file -Value $lines
            Write-Output "Fixed $file at line $lineNum"
        }
    }
}
