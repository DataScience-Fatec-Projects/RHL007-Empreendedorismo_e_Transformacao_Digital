# Darwin – Trabalho de Empreendedorismo – PROGRESSO

**Disciplina:** Empreendedorismo – 3º semestre – CST em Ciência de Dados – FATEC Jundiaí "Deputado Ary Fossen"
**Professora:** Profª. Ma. Jucelaine Lopes de Oliveira
**Integrantes:** Andressa Santos Silva; Jean Pablo de Souza de França; Rafael Soares de Albuquerque; Wellington Júnior Torres de Melo
**Título:** DARWIN: plataforma de previsão de demanda para supermercados regionais (alterado em 15/11/2026 por sugestão da professora na P1; antes: "EMPREENDEDORISMO: Formalização do Processo de Criação e Gestão da Empresa Darwin")
**Documento oficial:** `Projeto para Avaliação_Empreendedorismo_CDADOS_DARWIN.doc` (o arquivo `..._MODELO.doc` é o modelo original da professora, não editar)
**Repositório:** https://github.com/DataScience-Fatec-Projects/RHL007-Empreendedorismo_e_Transformacao_Digital (decisões e pendências em aberto ficam nas issues)
**Quadro de acompanhamento (GitHub Project):** https://github.com/orgs/DataScience-Fatec-Projects/projects/2 – visão Kanban por Status: coluna "Pronto para fazer" = o que bloqueia a entrega de 30/09 (revisão dos Capítulos 1 e 2); coluna "A refinar" = demais issues, a detalhar (responsável, escopo, prazo); campos Categoria e Prioridade em cada cartão

---

## 1. Decisões tomadas

| Data | Tema | Decisão | Observação |
|---|---|---|---|
| 13/09/2026 | Nome da empresa | **Darwin** | Metáfora de adaptação contínua (modelos que se retreinam). Verificar colidência de marca no INPI. |
| 13/09/2026 | Segmento | **Varejo** – varejo alimentar (supermercados) | Escolha do grupo. |
| 13/09/2026 | Solução (produto de dados) | **Previsão de demanda e reposição de estoque** por item, loja e dia, com pedido sugerido | Problema mensurável: ruptura ~11% e perdas ~1,5% do faturamento. |
| 13/09/2026 | Modelo de negócio | **Híbrido: SaaS + onboarding pago** | Assinatura mensal por loja + serviço de implantação/treinamento. |
| 13/09/2026 | Nicho (ICP) | **Supermercados regionais de médio porte**: redes de 5 a 50 lojas, faturamento R$ 100 mi a R$ 2 bi/ano, com ERP, sem equipe de dados | Exclui independentes (<5 lojas) e grandes redes (>50 lojas). |
| 13/09/2026 | Abrangência (SAM) | **Estado de São Paulo** | Sede em Jundiaí. 30% do faturamento nacional do setor. |
| 13/09/2026 | Equipe inicial | Os 4 sócios (integrantes do grupo) | 2 sócios dedicados 50% à implantação → capacidade de 2 redes/mês. |
| 28/09/2026 | Modelagem | **Gradient boosting (LightGBM) global por grupo de categorias + regressão quantílica + baselines obrigatórios** | Justificativa: competição M5 (Makridakis et al., 2022); leve (Green AI); explicável via SHAP. |
| 28/09/2026 | Planos e preços | **Essencial R$ 990 / Profissional R$ 1.500 / Rede R$ 1.990 por loja/mês**; onboarding R$ 9 mil / 15 mil / 25 mil por rede | Mix esperado 30/50/20 → média ≈ R$ 1.450, coerente com os R$ 1.500 do cap. 1. |
| 28/09/2026 | Módulos do produto | Previsão de Demanda, Pedido Sugerido, Alertas de Ruptura e Perdas, Painel de Resultados, Conectores | MVP (meses 1–6): Previsão + Pedido Sugerido, mercearia/bebidas/FLV, 1 conector, 3 pilotos. Produto final no mês 12. |
| 28/09/2026 | Humano no controle | Pedido só vai ao fornecedor após aprovação humana no 1º ano; automação opcional depois | Também é a prática de "IA justa" do cap. 2.4.2. |
| 15/11/2026 | Título | **DARWIN: plataforma de previsão de demanda para supermercados regionais** | Sugestão da professora na P1. Fonte única do título: negrito da referência em `capitulos/00-Resumo.md`. |
| 15/11/2026 | Nuvem | **Google Cloud, região São Paulo (southamerica-east1)** | 87% de energia livre de carbono em 2025 (Green AI); BigQuery/Cloud Run cobrados por uso; Google for Startups (até US$ 200 mil, exige rodada pré-seed). |
| 15/11/2026 | Arquitetura | Pipeline em lote diário: conectores (Cloud Run Jobs) → Cloud Storage + BigQuery → dbt + testes → LightGBM em VMs Spot (Vertex AI) + MLflow → inferência em lote até 6h → Cloud SQL + API FastAPI; monitoramento Cloud Monitoring + Evidently + CodeCarbon; orquestração Cloud Scheduler + Workflows (Composer a partir de 60 redes) | Figura 1 do cap. 3 (`ferramentas/gerar_figuras.py`). |
| 15/11/2026 | Papéis (proposta, grupo pode ajustar) | Rafael = Data Engineer; Jean Pablo = Data Scientist; Wellington = ML Engineer/plataforma (CTO); Andressa = Product Analyst, CS e comercial (CEO) | Rafael e Jean Pablo dedicam 50% às implantações (base do SOM). Figura 2 e Quadro 14. |
| 15/11/2026 | CNAE | Principal **6311-9/00**; secundários 6319-4/00, 6204-0/00, 6201-5/01 | A CONCLA exclui SaaS da 6203-1/00. Validar com contador. |
| 15/11/2026 | Captação | Sócios R$ 60 mil + PIPE FAPESP fase 1 (até R$ 300 mil) / Centelha SP + pré-seed de R$ 500 mil a partir do mês 7 | Necessidade de caixa: ~R$ 190 mil (mínimo no mês 6) a ~R$ 350 mil com atraso e impostos. |

## 2. Premissas numéricas centrais (manter consistência entre capítulos)

| Premissa | Valor | Fonte / onde aparece |
|---|---|---|
| Faturamento supermercados Brasil 2025 | R$ 1,145 tri; 439.728 lojas; 9,02% do PIB; 1.017 empresas no ranking | ABRAS (2026) – cap. 1 |
| Faturamento supermercados SP 2025 | R$ 350 bi (30% do Brasil); 27 mil estabelecimentos; 8,7% do PIB paulista | APAS (2026) – cap. 1 |
| Índice de ruptura | 11,9% (set/2025); 10,8% (jul/2026) | Neogrid – cap. 1 |
| Perdas no varejo | R$ 36,5 bi em 2024 = 1,51% (Abrappe/KPMG); **R$ 42,1 bi em 2025 = 1,65%** (Abrappe/**Protiviti**, 9ª edição); perecibilidade ≈ 40% das quebras em supermercados (dado de 2024) | cap. 1, Introdução |
| Impacto da ruptura | Média mundial 8,3%; 31% compram em outra loja; varejista perde ~4% das vendas; 47% das rupturas vêm do pedido/previsão da loja | Gruen, Corsten e Bharadwaj (2002) – substitui os "5–10%", "42%" e "32%" sem fonte primária |
| Margem bruta de referência | 25% nas contas (conservador); GPA 27,6% em 2025 | GPA (2026) – cap. 1 Bloco 2 |
| SAM | ~350 redes de 5–50 lojas em SP; ~4.500 lojas; ~R$ 58 bi de faturamento; ~R$ 81 mi/ano de receita endereçável | Estimativa dos autores – cap. 1.3.1 |
| SOM (24 meses) | 20 redes; ~260 lojas; ~R$ 4,7 mi/ano de receita recorrente + R$ 300 mil de onboarding | Capacidade de implantação – cap. 1.3.2 |
| Custo fixo inicial | ~R$ 40 mil/mês → ponto de equilíbrio ≈ 27 lojas | Estimativa – cap. 1.3.1 (detalhar nos caps. 3 e 5) |
| Esforço de onboarding | ~80 h técnicas por rede + 4 semanas de operação assistida; onboarding total de 4 a 6 semanas | cap. 1.3.2 e cap. 2.1 |
| Exemplo de ROI do cliente | Rede de 20 lojas (R$ 600 mi/ano): quebras R$ 9,9 mi (1,65%), vendas perdidas R$ 24 mi (4%); recupera R$ 1,2 mi de margem + ~R$ 1 mi de perdas ≈ **R$ 2,2 mi/ano** vs assinatura R$ 360 mil (~6x) | cap. 1 Bloco 2 (refeito em 15/11) |
| Custo fixo ao longo do tempo | R$ 40 mil/mês no início → ~R$ 110–116 mil/mês no mês 24 (4 contratações: suporte/CS mês 9, eng. dados mês 13, vendas mês 15, cientista mês 20) → equilíbrio ~76 lojas | cap. 3.3 |
| Custo de nuvem | Pilotos US$ 350/mês (~R$ 1,9 mil); 20 redes US$ 1.310 (~R$ 7,2 mil; 1,9% da receita); 60 redes US$ 3.300 (1,6%) – preços de tabela +50% para SP, câmbio R$ 5,50 | cap. 3.5, Quadro 17 |
| Funil e CAC | 200 redes contatadas → 60 reuniões → 30 diagnósticos gratuitos → 20 contratos; CAC ≈ R$ 23,5 mil/rede; payback < 2 meses | cap. 4.1 |
| Retenção | Metas GRR ≥ 92% (churn de receita ≤ 8%/ano) e NRR ≥ 105%; referência SaaS Capital 2025: GRR 91%, NRR 101% (102% na faixa de ACV US$ 25–50 mil) | cap. 4.4 |
| Projeção de caixa | Receita ano 1 ≈ R$ 600 mil; ano 2 ≈ R$ 3,4 mi; caixa mínimo ≈ −R$ 190 mil no mês 6; positivo acumulado a partir do mês 12 | cap. 5 (estimativa dos autores) |
| Compromissos da PUV | WAPE ≥ 20% menor que o baseline (backtest 24 meses); ruptura −20% e perdas −10% em piloto de 90 dias com lojas de controle; 1º pedido sugerido ≤ 30 dias; aceitação do pedido ≥ 80% após 60 dias; ROI ≥ 5x | cap. 2.2 (Quadro 10) – reaproveitar no cap. 4 como métricas de Customer Success |
| Nível de serviço | Disponibilidade 99,5%/mês; previsões até 6h; retreino semanal; backtest mensal | cap. 2.1 (Quadro 8) – detalhar SLA no cap. 4 |
| Indicadores ESG | CodeCarbon (kWh/kgCO2e por retreino, −10%/ano); nuvem ≤ 4% da receita; ΔWAPE entre grupos de lojas ≤ 5 p.p.; drift: PSI > 0,2 ou piora > 15% por 2 semanas; eliminação de dados ≤ 30 dias | cap. 2.4 (Quadro 11) – reaproveitar no cap. 3.4 |
| Dados tratados | Vendas/estoque/cadastro agregados (não pessoais); dados pessoais só de usuários da plataforma; sem CPF de fidelidade no MVP | cap. 2.4.3 |

## 3. Estrutura do trabalho e status

| Parte | Status | Arquivo-fonte |
|---|---|---|
| Capa e folha de rosto | ✅ Preenchidas (nomes, título Darwin, set/2026) | .doc |
| Capa e folha de rosto (título novo, natureza do trabalho com recuo de 8 cm) | ✅ 15/11 | `ferramentas/ajustar_pretextuais.ps1` |
| Ficha catalográfica | ⏳ Pendente (confirmar com a biblioteca se é exigida) | .doc |
| Resumo / Abstract | ✅ 15/11: Resumo refeito (212 palavras, cobre caps. 1–5) e Abstract escrito (208 palavras); referência no formato pedido pela professora; marca-texto amarelo do modelo removido | `capitulos/00-Resumo.md`, `capitulos/00-Abstract.md` |
| Listas de ilustrações e quadros | ✅ 15/11: Lista de Ilustrações com campo de Figuras (Figuras 1–2) e Lista de Quadros (1–24) | .doc |
| Introdução (resumo executivo) | ✅ 15/11 reescrita na ordem da professora: contexto com CAGR/IA/volume de dados → dor (R$ 42,1 bi; Gruen) → objetivo-tese e específicos como marcos → estrutura ligada à tese | `capitulos/00-Introducao.md` |
| **1 Análise de Mercado – Varejo** (Blocos 1–3, 1.1 a 1.5, Quadros 1–7) | ✅ Rascunho v1 inserido no .doc (13/09); citação BRASIL 2025 → 2025a ajustada em 28/09 | `capitulos/01-Analise-de-Mercado.md` |
| **2 O produto de dados e sua proposta de valor** (2.1 ficha técnica, 2.2 PUV, 2.3 escopo e limitações, 2.4 ESG com 2.4.1–2.4.3, Quadros 8–11) | ✅ **Rascunho v1 inserido no .doc (28/09)** – revisar em grupo | `capitulos/02-Produto-e-Proposta-de-Valor.md` |
| 3 Operações, infraestrutura e MLOps (3.1–3.5, Figuras 1–2, Quadros 12–17) | ✅ Rascunho v1 inserido (15/11) – revisar em grupo, em especial os papéis do Quadro 14 | `capitulos/03-Operacoes-Infraestrutura-MLOps.md` |
| 4 Distribuição, vendas e gestão de carteira (4.1–4.4, Quadros 18–23) | ✅ Rascunho v1 inserido (15/11) | `capitulos/04-Distribuicao-Vendas-Carteira.md` |
| 5 Considerações finais (tese, riscos – Quadro 24, próximos passos, visão, aprendizado) | ✅ Rascunho v1 inserido (15/11) | `capitulos/05-Consideracoes-Finais.md` |
| Referências (ABNT NBR 6023) | ✅ 15/11: 98 referências inseridas no .doc, sem numeração no título; roteiro da professora removido | `referencias.md` |
| Correções da P1 (comentários em `projeto_devolvido_p1/Comentado_Darwin.docx`) | ✅ 15/11 – ver histórico | – |

## 4. Arquivos deste diretório

- `Projeto para Avaliação_Empreendedorismo_CDADOS_DARWIN.doc` – documento oficial (entregável).
- `Projeto para Avaliação_Empreendedorismo_CDADOS_MODELO.doc` – modelo original da professora (referência do roteiro).
- `PROGRESSO.md` – este arquivo (decisões, premissas, status, próximos passos).
- `referencias.md` – referências já usadas, em formato ABNT, com URL e data de acesso.
- `capitulos/00-Introducao.md`, `capitulos/00-Resumo.md`, `capitulos/01-Analise-de-Mercado.md` e `capitulos/02-Produto-e-Proposta-de-Valor.md` – texto-fonte da Introdução, do Resumo e dos capítulos (editar aqui e regerar o Word).
- `capitulos/01-blocos.json` e `capitulos/02-blocos.json` – gerados automaticamente a partir dos .md (não editar à mão).
- `ferramentas/md_para_blocos.py` – converte um .md em blocos JSON.
- `ferramentas/inserir_capitulo_word.ps1` – substitui um capítulo dentro do .doc pelos blocos e atualiza o Sumário.
- `ferramentas/converter_legendas_seq.ps1` – converte legendas "Quadro N –" sem campo em legendas com SEQ e reconstrói a lista de quadros (uso pontual).
- `ferramentas/atualizar_resumo.ps1` – aplica `capitulos/00-Resumo.md` nas páginas pré-textuais (referência, resumo e palavras-chave).
- `backup/` – cópias do .doc antes de cada alteração automática.

### Como regerar um capítulo no Word após editar o .md
Sequência completa (ordem importa; feche o Word antes). A pasta padrão dos scripts agora é a raiz do repositório:
```powershell
cd "<pasta do repositório>"
python ferramentas\gerar_figuras.py                       # Figuras 1 e 2 do cap. 3
foreach ($c in "00-Introducao","01-Analise-de-Mercado","02-Produto-e-Proposta-de-Valor","03-Operacoes-Infraestrutura-MLOps","04-Distribuicao-Vendas-Carteira","05-Consideracoes-Finais") { python ferramentas\md_para_blocos.py "capitulos\$c.md" ("capitulos\" + $c.Substring(0,2) + "-blocos.json") }
python ferramentas\md_para_blocos.py --referencias referencias.md capitulos\06-blocos.json
$s = "ferramentas\inserir_capitulo_word.ps1"
powershell -ExecutionPolicy Bypass -File $s -Blocos capitulos\00-blocos.json -InicioTitulo "INTRODU" -FimTitulo "AN"
powershell -ExecutionPolicy Bypass -File $s -Blocos capitulos\01-blocos.json
powershell -ExecutionPolicy Bypass -File $s -Blocos capitulos\02-blocos.json -InicioTitulo "O PRODUTO DE DADOS" -FimTitulo "OPERA"
powershell -ExecutionPolicy Bypass -File $s -Blocos capitulos\03-blocos.json -InicioTitulo "OPERA" -FimTitulo "DISTRIBUI"
powershell -ExecutionPolicy Bypass -File $s -Blocos capitulos\04-blocos.json -InicioTitulo "DISTRIBUI" -FimTitulo "CONSIDERA"
powershell -ExecutionPolicy Bypass -File $s -Blocos capitulos\05-blocos.json -InicioTitulo "CONSIDERA" -FimTitulo "REFER"
powershell -ExecutionPolicy Bypass -File $s -Blocos capitulos\06-blocos.json -InicioTitulo "REFER" -FimTitulo "" -SemNumeroTitulo
powershell -ExecutionPolicy Bypass -File ferramentas\ajustar_pretextuais.ps1
powershell -ExecutionPolicy Bypass -File ferramentas\atualizar_resumo.ps1
powershell -ExecutionPolicy Bypass -File ferramentas\atualizar_resumo.ps1 -Fonte capitulos\00-Abstract.md -TituloResumo ABSTRACT -RotuloChave Keywords
```
Comandos antigos (por capítulo, mantidos para referência):
```powershell
# Introdução
python ferramentas\md_para_blocos.py capitulos\00-Introducao.md capitulos\00-blocos.json
powershell -ExecutionPolicy Bypass -File ferramentas\inserir_capitulo_word.ps1 -Blocos "capitulos\00-blocos.json" -InicioTitulo "INTRODU" -FimTitulo "AN"
# Resumo (referência + resumo + palavras-chave)
powershell -ExecutionPolicy Bypass -File ferramentas\atualizar_resumo.ps1
# Capítulo 1
python ferramentas\md_para_blocos.py capitulos\01-Analise-de-Mercado.md capitulos\01-blocos.json
powershell -ExecutionPolicy Bypass -File ferramentas\inserir_capitulo_word.ps1
# Capítulo 2
python ferramentas\md_para_blocos.py capitulos\02-Produto-e-Proposta-de-Valor.md capitulos\02-blocos.json
powershell -ExecutionPolicy Bypass -File ferramentas\inserir_capitulo_word.ps1 -Blocos "capitulos\02-blocos.json" -InicioTitulo "O PRODUTO DE DADOS" -FimTitulo "OPERA"
```
O script faz backup automático em `backup/`, apaga o conteúdo entre o título do capítulo e o título do capítulo seguinte, insere o texto novo com os estilos do modelo (Título 1/2/3 com numeração automática, Normal, Legenda) e atualiza o Sumário. Feche o Word antes de rodar. Para os próximos capítulos, passar `-InicioTitulo` com um trecho do título do capítulo (em maiúsculas, sem acentos) e `-FimTitulo` com o início do título seguinte.

## 5. Próximos passos

**Após a revisão de 15/11/2026 (pós-P1):**
1. Revisão em grupo dos Capítulos 3, 4 e 5 – em especial a distribuição de papéis (Quadro 14 e Figura 2), que foi uma proposta, e os números estimados pelos autores (custos de nuvem, CAC, projeção de caixa).
2. Conferir no .doc final: Sumário, listas, numeração de páginas, quebras de quadros; gerar PDF.
3. Confirmar com a professora/biblioteca se a ficha catalográfica é exigida.
4. Itens marcados como "a confirmar" nas pendências abaixo (CNAE com contador, INPI, preços da região São Paulo do Google Cloud).

**Histórico do planejamento anterior (Entrega 1):**

**Entrega 1 – 30/09/2026: Capítulos 1 e 2 revisados. Somente o documento, sem apresentação oral.** Decisões de preço, metas e escopo (issues #1, #2, #5) e responsáveis (#4) até 29/09; revisões (#6, #7) e conferência de referências (#12) até 30/09; gerar .doc/PDF e enviar. Milestone "Entrega 30/09 – Capítulos 1 e 2" no repositório.


1. **Revisão em grupo dos Capítulos 1 e 2** – ler o .doc; validar preço dos planos, metas da PUV e os limites declarados em 2.3.
2. **Introdução** – contextualização (Bloco 1), justificativa (ruptura/perdas), objetivo geral e específicos, estrutura do documento; usar a PUV como tese.
3. **Capítulo 3** – diagrama de arquitetura (ingestão → armazenamento → features → modelos → API → monitoramento), provedor de nuvem (decidir entre AWS e Google Cloud São Paulo, coerente com o cap. 2.4.1), equipe e papéis, governança (reaproveitar Quadro 11), capacidade e FinOps (custo de nuvem ≤ 4% da receita). Estender o pipeline para inserir a Figura.
4. **Capítulo 4** – go-to-market (outbound + parcerias com ERPs regionais + APAS Show), onboarding, suporte/SLA (99,5%, previsões até 6h), Customer Success com os KPIs do Quadro 10, churn.
5. **Capítulo 5, Resumo, Abstract, listas, ficha catalográfica, revisão ABNT.**

## 6. Pendências e pontos a confirmar

- [x] CADE sobre Carrefour/BIG: citado via Forbes Brasil (25/05/2022, venda de 14 lojas). Não foi localizada a página primária do CADE.
- [x] PL 2338/2023 (marco da IA): reverificado em 15/11/2026 – aguardando parecer na comissão especial da Câmara, sem votação.
- [ ] Preços do Google Cloud para a região São Paulo: o Quadro 17 usa preços de tabela padrão + 50%; conferir no seletor de região das páginas de preço.
- [ ] Composer 3 (Airflow gerenciado) na região São Paulo: disponibilidade só parcialmente confirmada (relevante apenas a partir de 60 redes).
- [ ] Salário de Customer Success Manager: usado o proxy "Analista de Customer Service" da Robert Half; engenheiro de dados via Numerando (fonte mais fraca).
- [ ] Relatório completo da 9ª Pesquisa Abrappe (2025) é restrito a associados; o texto cita a divulgação na imprensa (CartaCapital). O dado de perecibilidade (~40%) é da edição anterior.
- [ ] Buscar um número oficial de tíquete médio de supermercado (NielsenIQ/ABRAS) para o Bloco 2 – hoje o texto usa apenas dados qualitativos de frequência.
- [ ] Se possível, pedir à APAS o número de associados por faixa de lojas para substituir a estimativa do SAM.
- [ ] Fazer busca de anterioridade da marca "Darwin" no INPI (classes 9 e 42).
- [ ] Datas de publicação exatas dos artigos do Projeto Draft e do AgFeed sobre a Aravita (hoje marcadas como 2024 e 2025).
- [ ] Confirmar a URL exata da Resolução CD/ANPD nº 15/2024 (comunicação de incidentes) em `referencias.md`; hoje aponta para a página geral de atos normativos da ANPD.
- [x] Figuras: `inserir_capitulo_word.ps1` insere PNG (`![...](caminho)`) com legenda "Figura N –" (SEQ Figura); a Lista de Ilustrações usa índice de figuras.
- [x] Lista de quadros: em 30/09 as 11 legendas foram convertidas em legendas reais do Word (campo SEQ Quadro), a lista pré-textual passou a se chamar LISTA DE QUADROS e lista os Quadros 1–11 com páginas; o script de inserção já gera legendas com SEQ. A LISTA DE ILUSTRAÇÕES ficou com "Não há" até a figura do Capítulo 3 (depois, inserir legenda "Figura N –" com SEQ Figura e apontar a lista para esse rótulo).

- [x] Frase sobre "primeira entrega" removida da Introdução; Abstract escrito; nº de folhas atualizado (83 f. em 15/11).

## 7. Histórico

- **13/09/2026 – Sessão 1:** definições (nome, segmento, solução, modelo, nicho, SAM); pesquisa de mercado com ~40 fontes; Capítulo 1 escrito (Blocos 1–3, seções 1.1–1.5, Quadros 1–7) e inserido no .doc; criação de PROGRESSO.md, referencias.md e ferramentas de regeneração.
- **30/09/2026 – Sessão 3:** legendas dos quadros convertidas em campos SEQ e LISTA DE QUADROS reconstruída; Introdução escrita e inserida; Resumo breve e palavras-chave inseridos; linha de referência preenchida; scripts `converter_legendas_seq.ps1` e `atualizar_resumo.ps1` criados.
- **15/11/2026 – Sessão 4 (pós-P1):** comentários da professora (`projeto_devolvido_p1/Comentado_Darwin.docx`, 131 comentários em vermelho) aplicados. Observação: o PDF avaliado tinha uma Introdução diferente da do repositório (sem citações), Resumo com texto de preenchimento e a "Nota ao Aluno"; a base usada foi a do repositório. Correções: título novo; natureza do trabalho com recuo de 8 cm; Resumo e Abstract; Introdução reestruturada (CAGR, gasto em IA Gartner set/out 2026, IDC US$ 3,4 bi, volume de dados, objetivos como marcos, estrutura ligada à tese); cap. 1: frase "o grupo atuou como investigador" removida, perdas 2025 (R$ 42,1 bi, Abrappe/Protiviti), números de ruptura sem fonte primária substituídos por Gruen et al. (2002) e conta de ROI refeita, fonte da margem (GPA), preços de concorrentes marcados como indicativos, Quadro 1 com faixas acumuladas explicadas, CADE referenciado, RELEX confirmada por imprensa independente, reforma tributária com artigos (LC 214 arts. 343, 346, 348; Ato Conjunto RFB/CGIBS nº 1/2025, art. 3º), PL 2338 atualizado, coluna "Definição estratégica" do Quadro 2 removida, "roteiro de Oliveira" removido das fontes, CNAE corrigido, Sebrae citado diretamente, data de consulta informada, responsáveis por função nomeados; cap. 2: tom técnico, PUV com 1,6%/4%, fontes primárias de energia (Amazon 2025; Google CFE 87%), prudência na comparação com concorrentes; referências revisadas (98). Capítulos 3, 4 e 5 escritos e inseridos, com Figuras 1–2 e Quadros 12–24. Scripts: figuras, referências, títulos de capítulo padronizados, pré-textuais, Abstract.
- **28/09/2026 – Sessão 2:** decisões de modelagem (gradient boosting), planos (3 faixas) e escopo do MVP; Capítulo 2 escrito (2.1 ficha técnica, 2.2 PUV, 2.3 escopo e limitações, 2.4 ESG com 2.4.1–2.4.3, Quadros 8–11) e inserido no .doc; 12 referências novas; ajuste da citação BRASIL 2025a no cap. 1; verificação do status do PL 2338.
