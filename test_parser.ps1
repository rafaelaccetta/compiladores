$passed = 0
$failed = 0

Write-Host ""
Write-Host "=== Casos VALIDOS (espera: saida sem 'Erro:') ===" -ForegroundColor Cyan

foreach ($f in Get-ChildItem examples/valid/*.rkt | Sort-Object Name) {
    $output = cabal run compiladores -v0 -- $f.FullName 2>&1
    $hasError = $output -match "^Erro:"
    if ($hasError) {
        Write-Host "  FALHOU  $($f.Name)" -ForegroundColor Red
        Write-Host "          $output"
        $failed++
    } else {
        Write-Host "  OK      $($f.Name)" -ForegroundColor Green
        $passed++
    }
}

Write-Host ""
Write-Host "=== Casos INVALIDOS (espera: linha comecando com 'Erro:') ===" -ForegroundColor Cyan

foreach ($f in Get-ChildItem examples/invalid/*.rkt | Sort-Object Name) {
    $output = cabal run compiladores -v0 -- $f.FullName 2>&1
    $hasError = $output -match "^Erro:"
    if ($hasError) {
        Write-Host "  OK      $($f.Name)  →  $($Matches[0])" -ForegroundColor Green
        $passed++
    } else {
        Write-Host "  FALHOU  $($f.Name)  (deveria dar erro, mas nao deu)" -ForegroundColor Red
        $failed++
    }
}

Write-Host ""
$total = $passed + $failed
Write-Host "Resultado: $passed/$total testes passaram" -ForegroundColor $(if ($failed -eq 0) { "Green" } else { "Yellow" })
if ($failed -gt 0) { exit 1 } else { exit 0 }
