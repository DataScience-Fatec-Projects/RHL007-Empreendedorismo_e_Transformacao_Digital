# -*- coding: utf-8 -*-
"""Converte o Markdown restrito de um capítulo em blocos JSON para inserção no Word.

Regras do Markdown aceito (uma linha por parágrafo):
  ## Título de capítulo (Heading 1)   ### Seção (Heading 2)   #### Subseção (Heading 3)
  **Texto**  (linha inteira em negrito) -> parágrafo em negrito (títulos de bloco)
  - item     -> marcador
  Quadro N – título  -> legenda de quadro (linha acima da tabela)
  Figura N – título  -> legenda de figura (linha acima da imagem)
  ![descrição](caminho.png) -> imagem (caminho relativo à pasta do repositório)
  | a | b |  -> tabela (a linha |---|---| é ignorada)
  Fonte: ... -> fonte do quadro ou da figura
  # ...      -> comentário (ignorado)
  demais linhas -> parágrafo normal; **negrito** inline é preservado

Uso: python md_para_blocos.py entrada.md saida.json
     python md_para_blocos.py --referencias referencias.md saida.json
       (modo referências: cada parágrafo antes da linha "---" vira uma referência ABNT,
        precedida do título "REFERÊNCIAS"; o cabeçalho "# ..." e a nota inicial são ignorados)
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
        elif re.match(r"^(Quadro|Figura) \d+ [–-] ", s):
            blocks.append({"t": "caption", "text": s})
        elif re.fullmatch(r"!\[[^\]]*\]\([^)]+\)", s):
            blocks.append({"t": "img", "path": re.search(r"\(([^)]+)\)", s).group(1)})
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


def referencias(src, dst):
    """Gera blocos da seção REFERÊNCIAS a partir de referencias.md (parágrafos antes de '---')."""
    texto = re.split(r"(?m)^---\s*$", open(src, encoding="utf-8").read())[0]
    blocks = [{"t": "h1", "text": "REFERÊNCIAS"}]
    for s in (l.strip() for l in texto.splitlines()):
        # ignora cabeçalho, nota inicial e linhas sem cara de referência (precisam ter um ano)
        if not s or s.startswith("#") or s.startswith("Ordem alfab") or not re.search(r"(19|20)\d\d", s):
            continue
        blocks.append({"t": "ref", "text": s})
    with open(dst, "w", encoding="utf-8") as f:
        json.dump(blocks, f, ensure_ascii=False, indent=1)
    print(f"{len(blocks) - 1} referências gravadas em {dst}")


if __name__ == "__main__":
    if sys.argv[1] == "--referencias":
        referencias(sys.argv[2], sys.argv[3])
    else:
        main(sys.argv[1], sys.argv[2])
