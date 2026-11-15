<#
 Substitui o conteudo do Capitulo 1 dentro do .doc pelos blocos gerados a partir do Markdown.
 (arquivo propositalmente sem acentos: PowerShell 5.1 le .ps1 sem BOM como ANSI)

 - Mantem o paragrafo de titulo do capitulo (Titulo 1, numerado automaticamente) e tudo antes/depois.
 - Apaga do paragrafo seguinte ao titulo ate o paragrafo anterior ao proximo Titulo 1 (capitulo 2).
 - Insere os blocos com estilos nativos do modelo: Titulo 1/2/3 (numeracao automatica), Normal,
   Com marcadores, Legenda (para "Quadro N - ..." e "Fonte: ...") e tabelas com grade.
 - Atualiza o Sumario e salva. Faz backup antes.

 Uso: powershell -ExecutionPolicy Bypass -File ferramentas\inserir_capitulo_word.ps1 [-DigitarNumeros]
#>
param(
  [string]$Pasta = (Split-Path $PSScriptRoot -Parent),   # raiz do repositorio
  [string]$PadraoDoc = "*CDADOS_DARWIN.doc",
  [string]$Blocos = "capitulos\01-blocos.json",
  [string]$InicioTitulo = "LISE DE MERCADO",      # trecho (sem acento) do titulo do capitulo 1
  [string]$FimTitulo = "O PRODUTO DE DADOS",       # inicio do titulo do capitulo seguinte (maiusculas); "" = ate o fim do documento
  [switch]$DigitarNumeros,                         # use apenas se os estilos de titulo NAO tiverem numeracao automatica
  [switch]$SemBackup,
  [switch]$SemNumeroTitulo                         # remove a numeracao do titulo (elementos pos-textuais, ex.: REFERENCIAS)
)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [Text.Encoding]::UTF8

$doc = (Get-ChildItem (Join-Path $Pasta $PadraoDoc) | Select-Object -First 1).FullName
if (-not $doc) { throw "Documento nao encontrado em $Pasta ($PadraoDoc)" }
$blocosPath = Join-Path $Pasta $Blocos
$blocks = Get-Content -Raw -Encoding UTF8 $blocosPath | ConvertFrom-Json
"Documento: $doc"
"Blocos: $($blocks.Count)"

if (-not $SemBackup) {
  $bk = Join-Path $Pasta "backup"; New-Item -ItemType Directory -Force $bk | Out-Null
  $stamp = Get-Date -Format "yyyy-MM-dd_HHmm"
  Copy-Item $doc (Join-Path $bk ([IO.Path]::GetFileNameWithoutExtension($doc) + "_$stamp.doc"))
  "Backup em $bk"
}

# Encerra instancias ocultas do Word (orfas de automacao); janelas visiveis do usuario sao preservadas
Get-Process WINWORD -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq "" } | ForEach-Object { Stop-Process -Id $_.Id -Force }

# Constantes do Word
$wdStyleNormal = -1; $wdStyleHeading1 = -2; $wdStyleHeading2 = -3; $wdStyleHeading3 = -4
$wdStyleCaption = -35; $wdStyleListBullet = -49
$wdCollapseEnd = 0; $wdCollapseStart = 1; $wdAutoFitWindow = 2

$word = New-Object -ComObject Word.Application
$word.Visible = $false; $word.DisplayAlerts = 0
$d = $null
try {
  $d = $word.Documents.Open($doc)

  # Localiza o titulo do capitulo e o titulo do capitulo seguinte (OutlineLevel 1; ignora entradas do Sumario)
  $n = $d.Paragraphs.Count; $pStart = 0; $pEnd = 0
  for ($i = 1; $i -le $n; $i++) {
    $p = $d.Paragraphs.Item($i)
    if ($p.OutlineLevel -ne 1) { continue }
    $t = $p.Range.Text.Trim().ToUpperInvariant()
    if ($pStart -eq 0) { if ($t -like "*$InicioTitulo*") { $pStart = $i }; continue }
    if ($FimTitulo -ne "" -and $t.StartsWith($FimTitulo)) { $pEnd = $i; break }
  }
  if ($pStart -eq 0 -or ($pEnd -eq 0 -and $FimTitulo -ne "")) { throw "Nao achei os titulos (inicio=$pStart fim=$pEnd)" }
  "Titulo do capitulo no paragrafo $pStart; proximo capitulo no paragrafo $pEnd (0 = fim do documento)"

  # Padroniza o texto do titulo do capitulo com o do Markdown (sem o numero, que e automatico)
  if (@($blocks)[0].t -eq "h1") {
    $novo = ([string]@($blocks)[0].text -replace '^\d+(\.\d+)*\s+', '')
    $pt = $d.Paragraphs.Item($pStart)
    $d.Range($pt.Range.Start, $pt.Range.End - 1).Text = $novo
  }
  if ($SemNumeroTitulo) { $d.Paragraphs.Item($pStart).Range.ListFormat.RemoveNumbers() }

  # Apaga o conteudo antigo entre os dois titulos (ou ate o fim do documento)
  $delStart = $d.Paragraphs.Item($pStart + 1).Range.Start
  if ($pEnd -gt 0) { $delEnd = $d.Paragraphs.Item($pEnd).Range.Start } else { $delEnd = $d.Content.End - 1 }
  if ($delEnd -gt $delStart) { $d.Range($delStart, $delEnd).Delete() | Out-Null }
  "Conteudo antigo removido ($($delEnd - $delStart) caracteres)"

  # Cria um paragrafo vazio logo apos o titulo e posiciona a selecao nele
  $d.Paragraphs.Item($pStart).Range.InsertParagraphAfter()
  $sel = $word.Selection
  $d.Paragraphs.Item($pStart + 1).Range.Select()
  $sel.Collapse($wdCollapseStart)

  function Prep($styleId) {
    $sel.Style = $styleId
    $sel.ParagraphFormat.Reset()
    $sel.Font.Reset()
    # remove numeracao herdada apenas em texto corrido e legendas; titulos mantem a numeracao automatica do estilo
    if ($styleId -eq $wdStyleNormal -or $styleId -eq $wdStyleCaption) { try { $sel.Range.ListFormat.RemoveNumbers() } catch {} }
  }
  function TypeInline($text) {
    # suporta **negrito** inline
    $parts = [string]$text -split '\*\*'
    for ($k = 0; $k -lt $parts.Count; $k++) {
      if ($parts[$k] -eq "") { continue }
      $sel.Font.Bold = [int]($k % 2 -eq 1)
      $sel.TypeText($parts[$k])
    }
    $sel.Font.Bold = 0
  }
  function StripNum($text) {
    if ($DigitarNumeros) { return [string]$text }
    return ([string]$text -replace '^\d+(\.\d+)*\s+', '')
  }

  $first = $true
  foreach ($b in $blocks) {
    if ($b.t -eq "h1" -and $first) { $first = $false; continue }   # o titulo do capitulo ja existe no documento
    $first = $false
    switch ($b.t) {
      "h1" { Prep $wdStyleHeading1; $sel.TypeText((StripNum $b.text)); $sel.TypeParagraph() }
      "h2" { Prep $wdStyleHeading2; $sel.TypeText((StripNum $b.text)); $sel.TypeParagraph() }
      "h3" { Prep $wdStyleHeading3; $sel.TypeText((StripNum $b.text)); $sel.TypeParagraph() }
      "pb" { Prep $wdStyleNormal; $sel.ParagraphFormat.FirstLineIndent = 0; $sel.ParagraphFormat.KeepWithNext = -1; $sel.Font.Bold = 1; $sel.TypeText([string]$b.text); $sel.Font.Bold = 0; $sel.TypeParagraph() }
      "p"  { Prep $wdStyleNormal; TypeInline $b.text; $sel.TypeParagraph() }
      "li" { Prep $wdStyleListBullet; TypeInline $b.text; $sel.TypeParagraph() }
      "caption" {
        # Legenda real do Word: "Quadro " (ou "Figura ") + campo SEQ + " - titulo" (entra na lista correspondente)
        Prep $wdStyleCaption; $sel.ParagraphFormat.KeepWithNext = -1
        $txt = [string]$b.text
        if ($txt -match '^(Quadro|Figura) \d+ (.+)$') {
          $rotulo = $matches[1]; $rest = $matches[2]
          $sel.TypeText("$rotulo ")
          $fld = $d.Fields.Add($sel.Range, -1, "SEQ $rotulo \* ARABIC", $false)
          $sel.SetRange($fld.Result.End + 1, $fld.Result.End + 1)
          $sel.TypeText(" " + $rest)
        } else { $sel.TypeText($txt) }
        $sel.TypeParagraph()
      }
      "source"  { Prep $wdStyleCaption; $sel.TypeText([string]$b.text); $sel.TypeParagraph() }
      "img" {
        # Figura centralizada, limitada a largura util da pagina, presa a legenda acima e a fonte abaixo
        Prep $wdStyleNormal
        $sel.ParagraphFormat.FirstLineIndent = 0; $sel.ParagraphFormat.Alignment = 1; $sel.ParagraphFormat.KeepWithNext = -1
        $img = Join-Path $Pasta ([string]$b.path)
        $shp = $sel.InlineShapes.AddPicture($img, $false, $true)
        $larg = $d.PageSetup.PageWidth - $d.PageSetup.LeftMargin - $d.PageSetup.RightMargin
        if ($shp.Width -gt $larg) { $prop = $larg / $shp.Width; $shp.Width = $larg; $shp.Height = $shp.Height * $prop }
        $sel.TypeParagraph()
      }
      "ref" {
        # Referencia ABNT NBR 6023: alinhada a esquerda, espaco simples, sem recuo, uma linha em branco entre itens
        Prep $wdStyleNormal
        $sel.ParagraphFormat.FirstLineIndent = 0; $sel.ParagraphFormat.LeftIndent = 0; $sel.ParagraphFormat.Alignment = 0
        $sel.ParagraphFormat.LineSpacingRule = 0; $sel.ParagraphFormat.SpaceBefore = 0; $sel.ParagraphFormat.SpaceAfter = 12
        TypeInline $b.text; $sel.TypeParagraph()
      }
      "table" {
        Prep $wdStyleNormal
        $rows = @($b.rows); $nr = $rows.Count; $nc = @($rows[0]).Count
        $tbl = $d.Tables.Add($sel.Range, $nr, $nc)
        $tbl.Borders.Enable = $true
        for ($r = 1; $r -le $nr; $r++) {
          $row = @($rows[$r - 1])
          for ($c = 1; $c -le $nc; $c++) {
            $v = ""; if ($c -le $row.Count) { $v = [string]$row[$c - 1] }
            $tbl.Cell($r, $c).Range.Text = $v
          }
        }
        $tbl.Range.Font.Size = 9
        $tbl.Range.ParagraphFormat.FirstLineIndent = 0
        $tbl.Range.ParagraphFormat.LeftIndent = 0
        $tbl.Range.ParagraphFormat.SpaceAfter = 0
        $tbl.Range.ParagraphFormat.SpaceBefore = 0
        $tbl.Range.ParagraphFormat.LineSpacingRule = 0
        $tbl.Range.ParagraphFormat.Alignment = 0
        $tbl.Rows.Item(1).Range.Font.Bold = 1
        $tbl.Rows.Item(1).Shading.BackgroundPatternColor = 14737632
        $tbl.Rows.Item(1).HeadingFormat = -1
        $tbl.AutoFitBehavior($wdAutoFitWindow)
        $after = $tbl.Range; $after.Collapse($wdCollapseEnd); $after.Select()
      }
      default { Prep $wdStyleNormal; TypeInline ([string]$b.text); $sel.TypeParagraph() }
    }
  }

  # Garante numeracao automatica (1.1, 1.2, 1.3.1...) nos titulos inseridos: copia o modelo de lista
  # dos primeiros titulos numerados de nivel 2 e 3 que existirem fora do capitulo inserido
  # (primeiro nos capitulos seguintes; se faltar algum nivel, nos anteriores, a partir do inicio).
  $n = $d.Paragraphs.Count; $pEnd2 = $n + 1
  for ($i = $pStart + 1; $i -le $n; $i++) { if ($d.Paragraphs.Item($i).OutlineLevel -eq 1) { $pEnd2 = $i; break } }
  $ref = @{}
  foreach ($faixa in @(@($pEnd2, $n), @(1, ($pStart - 1)))) {
    for ($i = $faixa[0]; $i -le $faixa[1]; $i++) {
      $p = $d.Paragraphs.Item($i); $ol = $p.OutlineLevel
      if (($ol -eq 2 -or $ol -eq 3) -and -not $ref.ContainsKey($ol) -and $p.Range.ListFormat.ListString -match '^\d') { $ref[$ol] = $p }
      if ($ref.Count -eq 2) { break }
    }
    if ($ref.Count -eq 2) { break }
  }
  $renum = 0
  for ($i = $pStart + 1; $i -lt $pEnd2; $i++) {
    $p = $d.Paragraphs.Item($i); $ol = $p.OutlineLevel
    if (($ol -eq 2 -or $ol -eq 3) -and $p.Range.ListFormat.ListString -eq "" -and $ref.ContainsKey($ol)) {
      $p.Range.ParagraphFormat.Reset()
      $p.Range.ListFormat.ApplyListTemplateWithLevel($ref[$ol].Range.ListFormat.ListTemplate, $true, 2, 2, $ref[$ol].Range.ListFormat.ListLevelNumber)
      $renum++
    }
  }
  "Titulos renumerados: $renum"

  # Atualiza campos (numeracao SEQ), lista de quadros e sumario(s)
  try { $d.Fields.Update() | Out-Null } catch {}
  for ($k = 1; $k -le $d.TablesOfFigures.Count; $k++) { try { $d.TablesOfFigures.Item($k).Update() | Out-Null } catch {} }
  for ($k = 1; $k -le $d.TablesOfContents.Count; $k++) { $d.TablesOfContents.Item($k).Update() | Out-Null }
  $d.Save()
  "Salvo: $doc  (paginas: $($d.ComputeStatistics(2)))"
} finally {
  if ($d) { $d.Close($false) }
  $word.Quit()
  [System.Runtime.InteropServices.Marshal]::ReleaseComObject($word) | Out-Null
}
