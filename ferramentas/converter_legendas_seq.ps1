<#
 Converte legendas "Quadro N - titulo" (estilo Legenda) em legendas reais do Word com campo SEQ Quadro,
 aponta a lista de quadros (campo TOC \c) para o rotulo "Quadro", renomeia o titulo da lista e atualiza
 Sumario, lista e campos. Uso unico ou sempre que uma legenda for criada sem SEQ.
 Uso: powershell -ExecutionPolicy Bypass -File ferramentas\converter_legendas_seq.ps1
 (arquivo propositalmente sem acentos; PowerShell 5.1 le .ps1 sem BOM como ANSI)
#>
param(
  [string]$Pasta = "C:\General\fatec\Trabalho de Empreendedorismo",
  [string]$PadraoDoc = "*CDADOS_DARWIN.doc",
  [string]$Rotulo = "Quadro",
  [string]$TituloListaAntigo = "LISTA DE TABELAS",
  [string]$TituloListaNovo = "LISTA DE QUADROS"
)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8
$doc = (Get-ChildItem (Join-Path $Pasta $PadraoDoc) | Select-Object -First 1).FullName
$bk = Join-Path $Pasta "backup"; New-Item -ItemType Directory -Force $bk | Out-Null
Copy-Item $doc (Join-Path $bk ([IO.Path]::GetFileNameWithoutExtension($doc) + "_" + (Get-Date -Format "yyyy-MM-dd_HHmm") + "_antes-seq.doc"))
Get-Process WINWORD -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq "" } | ForEach-Object { Stop-Process -Id $_.Id -Force }
$w = New-Object -ComObject Word.Application; $w.Visible = $false; $w.DisplayAlerts = 0
$d = $null
try {
  $d = $w.Documents.Open($doc)
  if ($d.ReadOnly) { throw "Documento aberto somente leitura (feche o Word e tente de novo)" }
  # 1) legendas -> campo SEQ
  $n = $d.Paragraphs.Count; $conv = 0
  for ($i = 1; $i -le $n; $i++) {
    $p = $d.Paragraphs.Item($i)
    if ($p.Range.Information(12)) { continue }
    $t = $p.Range.Text
    if ($t -match ('^' + $Rotulo + ' (\d+) ') -and $p.Range.Fields.Count -eq 0) {
      $start = $p.Range.Start + $Rotulo.Length + 1
      $r = $d.Range($start, $start + $matches[1].Length)
      $null = $d.Fields.Add($r, -1, ('SEQ ' + $Rotulo + ' \* ARABIC'), $false)
      $conv++
    }
  }
  "Legendas convertidas para SEQ ${Rotulo}: $conv"
  # 2) lista de quadros: campo TOC \c
  $tofs = $d.TablesOfFigures.Count
  if ($tofs -ge 1) {
    $fld = $d.TablesOfFigures.Item(1).Range.Fields.Item(1)
    $fld.Code.Text = ' TOC \h \z \c "' + $Rotulo + '" '
    "Campo da lista: [" + $fld.Code.Text + "]"
  } else { "AVISO: nenhuma lista (TOC \c) encontrada no documento" }
  # 3) titulo da lista
  for ($i = 1; $i -le $n; $i++) {
    $p = $d.Paragraphs.Item($i)
    if ($p.Range.Text.Trim() -eq $TituloListaAntigo) { $d.Range($p.Range.Start, $p.Range.End - 1).Text = $TituloListaNovo; "Titulo da lista renomeado para $TituloListaNovo"; break }
  }
  # 4) atualiza campos, lista e sumario
  $null = $d.Fields.Update()
  for ($k = 1; $k -le $d.TablesOfFigures.Count; $k++) { $null = $d.TablesOfFigures.Item($k).Update() }
  for ($k = 1; $k -le $d.TablesOfContents.Count; $k++) { $null = $d.TablesOfContents.Item($k).Update() }
  $d.Save()
  "--- lista resultante ---"
  ($d.TablesOfFigures.Item(1).Range.Text -split "`r") | Where-Object { $_.Trim() -ne "" } | ForEach-Object { "  " + $_.Trim() }
  "Salvo. Paginas: " + $d.ComputeStatistics(2)
} finally { if ($d) { $d.Close($false) }; $w.Quit(); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($w) | Out-Null }
