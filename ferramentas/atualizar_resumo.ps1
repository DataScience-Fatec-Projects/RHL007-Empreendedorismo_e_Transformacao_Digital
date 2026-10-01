<#
 Aplica o conteudo de capitulos\00-Resumo.md nas paginas pre-textuais do .doc:
   bloco 1 -> paragrafo de referencia imediatamente acima do titulo RESUMO ({{FOLHAS}} = n. de paginas; **x** = negrito)
   bloco 2 -> primeiro paragrafo apos o titulo RESUMO (texto do resumo)
   bloco 3 -> paragrafo "Palavras-chave: ..." logo apos o resumo (criado se nao existir)
 O ABSTRACT nao e alterado. Faz backup antes. Pode ser executado varias vezes.
 Uso: powershell -ExecutionPolicy Bypass -File ferramentas\atualizar_resumo.ps1
 (arquivo propositalmente sem acentos; PowerShell 5.1 le .ps1 sem BOM como ANSI)
#>
param(
  [string]$Pasta = "C:\General\fatec\Trabalho de Empreendedorismo",
  [string]$PadraoDoc = "*CDADOS_DARWIN.doc",
  [string]$Fonte = "capitulos\00-Resumo.md",
  [string]$TituloResumo = "RESUMO"
)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$doc = (Get-ChildItem (Join-Path $Pasta $PadraoDoc) | Select-Object -First 1).FullName
$md = Get-Content -Raw -Encoding UTF8 (Join-Path $Pasta $Fonte)
$blocos = @()
foreach ($b in ($md -replace "`r`n", "`n") -split "`n\s*`n") {
  $t = $b.Trim()
  if ($t -eq "" -or $t.StartsWith("# ")) { continue }
  $blocos += ($t -replace "`n", " ")
}
if ($blocos.Count -lt 3) { throw "Esperava 3 blocos (referencia, resumo, palavras-chave); achei $($blocos.Count)" }
$refTxt = $blocos[0]; $resumoTxt = $blocos[1]; $kwTxt = $blocos[2]

$bk = Join-Path $Pasta "backup"; New-Item -ItemType Directory -Force $bk | Out-Null
Copy-Item $doc (Join-Path $bk ([IO.Path]::GetFileNameWithoutExtension($doc) + "_" + (Get-Date -Format "yyyy-MM-dd_HHmm") + "_antes-resumo.doc"))
Get-Process WINWORD -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq "" } | ForEach-Object { Stop-Process -Id $_.Id -Force }

function Set-ParaText($d, $p, $text) { $d.Range($p.Range.Start, $p.Range.End - 1).Text = $text }

$w = New-Object -ComObject Word.Application; $w.Visible = $false; $w.DisplayAlerts = 0
$d = $null
try {
  $d = $w.Documents.Open($doc)
  if ($d.ReadOnly) { throw "Documento aberto somente leitura (feche o Word e tente de novo)" }
  $n = $d.Paragraphs.Count
  $iTitulo = 0
  for ($i = 1; $i -le $n; $i++) { if ($d.Paragraphs.Item($i).Range.Text.Trim() -eq $TituloResumo) { $iTitulo = $i; break } }
  if ($iTitulo -eq 0) { throw "Titulo $TituloResumo nao encontrado" }
  # referencia: ultimo paragrafo nao vazio antes do titulo
  $iRef = 0; for ($i = $iTitulo - 1; $i -ge 1; $i--) { if ($d.Paragraphs.Item($i).Range.Text.Trim() -ne "") { $iRef = $i; break } }
  # resumo: primeiro paragrafo nao vazio depois do titulo
  $iRes = 0; for ($i = $iTitulo + 1; $i -le $n; $i++) { if ($d.Paragraphs.Item($i).Range.Text.Trim() -ne "") { $iRes = $i; break } }
  if ($iRef -eq 0 -or $iRes -eq 0) { throw "Nao achei os paragrafos de referencia/resumo (ref=$iRef res=$iRes)" }

  # 1) referencia com numero de folhas e titulo em negrito
  $folhas = $d.ComputeStatistics(2)
  $refPlain = $refTxt.Replace("{{FOLHAS}}", [string]$folhas)
  $boldStart = $refPlain.IndexOf("**"); $boldText = ""
  if ($boldStart -ge 0) {
    $boldEnd = $refPlain.IndexOf("**", $boldStart + 2)
    $boldText = $refPlain.Substring($boldStart + 2, $boldEnd - $boldStart - 2)
    $refPlain = $refPlain.Remove($boldStart, $boldEnd - $boldStart + 2).Insert($boldStart, $boldText)
  }
  $pRef = $d.Paragraphs.Item($iRef)
  Set-ParaText $d $pRef $refPlain
  $pRef = $d.Paragraphs.Item($iRef)
  $pRef.Range.Font.Bold = 0
  if ($boldText -ne "") { $d.Range($pRef.Range.Start + $boldStart, $pRef.Range.Start + $boldStart + $boldText.Length).Font.Bold = 1 }
  "Referencia atualizada ($folhas f.)"

  # 2) resumo
  $pRes = $d.Paragraphs.Item($iRes)
  Set-ParaText $d $pRes $resumoTxt
  $pRes = $d.Paragraphs.Item($iRes)
  $pRes.Range.Font.Bold = 0; $pRes.Range.Font.Italic = 0
  $pRes.Alignment = 3; $pRes.FirstLineIndent = 0
  "Resumo atualizado ($($resumoTxt.Split(' ').Count) palavras)"

  # 3) palavras-chave: proximo paragrafo nao vazio; se nao for 'Palavras-chave', cria (linha em branco + paragrafo)
  $iNext = 0; for ($i = $iRes + 1; $i -le $d.Paragraphs.Count; $i++) { if ($d.Paragraphs.Item($i).Range.Text.Trim() -ne "") { $iNext = $i; break } }
  $pNext = $d.Paragraphs.Item($iNext)
  if ($pNext.Range.Text.Trim().StartsWith("Palavras-chave")) {
    Set-ParaText $d $pNext $kwTxt
    "Palavras-chave atualizadas"
  } else {
    $pRes.Range.InsertParagraphAfter()
    $pBlank = $d.Paragraphs.Item($iRes + 1)
    $pBlank.Range.InsertParagraphAfter()
    $pKw = $d.Paragraphs.Item($iRes + 2)
    $d.Range($pKw.Range.Start, $pKw.Range.Start).Text = $kwTxt
    $pKw = $d.Paragraphs.Item($iRes + 2)
    $pKw.Range.Font.Bold = 0; $pKw.Alignment = 3; $pKw.FirstLineIndent = 0
    "Palavras-chave inseridas"
  }
  # negrito apenas no rotulo "Palavras-chave:"
  $iKw = 0; for ($i = $iRes + 1; $i -le $d.Paragraphs.Count; $i++) { if ($d.Paragraphs.Item($i).Range.Text.Trim().StartsWith("Palavras-chave")) { $iKw = $i; break } }
  if ($iKw -gt 0) { $pk = $d.Paragraphs.Item($iKw); $d.Range($pk.Range.Start, $pk.Range.Start + 15).Font.Bold = 1 }

  try { $null = $d.Fields.Update() } catch {}
  for ($k = 1; $k -le $d.TablesOfContents.Count; $k++) { $null = $d.TablesOfContents.Item($k).Update() }
  $d.Save()
  "Salvo. Paginas: " + $d.ComputeStatistics(2)
} finally { if ($d) { $d.Close($false) }; $w.Quit(); [System.Runtime.InteropServices.Marshal]::ReleaseComObject($w) | Out-Null }
