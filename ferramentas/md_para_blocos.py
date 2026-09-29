# -*- coding: utf-8 -*-
"""Converte o Markdown restrito de um capítulo em blocos JSON para inserção no Word.

Regras do Markdown aceito (uma linha por parágrafo):
  ## Título de capítulo (Heading 1)   ### Seção (Heading 2)   #### Subseção (Heading 3)
  **Texto**  (linha inteira em negrito) -> parágrafo em negrito (títulos de bloco)
  - item     -> marcador
  Quadro N – título  -> legenda de quadro (linha acima da tabela)
  | a | b |  -> tabela (a linha |---|---| é ignorada)
  Fonte: ... -> fonte do quadro
  # ...      -> comentário (ignorado)
  demais linhas -> parágrafo normal; **negrito** inline é preservado

Uso: python md_para_blocos.py entrada.md saida.json
"""
import json
import re
import sys


def main(src, dst):
    lines = open(src, encoding="utf-8").read().splitlines()
    blocks, i = [], 0
    while i < len(lines):
        s = lines[i].strip()
        if not s or s.startswith("# ") or s.startswith("<!--"):
            i += 1
            continue
        if s.startswith("|"):
            rows = []
            while i < len(lines) and lines[i].strip().startswith("|"):
                cells = [c.strip() for c in lines[i].strip().strip("|").split("|")]
                if not all(re.fullmatch(r":?-{2,}:?", c) for c in cells):
                    rows.append(cells)
                i += 1
            blocks.append({"t": "table", "rows": rows})
            continue
        if s.startswith("#### "):
            blocks.append({"t": "h3", "text": s[5:].strip()})
        elif s.startswith("### "):
            blocks.append({"t": "h2", "text": s[4:].strip()})
        elif s.startswith("## "):
            blocks.append({"t": "h1", "text": s[3:].strip()})
        elif re.match(r"^Quadro \d+ [–-] ", s):
            blocks.append({"t": "caption", "text": s})
        elif s.startswith("Fonte:"):
            blocks.append({"t": "source", "text": s})
        elif s.startswith("- "):
            blocks.append({"t": "li", "text": s[2:].strip()})
        elif re.fullmatch(r"\*\*[^*]+\*\*", s):
            blocks.append({"t": "pb", "text": s.strip("*")})
        else:
            blocks.append({"t": "p", "text": s})
        i += 1
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(blocks, f, ensure_ascii=False, indent=1)
    kinds = {}
    for b in blocks:
        kinds[b["t"]] = kinds.get(b["t"], 0) + 1
    print(f"{len(blocks)} blocos gravados em {dst}: {kinds}")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
