# RHL007 – Empreendedorismo e Transformação Digital – Empresa Darwin

Trabalho da disciplina **Empreendedorismo** (3º semestre, CST em Ciência de Dados, FATEC Jundiaí "Deputado Ary Fossen"), orientado pela Profª. Ma. Jucelaine Lopes de Oliveira.

**Título:** EMPREENDEDORISMO: Formalização do Processo de Criação e Gestão da Empresa Darwin

**Grupo:** Andressa Santos Silva · Jean Pablo de Souza de França · Rafael Soares de Albuquerque · Wellington Júnior Torres de Melo

## A empresa

**Darwin** é uma plataforma SaaS de previsão de demanda e reposição de estoque para redes regionais de supermercados (5 a 50 lojas) do Estado de São Paulo. Ela transforma os dados de venda que o varejista já possui no ERP em previsões diárias por item e loja e em pedidos sugeridos, com o objetivo de reduzir ruptura e perdas. Modelo de negócio híbrido: assinatura por loja mais onboarding pago.

O resumo das decisões do grupo está em [`resumo-para-o-grupo.md`](resumo-para-o-grupo.md). O estado completo do trabalho (decisões, premissas numéricas, status e pendências) está em [`PROGRESSO.md`](PROGRESSO.md).

## Estrutura do repositório

| Caminho | Conteúdo |
|---|---|
| `Projeto para Avaliação_Empreendedorismo_CDADOS_DARWIN.doc` | Documento oficial entregável, no modelo da professora |
| `PROGRESSO.md` | Fonte de verdade: decisões, premissas, status por capítulo, pendências e histórico |
| `resumo-para-o-grupo.md` | Resumo executivo das decisões e do método de trabalho |
| `referencias.md` | Referências em formato ABNT NBR 6023, com URL e data de acesso |
| `capitulos/01-Analise-de-Mercado.md` | Texto-fonte do Capítulo 1 |
| `capitulos/02-Produto-e-Proposta-de-Valor.md` | Texto-fonte do Capítulo 2 |
| `ferramentas/md_para_blocos.py` | Converte um capítulo em Markdown para blocos JSON |
| `ferramentas/inserir_capitulo_word.ps1` | Substitui um capítulo dentro do `.doc` pelos blocos, mantendo estilos, numeração e Sumário |

## Como trabalhamos

1. Cada capítulo é escrito em Markdown na pasta `capitulos/` (uma linha por parágrafo, tabelas em formato pipe, legendas `Quadro N – ...` e `Fonte: ...`).
2. O texto é inserido no `.doc` pelo script, que faz backup, apaga o conteúdo antigo do capítulo, insere o novo com os estilos do modelo e atualiza o Sumário.
3. Decisões e números ficam em `PROGRESSO.md`; qualquer mudança começa por lá.
4. Pendências e decisões em aberto são tratadas como **issues** deste repositório. O quadro Kanban [Darwin – Entrega do Capítulo 2](https://github.com/orgs/DataScience-Fatec-Projects/projects/2) separa o que bloqueia a próxima entrega ("Pronto para fazer") do que ainda precisa de refinamento ("A refinar").

### Regerar um capítulo no Word (Windows, com Microsoft Word instalado)

```powershell
cd "<pasta do repositório>"
# Capítulo 1
python ferramentas\md_para_blocos.py capitulos\01-Analise-de-Mercado.md capitulos\01-blocos.json
powershell -ExecutionPolicy Bypass -File ferramentas\inserir_capitulo_word.ps1
# Capítulo 2
python ferramentas\md_para_blocos.py capitulos\02-Produto-e-Proposta-de-Valor.md capitulos\02-blocos.json
powershell -ExecutionPolicy Bypass -File ferramentas\inserir_capitulo_word.ps1 -Blocos "capitulos\02-blocos.json" -InicioTitulo "O PRODUTO DE DADOS" -FimTitulo "OPERA"
```

Feche o Word antes de rodar. O script aceita `-Pasta` para apontar outra pasta e `-PadraoDoc` para outro nome de arquivo.

## Regras de edição

- Edite o `.md` e regere o Word. Se precisar editar direto no `.doc`, avise o grupo, porque a próxima regeração do capítulo sobrescreve o texto daquele capítulo.
- Não edite o modelo original da professora (`..._MODELO.doc`, mantido fora do repositório).
- Toda afirmação numérica precisa de fonte em `referencias.md`.

## Status

| Parte | Status |
|---|---|
| Capítulo 1 – Análise de Mercado (Quadros 1–7) | Rascunho v1 pronto |
| Capítulo 2 – Produto e PUV (Quadros 8–11) | Rascunho v1 pronto |
| Introdução | Próximo |
| Capítulos 3, 4 e 5; Resumo, Abstract, listas e referências finais | Pendentes |
