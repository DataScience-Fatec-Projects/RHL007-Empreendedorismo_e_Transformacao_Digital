# Darwin – resumo para o grupo (28/09/2026)

## O que já decidimos

1. **Empresa:** Darwin, uma empresa de Ciência de Dados para o varejo alimentar. O nome remete à adaptação contínua: modelos que se retreinam conforme a demanda muda.
2. **Produto:** plataforma SaaS de previsão de demanda e reposição para supermercados, com cinco módulos: Previsão de Demanda, Pedido Sugerido, Alertas de Ruptura e Perdas, Painel de Resultados e Conectores de ERP.
3. **Cliente ideal (ICP):** redes regionais de 5 a 50 lojas, faturamento de R$ 100 mi a R$ 2 bi, que já têm ERP mas não têm equipe de dados. Decisor: comprador-chefe ou diretor de operações.
4. **Mercado:** Estado de São Paulo (R$ 350 bi, 30% do setor no Brasil). Mercado atendível: ~350 redes e ~4.500 lojas. Meta em 24 meses: 20 redes (~260 lojas), ~R$ 4,7 mi/ano de receita recorrente.
5. **Modelo de negócio:** híbrido, assinatura por loja + onboarding pago. Planos: Essencial R$ 990, Profissional R$ 1.500, Rede R$ 1.990 por loja/mês. Onboarding R$ 9 mil, 15 mil e 25 mil por rede.
6. **Tecnologia:** LightGBM (gradient boosting) global por grupo de categorias, com baselines obrigatórios e previsão por quantis; explicabilidade com SHAP; retreino semanal; o comprador aprova todo pedido no 1º ano.
7. **Promessas ao cliente (PUV):** erro de previsão 20% menor que a regra atual (comprovado em backtesting); ruptura −20% e perdas −10% em piloto de 90 dias com lojas de controle; primeiro pedido sugerido em 30 dias; aceitação ≥ 80%; retorno ≥ 5x a assinatura.
8. **Concorrência:** Neogrid, RELEX e Blue Yonder atendem grandes redes; a Aravita é a concorrente mais direta (só perecíveis, R$ 2 a 4 mil por loja). Nossa brecha: preço por loja, todas as categorias, implantação em semanas, suporte local.
9. **ESG:** modelos leves e medição de carbono (CodeCarbon); auditoria de erro por grupo de lojas e cesta básica; alerta para doação de alimentos; LGPD como agente de pequeno porte; MLOps com monitoramento de drift.
10. **Empresa na prática:** sede em Jundiaí, quatro sócios (nós), custo fixo inicial ~R$ 40 mil/mês, ponto de equilíbrio ~27 lojas assinantes.

## Como estamos fazendo

- **Documento oficial:** `Projeto ..._CDADOS_DARWIN.doc`, seguindo o roteiro da professora. O `..._MODELO.doc` é o original e não deve ser editado.
- **Texto-fonte:** cada capítulo é escrito em Markdown na pasta `capitulos/` e inserido no Word por script, que mantém formatação, numeração automática e Sumário e faz backup antes. Comandos prontos estão no `PROGRESSO.md`.
- **Fonte de verdade:** `PROGRESSO.md` (decisões, premissas numéricas, status, pendências) e `referencias.md` (ABNT). Se algum número mudar, muda ali primeiro e depois nos capítulos afetados.
- **Fluxo por capítulo:** definir escopo em conjunto → pesquisar fontes reais → escrever → inserir no Word → revisão do grupo.
- **Regra de edição:** quem quiser mudar o texto edita o `.md` e regera o Word. Se editar direto no `.doc`, avisa o grupo, senão a próxima regeração sobrescreve.

## Onde estamos

| Parte | Status |
|---|---|
| Capítulo 1 – Análise de Mercado (Quadros 1–7) | Pronto, rascunho v1 |
| Capítulo 2 – Produto e PUV (Quadros 8–11) | Pronto, rascunho v1 |
| Introdução | Próximo |
| Capítulo 3 – Operações, infraestrutura e MLOps (com diagrama) | Pendente |
| Capítulo 4 – Vendas, parceiros, suporte e churn | Pendente |
| Capítulo 5, Resumo, Abstract, listas, referências finais | Pendente |

## O que precisamos do grupo agora

- Ler os Capítulos 1 e 2 no .doc e apontar o que cortar, ajustar ou reforçar.
- Validar os preços dos planos e as metas da PUV (são os compromissos registrados no documento; nesta entrega não há apresentação, só o texto).
- Tarefas que dependem de pessoas: busca da marca "Darwin" no INPI; tentar obter da APAS o número de redes por faixa de lojas; achar a referência do CADE sobre Carrefour/BIG e um número oficial de tíquete médio.
