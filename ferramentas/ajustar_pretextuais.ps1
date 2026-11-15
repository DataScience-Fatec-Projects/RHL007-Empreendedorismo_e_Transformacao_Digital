<#
 Ajusta as paginas pre-textuais do .doc conforme a avaliacao da P1:
   1) titulo do trabalho na capa e na folha de rosto (estilo Titulo): lido do trecho em **negrito**
      da referencia em capitulos\00-Resumo.md (fonte unica do titulo);
   2) natureza do trabalho na folha de rosto com recuo esquerdo de 8 cm, justificada, espaco simples (NBR 14724);
   3) LISTA DE ILUSTRACOES: troca o "Nao ha" por um indice de figuras (legendas "Figura N - ...", campo SEQ Figura);
   4) atualiza campos, listas e sumario.
 Rodar depois de inserir os capitulos (para que as figuras ja existam). Faz backup antes.
 Uso: powershell -ExecutionPolicy Bypass -File ferramentas\ajustar_pretextuais.ps1
 (arquivo propositalmente sem acentos; PowerShell 5.1 le .ps1 sem BOM como ANSI)
#>
param(
  [string]$Pasta = (Split-Path $PSScriptRoot -Parent),
  [string]$PadraoDoc = "*CDADOS_DARWIN.doc",
  [string]$FonteTitulo = "capitulos\00-Resumo.md",
  [double]$RecuoNaturezaCm = 8
)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$doc = (Get-ChildItem (Join-Path $Pasta $PadraoDoc) | Select-Object -First 1).FullName
# ignora as linhas de comentario ("# ...") do Markdown
$md = (Get-Content -Encoding UTF8 (Join-Path $Pasta $FonteTitulo) | Where-Object { -not $_.StartsWith("#") }) -join "`n"
if ($md -notmatch '\*\*([^*]+)\*\*') { throw "Titulo em negrito nao encontrado em $FonteTitulo" }
$titulo = $matches[1].Trim()
"Titulo: $titulo"

$bk = Join-Path $Pasta "backup"; New-Item -ItemType Directory -Force $bk | Out-Null
Copy-Item $doc (Join-Path $bk ([IO.Path]::GetFileNameWithoutExtension($doc) + "_" + (Get-Date -Format "yyyy-MM-dd_HHmm") + "_antes-pretextuais.doc"))
Get-Process WINWORD -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq "" } | ForEach-Object { Stop-Process -Id $_.Id -Force }

$w = New-Object -ComObject Word.Application; $w.Visible = $false; $w.DisplayAlerts = 0
$d = $null
try {
  $d = $w.Documents.Open($doc)
  if ($d.ReadOnly) { throw "Documento aberto somente leitura (feche o Word e tente de novo)" }

  # limite das paginas pre-textuais: primeiro Titulo 1 (INTRODUCAO)
  $n = $d.Paragraphs.Count; $fim = $n
  for ($i = 1; $i -le $n; $i++) { if ($d.Paragraphs.Item($i).OutlineLevel -eq 1) { $fim = $i - 1; break } }

  # capa e folha de rosto terminam antes do paragrafo RESUMO (SUMARIO e outros titulos de pagina tambem usam o estilo Titulo)
  $fimRosto = $fim
  for ($i = 1; $i -le $fim; $i++) { if ($d.Paragraphs.Item($i).Range.Text.Trim() -eq "RESUMO") { $fimRosto = $i - 1; break } }

  $nTit = 0
  for ($i = 1; $i -le $fim; $i++) {
    $p = $d.Paragraphs.Item($i); $t = $p.Range.Text.Trim()
    # 1) titulo: paragrafos com estilo de titulo (wdStyleTitle) e texto, apenas na capa e na folha de rosto
    if ($i -le $fimRosto -and $t -ne "" -and $p.Style.NameLocal -eq $d.Styles.Item(-63).NameLocal) {
      $d.Range($p.Range.Start, $p.Range.End - 1).Text = $titulo; $nTit++
    }
    # 2) natureza do trabalho
    if ($t.StartsWith("Trabalho apresentado")) {
      $p.LeftIndent = $w.CentimetersToPoints($RecuoNaturezaCm); $p.FirstLineIndent = 0; $p.RightIndent = 0
      $p.Alignment = 3; $p.LineSpacingRule = 0
      "Natureza do trabalho: recuo de $RecuoNaturezaCm cm"
    }
  }
  "Titulos substituidos: $nTit"

  # 3) lista de ilustracoes com indice de figuras; cada lista pre-textual comeca em pagina nova
  for ($i = 1; $i -le $fim; $i++) {
    $p = $d.Paragraphs.Item($i); $t = $p.Range.Text.Trim().ToUpperInvariant()
    # so a LISTA DE ILUSTRACOES nao tem quebra manual no modelo; LISTA DE QUADROS e SUMARIO ja tem
    # (PageBreakBefore nelas geraria pagina em branco)
    if ($t.StartsWith("LISTA DE ILUSTRA")) { $p.PageBreakBefore = -1; $p.KeepWithNext = -1 }
    elseif ($t.StartsWith("LISTA DE ") -or ($t.StartsWith("SUM") -and $t.Length -le 8)) { $p.PageBreakBefore = 0 }
  }
  $temFig = $false
  for ($k = 1; $k -le $d.TablesOfFigures.Count; $k++) { if ($d.TablesOfFigures.Item($k).Caption -eq "Figura") { $temFig = $true } }
  if (-not $temFig) {
    $iLista = 0
    for ($i = 1; $i -le $fim; $i++) { if ($d.Paragraphs.Item($i).Range.Text.Trim().ToUpperInvariant().StartsWith("LISTA DE ILUSTRA")) { $iLista = $i; break } }
    if ($iLista -gt 0) {
      $iNada = 0
      for ($i = $iLista + 1; $i -le $fim; $i++) { $t = $d.Paragraphs.Item($i).Range.Text.Trim(); if ($t -ne "") { if ($t -like "N*o h*") { $iNada = $i }; break } }
      if ($iNada -gt 0) {
        $p = $d.Paragraphs.Item($iNada)
        $r = $d.Range($p.Range.Start, $p.Range.End - 1); $r.Text = ""
        $null = $d.TablesOfFigures.Add($r, "Figura", $true)
        "Lista de ilustracoes: indice de figuras inserido"
      } else { "Lista de ilustracoes: paragrafo 'Nao ha' nao encontrado; nada alterado" }
    }
  } else { "Lista de ilustracoes: indice de figuras ja existe" }

  # 4) atualiza tudo
  try { $null = $d.Fields.Update() } catch {}
  for ($k = 1; $k -le $d.TablesOfFigures.Count; $k++) { try { $null = $d.TablesOfFigures.Item($k).Update() } catch {} }
  for ($k = 1; $k -le $d.TablesOfContents.Count; $k++) { $null = $d.TablesOfContents.Item($k).Update() }
  $d.Save()
  "Salvo. Paginas: " + $d.ComputeStatistics(2)
} finally { if ($d) { $d.Close($false) }; $w.Quit(); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($w) | Out-Null }
