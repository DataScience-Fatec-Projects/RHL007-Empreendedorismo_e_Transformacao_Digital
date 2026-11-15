# -*- coding: utf-8 -*-
"""Gera as figuras do Capítulo 3 em capitulos/figuras/ (PNG, 200 dpi).

  fig01-arquitetura.png  – arquitetura da solução e pipeline de dados (seção 3.1)
  fig02-organograma.png  – organograma funcional da equipe (seção 3.3)

Uso: python ferramentas/gerar_figuras.py
"""
import os

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import FancyArrowPatch, FancyBboxPatch  # noqa: E402

RAIZ = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SAIDA = os.path.join(RAIZ, "capitulos", "figuras")

TINTA = "#1f2933"
CINZA = "#5f6b7a"
AZUL = "#1d4e89"
AZUL_CLARO = "#e8f0fa"
VERDE = "#2e7d4f"
VERDE_CLARO = "#e9f5ee"
LARANJA = "#b35c00"
LARANJA_CLARO = "#fdf1e4"
NEUTRO = "#f4f5f7"
NL = "\n"


def caixa(ax, x, y, w, h, texto, fc=NEUTRO, ec=CINZA, fs=8.5, peso="normal", cor=TINTA, estilo="-", lw=1.0):
    ax.add_patch(FancyBboxPatch((x, y), w, h, boxstyle="round,pad=0.004,rounding_size=0.012",
                                fc=fc, ec=ec, lw=lw, ls=estilo))
    ax.text(x + w / 2, y + h / 2, texto, ha="center", va="center", fontsize=fs, color=cor,
            fontweight=peso, linespacing=1.25)


def seta(ax, x1, y1, x2, y2, cor=TINTA, estilo="-|>", lw=1.2, ls="-", rad=0.0):
    ax.add_patch(FancyArrowPatch((x1, y1), (x2, y2), arrowstyle=estilo, mutation_scale=11, color=cor, lw=lw,
                                 linestyle=ls, connectionstyle=f"arc3,rad={rad}"))


def L(*linhas):
    return NL.join(linhas)


def arquitetura():
    fig, ax = plt.subplots(figsize=(13, 7.6), dpi=200)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")

    # nuvem (região São Paulo)
    ax.add_patch(FancyBboxPatch((0.165, 0.075), 0.825, 0.775, boxstyle="round,pad=0.004,rounding_size=0.015",
                                fc="white", ec=AZUL, lw=1.4, ls="--"))
    ax.text(0.172, 0.83, "Google Cloud – região São Paulo (southamerica-east1) · projetos separados: "
            "desenvolvimento, homologação e produção", fontsize=8.5, color=AZUL, fontweight="bold", va="center")

    # faixa superior: orquestração e engenharia
    caixa(ax, 0.18, 0.73, 0.795, 0.075,
          L("Orquestração: Cloud Scheduler + Cloud Workflows (Cloud Composer/Airflow a partir de 60 redes)",
            "CI/CD: GitHub Actions   ·   Infraestrutura como código: Terraform   ·   Segredos: Secret Manager"),
          fc=AZUL_CLARO, ec=AZUL, fs=8)

    colunas = [
        (L("1 Ingestão", "(batch diário, D-1)"),
         [L("Conectores por ERP", "(Cloud Run Jobs,", "leitura somente)"),
          L("Arquivos CSV via", "SFTP para a área", "de entrada")]),
        ("2 Armazenamento",
         [L("Data lake:", "Cloud Storage", "(Parquet; camadas", "bruta e tratada)"),
          L("Data warehouse:", "BigQuery", "(um dataset", "por cliente)")]),
        (L("3 Processamento", "(ELT)"),
         [L("dbt sobre BigQuery:", "limpeza, correção", "de demanda censurada", "e tabelas de features"),
          L("Testes de dados", "(dbt tests e Great", "Expectations): falha", "bloqueia o pipeline")]),
        (L("4 Treino e", "versionamento"),
         [L("LightGBM global por", "grupo + regressão", "quantílica (Vertex AI", "Training, VMs Spot)"),
          L("MLflow: experimentos", "e registro de modelos;", "portão de backtesting", "antes do deploy")]),
        (L("5 Entrega", "(serviço do modelo)"),
         [L("Inferência batch", "diária concluída", "até as 6h", "(Cloud Run Jobs)"),
          L("API REST (FastAPI,", "Cloud Run) e app web", "sobre Cloud SQL;", "pedido volta ao ERP")]),
    ]
    x0, larg, passo = 0.18, 0.143, 0.163
    for k, (titulo, itens) in enumerate(colunas):
        x = x0 + k * passo
        caixa(ax, x, 0.635, larg, 0.07, titulo, fc=AZUL, ec=AZUL, fs=8.5, peso="bold", cor="white")
        caixa(ax, x, 0.45, larg, 0.165, itens[0], fs=7.8)
        caixa(ax, x, 0.265, larg, 0.165, itens[1], fs=7.8)
        if k < len(colunas) - 1:
            seta(ax, x + larg + 0.002, 0.44, x + passo - 0.002, 0.44)

    # fontes do cliente (fora da nuvem)
    caixa(ax, 0.01, 0.635, 0.135, 0.07, "Ambiente do cliente", fc=CINZA, ec=CINZA, fs=8.5, peso="bold", cor="white")
    caixa(ax, 0.01, 0.495, 0.135, 0.12, L("ERP de varejo", "(Consinco/TOTVS,", "Bluesoft, Zanthus,", "RP Info, Sysmo)"), fs=7.8)
    caixa(ax, 0.01, 0.375, 0.135, 0.10, L("Vendas por item,", "loja e dia; estoque;", "cadastro; promoções"), fs=7.8)
    caixa(ax, 0.01, 0.265, 0.135, 0.09, L("Dados externos:", "feriados e clima"), fs=7.8)
    seta(ax, 0.147, 0.44, 0.178, 0.44)

    # usuários: saída da entrega até o cliente
    caixa(ax, 0.01, 0.09, 0.135, 0.15, L("Compradores e", "gerentes do cliente", "(web, e-mail,", "WhatsApp)"),
          fc=VERDE_CLARO, ec=VERDE, fs=7.8)
    xc5 = x0 + 4 * passo + larg / 2
    ax.plot([xc5, xc5], [0.264, 0.215], color=VERDE, lw=1.2)
    seta(ax, xc5, 0.215, 0.147, 0.215, cor=VERDE)
    ax.text(0.30, 0.222, "previsões, pedido sugerido, alertas e explicações", fontsize=7.6, color=VERDE, style="italic")

    # monitoramento
    caixa(ax, 0.18, 0.09, 0.795, 0.085,
          L("6 Monitoramento: Cloud Monitoring e Logging (prazo das 6h, falhas, disponibilidade)  ·  "
            "Evidently (drift: PSI e WAPE realizado)",
            "CodeCarbon (energia por retreino)  ·  Billing (custo de nuvem por loja)"),
          fc=LARANJA_CLARO, ec=LARANJA, fs=7.8)
    seta(ax, 0.95, 0.264, 0.95, 0.177, cor=LARANJA)
    xc4 = x0 + 3 * passo + larg / 2
    seta(ax, xc4 - 0.02, 0.177, xc4, 0.262, cor=LARANJA, ls="--")
    ax.text(xc4 - 0.03, 0.185, "alerta de drift aciona retreino", fontsize=7.2, color=LARANJA, ha="right")

    ax.text(0.5, 0.035, "Rotina diária: 0h–1h ingestão · 1h–2h ELT e testes · 2h–4h inferência e pedido sugerido · "
            "até 6h publicação.  Retreino semanal (domingo à noite) e backtesting mensal.",
            ha="center", fontsize=8, color=CINZA)
    os.makedirs(SAIDA, exist_ok=True)
    fig.savefig(os.path.join(SAIDA, "fig01-arquitetura.png"), bbox_inches="tight", facecolor="white")
    plt.close(fig)


def organograma():
    fig, ax = plt.subplots(figsize=(13, 6.6), dpi=200)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")

    caixa(ax, 0.30, 0.86, 0.40, 0.10, L("Sócios-fundadores", "(comitê semanal: prioridades, metas, caixa e riscos)"),
          fc=TINTA, ec=TINTA, fs=9, peso="bold", cor="white")

    areas = [
        ("Engenharia de Dados", L("Rafael Soares de Albuquerque", "(Data Engineer)"),
         L("Conectores de ERP", "Pipelines e dbt", "Qualidade de dados", "Correção de demanda censurada"),
         L("Engenheiro de dados", "pleno (mês 13)")),
        ("Ciência de Dados", L("Jean Pablo de Souza de França", "(Data Scientist)"),
         L("Modelos e baselines", "Backtesting e calibração", "Auditoria de justiça", "Model cards"),
         L("Cientista de dados", "pleno (mês 20)")),
        (L("Engenharia de ML", "e Plataforma"), L("Wellington Júnior Torres de Melo", "(ML Engineer · CTO)"),
         L("MLOps, deploy e API", "Monitoramento e SLA", "Segurança e LGPD técnica", "FinOps e Green AI"),
         None),
        (L("Produto, Sucesso do", "Cliente e Comercial"), L("Andressa Santos Silva", "(Product Analyst · CEO)"),
         L("Prospecção e pilotos", "Onboarding e treinamento", "QBR e health score", "Roadmap de produto"),
         L("Analista de suporte e", "sucesso do cliente (mês 9)", "Executivo de vendas (mês 15)")),
    ]
    larg, passo, x0 = 0.225, 0.245, 0.02
    for k, (area, pessoa, resp, futuro) in enumerate(areas):
        x = x0 + k * passo
        cx = x + larg / 2
        ax.plot([0.5, cx], [0.86, 0.765], color=CINZA, lw=1.0)
        caixa(ax, x, 0.68, larg, 0.085, area, fc=AZUL, ec=AZUL, fs=9, peso="bold", cor="white")
        caixa(ax, x, 0.585, larg, 0.08, pessoa, fc=AZUL_CLARO, ec=AZUL, fs=8)
        caixa(ax, x, 0.36, larg, 0.205, resp, fs=8)
        if futuro:
            caixa(ax, x, 0.215, larg, 0.12, "Contratação prevista:" + NL + futuro, fc="white", ec=CINZA, fs=7.8,
                  estilo="--", cor=CINZA)

    # interações (fluxo de trabalho entre as áreas)
    fluxos = [
        (0, 1, "dados validados e features"),
        (1, 2, "modelo aprovado no backtesting"),
        (2, 3, "previsões no prazo e métricas de uso"),
    ]
    y = 0.145
    for a, b, rot in fluxos:
        xa = x0 + a * passo + larg / 2 + 0.02
        xb = x0 + b * passo + larg / 2 - 0.02
        seta(ax, xa, y, xb, y, cor=VERDE)
        ax.text((xa + xb) / 2, y + 0.012, rot, ha="center", va="bottom", fontsize=7.4, color=VERDE)
    xa = x0 + 3 * passo + larg / 2
    xb = x0 + larg / 2
    seta(ax, xa, 0.075, xb, 0.075, cor=LARANJA, ls="--")
    ax.text((xa + xb) / 2, 0.085, "retorno do cliente: motivos de ajuste dos pedidos, incidentes e pedidos de melhoria "
            "(backlog semanal)", ha="center", va="bottom", fontsize=7.4, color=LARANJA)
    fig.savefig(os.path.join(SAIDA, "fig02-organograma.png"), bbox_inches="tight", facecolor="white")
    plt.close(fig)


if __name__ == "__main__":
    arquitetura()
    organograma()
    print("Figuras geradas em", SAIDA)
