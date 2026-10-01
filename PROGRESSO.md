# Darwin – Trabalho de Empreendedorismo – PROGRESSO

**Disciplina:** Empreendedorismo – 3º semestre – CST em Ciência de Dados – FATEC Jundiaí "Deputado Ary Fossen"
**Professora:** Profª. Ma. Jucelaine Lopes de Oliveira
**Integrantes:** Andressa Santos Silva; Jean Pablo de Souza de França; Rafael Soares de Albuquerque; Wellington Júnior Torres de Melo
**Título:** EMPREENDEDORISMO: Formalização do Processo de Criação e Gestão da Empresa Darwin
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

## 2. Premissas numéricas centrais (manter consistência entre capítulos)

| Premissa | Valor | Fonte / onde aparece |
|---|---|---|
| Faturamento supermercados Brasil 2025 | R$ 1,145 tri; 439.728 lojas; 9,02% do PIB; 1.017 empresas no ranking | ABRAS (2026) – cap. 1 |
| Faturamento supermercados SP 2025 | R$ 350 bi (30% do Brasil); 27 mil estabelecimentos; 8,7% do PIB paulista | APAS (2026) – cap. 1 |
| Índice de ruptura | 11,9% (set/2025); 10,8% (jul/2026) | Neogrid – cap. 1 |
| Perdas no varejo | R$ 36,5 bi em 2024 = 1,51% do faturamento; perecibilidade ≈ 40% das quebras em supermercados | Abrappe/KPMG – cap. 1 |
| SAM | ~350 redes de 5–50 lojas em SP; ~4.500 lojas; ~R$ 58 bi de faturamento; ~R$ 81 mi/ano de receita endereçável | Estimativa dos autores – cap. 1.3.1 |
| SOM (24 meses) | 20 redes; ~260 lojas; ~R$ 4,7 mi/ano de receita recorrente + R$ 300 mil de onboarding | Capacidade de implantação – cap. 1.3.2 |
| Custo fixo inicial | ~R$ 40 mil/mês → ponto de equilíbrio ≈ 27 lojas | Estimativa – cap. 1.3.1 (detalhar nos caps. 3 e 5) |
| Esforço de onboarding | ~80 h técnicas por rede + 4 semanas de operação assistida; onboarding total de 4 a 6 semanas | cap. 1.3.2 e cap. 2.1 |
| Exemplo de ROI do cliente | Rede de 20 lojas: ganho ≈ R$ 2,4 mi/ano vs assinatura R$ 360 mil/ano (>6x) | cap. 1 Bloco 2 |
| Compromissos da PUV | WAPE ≥ 20% menor que o baseline (backtest 24 meses); ruptura −20% e perdas −10% em piloto de 90 dias com lojas de controle; 1º pedido sugerido ≤ 30 dias; aceitação do pedido ≥ 80% após 60 dias; ROI ≥ 5x | cap. 2.2 (Quadro 10) – reaproveitar no cap. 4 como métricas de Customer Success |
| Nível de serviço | Disponibilidade 99,5%/mês; previsões até 6h; retreino semanal; backtest mensal | cap. 2.1 (Quadro 8) – detalhar SLA no cap. 4 |
| Indicadores ESG | CodeCarbon (kWh/kgCO2e por retreino, −10%/ano); nuvem ≤ 4% da receita; ΔWAPE entre grupos de lojas ≤ 5 p.p.; drift: PSI > 0,2 ou piora > 15% por 2 semanas; eliminação de dados ≤ 30 dias | cap. 2.4 (Quadro 11) – reaproveitar no cap. 3.4 |
| Dados tratados | Vendas/estoque/cadastro agregados (não pessoais); dados pessoais só de usuários da plataforma; sem CPF de fidelidade no MVP | cap. 2.4.3 |

## 3. Estrutura do trabalho e status

| Parte | Status | Arquivo-fonte |
|---|---|---|
| Capa e folha de rosto | ✅ Preenchidas (nomes, título Darwin, set/2026) | .doc |
| Ficha catalográfica | ⏳ Pendente (nº de páginas só no final) | .doc |
| Resumo / Abstract | ✅ Resumo breve inserido em 30/09 (um parágrafo + palavras-chave; linha de referência preenchida com o nº de folhas atual). ⏳ Abstract pendente (texto-guia do modelo ainda no .doc) | `capitulos/00-Resumo.md` |
| Listas de ilustrações e tabelas | ⏳ Refazer no final (os Quadros são texto simples, sem campo SEQ) | .doc |
| Introdução (executive summary) | ✅ Inserida em 30/09 (contextualização, justificativa, objetivos, método e estrutura; ~2 páginas) | `capitulos/00-Introducao.md` |
| **1 Análise de Mercado – Varejo** (Blocos 1–3, 1.1 a 1.5, Quadros 1–7) | ✅ Rascunho v1 inserido no .doc (13/09); citação BRASIL 2025 → 2025a ajustada em 28/09 | `capitulos/01-Analise-de-Mercado.md` |
| **2 O produto de dados e sua proposta de valor** (2.1 ficha técnica, 2.2 PUV, 2.3 escopo e limitações, 2.4 ESG com 2.4.1–2.4.3, Quadros 8–11) | ✅ **Rascunho v1 inserido no .doc (28/09)** – revisar em grupo | `capitulos/02-Produto-e-Proposta-de-Valor.md` |
| 3 Operações, infraestrutura e MLOps (3.1 arquitetura e pipeline com diagrama, 3.2 infraestrutura, 3.3 equipe, 3.4 governança e qualidade, 3.5 capacidade e escalabilidade) | ⏳ Pendente – exige uma Figura (diagrama de arquitetura); o pipeline ainda não insere imagens | – |
| 4 Distribuição, vendas e gestão de carteira (canais, parceiros, CS/suporte, churn) | ⏳ Pendente | – |
| 5 Considerações finais | ⏳ Pendente | – |
| Referências (ABNT NBR 6023) | 🟡 Parcial – fontes dos caps. 1 e 2 listadas | `referencias.md` |

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
```powershell
cd "C:\General\fatec\Trabalho de Empreendedorismo"
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

**Entrega 1 – 30/09/2026: Capítulos 1 e 2 revisados. Somente o documento, sem apresentação oral.** Decisões de preço, metas e escopo (issues #1, #2, #5) e responsáveis (#4) até 29/09; revisões (#6, #7) e conferência de referências (#12) até 30/09; gerar .doc/PDF e enviar. Milestone "Entrega 30/09 – Capítulos 1 e 2" no repositório.


1. **Revisão em grupo dos Capítulos 1 e 2** – ler o .doc; validar preço dos planos, metas da PUV e os limites declarados em 2.3.
2. **Introdução** – contextualização (Bloco 1), justificativa (ruptura/perdas), objetivo geral e específicos, estrutura do documento; usar a PUV como tese.
3. **Capítulo 3** – diagrama de arquitetura (ingestão → armazenamento → features → modelos → API → monitoramento), provedor de nuvem (decidir entre AWS e Google Cloud São Paulo, coerente com o cap. 2.4.1), equipe e papéis, governança (reaproveitar Quadro 11), capacidade e FinOps (custo de nuvem ≤ 4% da receita). Estender o pipeline para inserir a Figura.
4. **Capítulo 4** – go-to-market (outbound + parcerias com ERPs regionais + APAS Show), onboarding, suporte/SLA (99,5%, previsões até 6h), Customer Success com os KPIs do Quadro 10, churn.
5. **Capítulo 5, Resumo, Abstract, listas, ficha catalográfica, revisão ABNT.**

## 6. Pendências e pontos a confirmar

- [ ] Confirmar a referência do CADE sobre Carrefour/BIG (ato de concentração de 2022) e incluir em `referencias.md`; hoje o texto cita o fato sem referência formal.
- [x] PL 2338/2023 (marco da IA): verificado em 28/09/2026 – ainda em tramitação na Câmara (comissão especial, sem votação final até jul/2026). O texto do Bloco 1 continua correto; reverificar antes da entrega final.
- [ ] Buscar um número oficial de tíquete médio de supermercado (NielsenIQ/ABRAS) para o Bloco 2 – hoje o texto usa apenas dados qualitativos de frequência.
- [ ] Se possível, pedir à APAS o número de associados por faixa de lojas para substituir a estimativa do SAM.
- [ ] Fazer busca de anterioridade da marca "Darwin" no INPI (classes 9 e 42).
- [ ] Datas de publicação exatas dos artigos do Projeto Draft e do AgFeed sobre a Aravita (hoje marcadas como 2024 e 2025).
- [ ] Confirmar a URL exata da Resolução CD/ANPD nº 15/2024 (comunicação de incidentes) em `referencias.md`; hoje aponta para a página geral de atos normativos da ANPD.
- [ ] Cap. 3 precisará de uma Figura (diagrama de arquitetura): estender `inserir_capitulo_word.ps1` para inserir imagem PNG com legenda "Figura N – ...".
- [x] Lista de quadros: em 30/09 as 11 legendas foram convertidas em legendas reais do Word (campo SEQ Quadro), a lista pré-textual passou a se chamar LISTA DE QUADROS e lista os Quadros 1–11 com páginas; o script de inserção já gera legendas com SEQ. A LISTA DE ILUSTRAÇÕES ficou com "Não há" até a figura do Capítulo 3 (depois, inserir legenda "Figura N –" com SEQ Figura e apontar a lista para esse rótulo).

- [ ] No fechamento: remover da Introdução a frase final sobre "primeira entrega" (último parágrafo de `00-Introducao.md`), escrever o Abstract e rodar `atualizar_resumo.ps1` para atualizar o nº de folhas.

## 7. Histórico

- **13/09/2026 – Sessão 1:** definições (nome, segmento, solução, modelo, nicho, SAM); pesquisa de mercado com ~40 fontes; Capítulo 1 escrito (Blocos 1–3, seções 1.1–1.5, Quadros 1–7) e inserido no .doc; criação de PROGRESSO.md, referencias.md e ferramentas de regeneração.
- **30/09/2026 – Sessão 3:** legendas dos quadros convertidas em campos SEQ e LISTA DE QUADROS reconstruída; Introdução escrita e inserida; Resumo breve e palavras-chave inseridos; linha de referência preenchida; scripts `converter_legendas_seq.ps1` e `atualizar_resumo.ps1` criados.
- **28/09/2026 – Sessão 2:** decisões de modelagem (gradient boosting), planos (3 faixas) e escopo do MVP; Capítulo 2 escrito (2.1 ficha técnica, 2.2 PUV, 2.3 escopo e limitações, 2.4 ESG com 2.4.1–2.4.3, Quadros 8–11) e inserido no .doc; 12 referências novas; ajuste da citação BRASIL 2025a no cap. 1; verificação do status do PL 2338.
