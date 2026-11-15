# Capítulo 3 – Operações, infraestrutura e MLOps (Darwin) – texto-fonte do que vai para o Word

## 3 OPERAÇÕES, INFRAESTRUTURA E MLOPS

Este capítulo descreve como a Darwin transforma dados, ferramentas e pessoas em uma entrega diária confiável: as previsões e os pedidos sugeridos de cada loja disponíveis até as 6h, com a qualidade prometida no Capítulo 2. A distância entre um modelo que funciona em um notebook e um produto de dados que funciona todos os dias, para dezenas de redes, é feita de processos, automação e governança. Por isso o capítulo segue a ordem do próprio fluxo de trabalho: a arquitetura da solução e o pipeline de dados (seção 3.1), a infraestrutura tecnológica e o ambiente operacional (3.2), a equipe que opera essa infraestrutura (3.3), os controles de qualidade de dados e de modelos (3.4) e a capacidade computacional, com o plano de escalabilidade e de custos (3.5). Todas as escolhas partem de três premissas já fixadas: inferência em lote uma vez ao dia, retreino semanal e custo de nuvem de no máximo 4% da receita.

### 3.1 Arquitetura da Solução e Pipeline de Dados

A arquitetura da Darwin foi desenhada para o padrão de uso do varejo alimentar: os dados de venda chegam fechados ao fim do dia, as decisões de compra acontecem pela manhã e o mesmo processamento se repete, com dados diferentes, para cada rede cliente. A solução é, portanto, um pipeline em lote (batch) diário, executado na madrugada, e não um sistema de fluxo contínuo (streaming), que custaria mais sem melhorar a decisão do comprador. Toda a plataforma roda no Google Cloud, na região de São Paulo (southamerica-east1), em operação desde 2017 (STIVER, 2017), o que mantém os dados dos clientes no Brasil e próximos dos usuários. A Figura 1 apresenta o fluxo de dados da ingestão até a entrega do resultado ao cliente.

Figura 1 – Arquitetura da solução e pipeline de dados da Darwin

![Arquitetura da solução Darwin](capitulos/figuras/fig01-arquitetura.png)

Fonte: elaborado pelos autores (2026).

Os seis componentes da Figura 1 funcionam da seguinte forma:

- Ingestão: conectores específicos para cada ERP leem, com usuário somente de leitura, as vendas por item, loja e dia, o estoque, o cadastro de produtos e o calendário promocional do dia anterior (D-1); redes sem conector enviam arquivos CSV por SFTP. Dados externos de feriados e clima completam a carga. Cada conector é um job em contêiner que roda entre 0h e 1h e grava os arquivos, sem transformação, na área de entrada.
- Armazenamento: a camada bruta e a camada tratada ficam em um data lake no Cloud Storage, em formato Parquet; as tabelas analíticas ficam em um data warehouse no BigQuery, com um conjunto de dados (dataset) isolado por cliente, particionado por data e agrupado por loja; e os resultados do dia, consultados pelos usuários, ficam em um banco relacional PostgreSQL gerenciado (Cloud SQL), adequado a leituras rápidas e frequentes.
- Processamento e transformação (ELT): os dados são carregados primeiro e transformados dentro do BigQuery com o dbt, que padroniza cadastros, trata devoluções e cancelamentos, identifica os dias de ruptura e corrige a demanda censurada, e calcula as variáveis de calendário, preço, promoção, defasagens e médias móveis. Testes automáticos de dados rodam antes de qualquer modelo e, se falham, interrompem o pipeline daquela rede e avisam a equipe.
- Treinamento e versionamento: os modelos LightGBM globais por grupo de categorias, com regressão quantílica, são treinados semanalmente em máquinas virtuais do tipo Spot, com desconto de até 91% em relação ao preço normal (GOOGLE CLOUD, 2026f), orquestradas pelo serviço de treinamento do Vertex AI, disponível na região de São Paulo (GOOGLE CLOUD, 2026h). Cada execução registra no MLflow os parâmetros, as métricas de backtesting, a versão dos dados e o artefato do modelo; o registro de modelos do MLflow controla qual versão está em produção (MLFLOW, 2026). Uma versão nova só é promovida se passar pelo portão de backtesting descrito na seção 3.4.
- Deploy (serviço do modelo): como a previsão é diária, o modelo é servido em lote, não por chamadas individuais em tempo real. Um job de inferência por rede gera, entre 2h e 4h, as previsões de 1 a 28 dias, os quantis, o pedido sugerido e os alertas, e publica tudo no Cloud SQL até as 6h. Uma API REST (FastAPI no Cloud Run) entrega esses resultados ao aplicativo web, aos alertas por e-mail e WhatsApp e ao conector que devolve o pedido aprovado ao ERP do cliente.
- Monitoramento: o Cloud Monitoring acompanha a saúde do pipeline (horário de término de cada etapa, falhas, disponibilidade da API) e dispara alerta se a publicação de qualquer rede não estiver concluída até as 5h, uma hora antes do prazo contratado; o Evidently calcula diariamente o desvio das variáveis de entrada e, à medida que as vendas reais chegam, o erro realizado das previsões (EVIDENTLY AI, 2026); o CodeCarbon mede a energia de cada retreino; e os relatórios de faturamento medem o custo de nuvem por loja. Um alerta de desvio aciona análise e, se confirmado, retreino fora do calendário semanal.

A orquestração dessa sequência diária é feita pelo Cloud Scheduler, que dispara o fluxo, e pelo Cloud Workflows, que encadeia as etapas por rede, com novas tentativas automáticas e registro de cada execução; o serviço está disponível na região de São Paulo (GOOGLE CLOUD, 2026i). O Apache Airflow gerenciado (Cloud Composer) oferece mais recursos de agendamento e dependências entre tarefas (THE APACHE SOFTWARE FOUNDATION, 2026), mas tem um custo fixo mensal que não se justifica no início; a migração está prevista para quando a carteira passar de 60 redes. O Quadro 12 resume as escolhas de cada componente e a alternativa descartada.

Quadro 12 – Componentes do pipeline da Darwin e justificativa das escolhas

| Componente | Tecnologia adotada | Por que esta escolha | Alternativa descartada nesta fase |
|---|---|---|---|
| Ingestão | Conectores em contêiner (Cloud Run Jobs) e SFTP para arquivos | Execução por demanda, sem servidor ligado o dia todo; um conector por ERP reaproveitado entre clientes. | Streaming (Pub/Sub, Kafka): não há ganho de decisão com dados em tempo real para pedidos diários. |
| Armazenamento | Cloud Storage (data lake em Parquet), BigQuery (data warehouse) e Cloud SQL PostgreSQL (resultados do dia) | Lake barato para histórico bruto; warehouse sem servidor, cobrado pelo uso; banco relacional para leituras rápidas da aplicação. | Banco relacional único para tudo: não escala para bilhões de linhas de venda. |
| Processamento (ELT) | dbt sobre BigQuery, com dbt tests e Great Expectations | Transformações em SQL versionadas no Git, testáveis e documentadas (DBT LABS, 2026; GREAT EXPECTATIONS, 2026). | Spark (Dataproc): desnecessário para o volume de até 60 redes; reavaliado depois. |
| Treinamento e versionamento | LightGBM e regressão quantílica em VMs Spot via Vertex AI Training; MLflow (experimentos e registro de modelos) | Modelos leves em processadores comuns; Spot reduz o custo do retreino; MLflow é aberto e evita dependência de um único provedor. | GPUs e redes neurais profundas: sem ganho comprovado de acurácia que justifique o custo (seção 2.4.1). |
| Deploy | Inferência em lote por rede (Cloud Run Jobs) e API REST FastAPI (Cloud Run) | O resultado é diário; a API apenas lê resultados prontos, com baixa latência e escala automática. | Endpoint de inferência em tempo real: custo fixo de máquina ligada sem necessidade. |
| Monitoramento | Cloud Monitoring e Logging, Evidently, CodeCarbon e relatórios de faturamento | Cobre saúde do pipeline, desvio dos modelos, energia e custo em um único painel de operação. | Ferramentas pagas de observabilidade: avaliadas quando houver equipe de plantão dedicada. |
| Orquestração | Cloud Scheduler e Cloud Workflows | Sem custo fixo relevante e suficiente para fluxos lineares por rede. | Cloud Composer (Airflow gerenciado): previsto a partir de 60 redes. |

Fonte: elaborado pelos autores (2026).

A análise do Quadro 12 mostra o critério comum das escolhas: usar serviços gerenciados e cobrados pelo uso, que custam pouco quando a carteira é pequena e crescem junto com ela, e preferir ferramentas abertas (dbt, MLflow, LightGBM, Evidently) nas camadas que contêm a propriedade intelectual da empresa, para que uma eventual troca de provedor de nuvem não exija reescrever os modelos. Essa arquitetura corresponde ao nível 1 de maturidade em MLOps, no qual o treinamento é automatizado e contínuo, com validação de dados e de modelos (KAZMIERCZAK; SALAMA; HUERTA, [s.d.]); o nível 2, com integração e entrega contínuas do próprio pipeline, é alcançado com o GitHub Actions descrito na seção 3.2. A preocupação com esses controles desde o início responde a um risco conhecido dos sistemas de aprendizado de máquina: o código do modelo é a menor parte do sistema, e a dívida técnica se acumula nos dados, nas configurações e nas dependências ao seu redor (SCULLEY et al., 2015).

### 3.2 Infraestrutura Tecnológica (Cloud & On-premise)

A Darwin não terá infraestrutura própria de servidores (on-premise): toda a computação, o armazenamento e o deploy dos modelos ficam em nuvem pública, e o único equipamento físico são as estações de trabalho da equipe. A escolha do Google Cloud, entre os provedores avaliados no Capítulo 2, considerou cinco critérios. O primeiro é a localização: a região de São Paulo atende o requisito de manter os dados no país e reduz a latência para os usuários. O segundo é a sustentabilidade, coerente com a prática ambiental da seção 2.4.1: a região de São Paulo operou com 87% de energia livre de carbono em 2025, medida hora a hora (GOOGLE CLOUD, 2026j), contra a compensação anual em energia renovável declarada pela Amazon para o conjunto de suas operações (AMAZON, 2026). O terceiro é o modelo de custo: BigQuery e Cloud Run são cobrados pelo uso, com faixas gratuitas mensais, como o primeiro 1 TiB de consultas e os primeiros 10 GiB de armazenamento no BigQuery (GOOGLE CLOUD, 2026b) e uma cota mensal de processamento no Cloud Run (GOOGLE CLOUD, 2026d), o que torna o custo da fase de pilotos praticamente marginal. O quarto é a oferta de serviços de aprendizado de máquina na própria região, como treinamento personalizado, registro e monitoramento de modelos (GOOGLE CLOUD, 2026h). O quinto é o acesso ao programa Google for Startups Cloud, que concede até US$ 200 mil em créditos ao longo de dois anos a startups que tenham captado rodada pré-seed ou seed (GOOGLE CLOUD, 2026g), condição que a Darwin pretende cumprir conforme o plano de captação do Capítulo 5.

A infraestrutura digital é organizada em três ambientes isolados, cada um em um projeto separado do Google Cloud: desenvolvimento, onde a equipe experimenta com dados anonimizados ou sintéticos; homologação, onde cada versão nova roda sobre uma cópia dos dados de uma rede piloto antes de ser liberada; e produção, que atende os clientes e ao qual apenas o pipeline automatizado e dois sócios têm acesso de escrita. Essa separação garante que um experimento nunca altere a entrega de um cliente. O Quadro 13 relaciona os componentes da infraestrutura digital.

Quadro 13 – Infraestrutura digital da Darwin

| Camada | Ferramenta | Uso na Darwin |
|---|---|---|
| Nuvem (computação, armazenamento e deploy) | Google Cloud, região São Paulo | Todos os serviços da Figura 1, em três projetos (desenvolvimento, homologação e produção). |
| Repositório de código | GitHub (organização privada) | Código dos conectores, transformações dbt, modelos, API e infraestrutura; revisão obrigatória por outro sócio antes de cada integração. |
| Integração e entrega contínuas (CI/CD) | GitHub Actions | Testes automáticos a cada alteração; publicação em homologação e, após aprovação, em produção. |
| Infraestrutura como código | Terraform | Criação reprodutível dos três ambientes e de cada novo cliente (HASHICORP, 2026). |
| Orquestração de pipelines | Cloud Scheduler e Cloud Workflows (Cloud Composer a partir de 60 redes) | Execução diária e semanal das etapas, com novas tentativas e registro. |
| Segurança e acessos | Cloud IAM, Secret Manager, autenticação em dois fatores | Acesso por papel e menor privilégio; credenciais dos ERPs dos clientes guardadas como segredos, nunca no código. |
| Colaboração e gestão | Google Workspace, Slack e Jira | Documentos e e-mail corporativo; comunicação interna e canal compartilhado com clientes do plano Rede; quadro de tarefas e chamados de suporte. |

Fonte: elaborado pelos autores (2026).

O Quadro 13 mostra uma infraestrutura enxuta, mas completa: nenhuma etapa depende de configuração manual, de modo que a criação do ambiente de um cliente novo se resume à execução de um módulo Terraform e à configuração do conector, o que reduz o esforço de onboarding estimado no Capítulo 1 e sustenta a meta de duas implantações por mês.

#### 3.2.1 Ambiente Operacional (Físico e Remoto)

O ambiente operacional combina três camadas. Na infraestrutura física, a Darwin adota o trabalho remoto como padrão, com encontros semanais presenciais em um espaço de coworking em Jundiaí, que também serve de endereço fiscal e de local de reunião com clientes. Cada sócio usa um notebook com pelo menos 16 GB de memória, armazenamento SSD e processador de múltiplos núcleos, além de monitor adicional; o processamento pesado nunca ocorre na máquina local, mas nas instâncias de nuvem, o que dispensa servidores próprios. As visitas aos clientes, nas fases de diagnóstico e treinamento, são feitas com veículo próprio dos sócios e reembolso de quilometragem.

Na infraestrutura digital, descrita no Quadro 13, os dados de clientes nunca são copiados para os notebooks: o desenvolvimento acessa amostras anonimizadas no projeto de desenvolvimento, e a análise de dados reais é feita apenas dentro da nuvem. Na governança de acesso, cada pessoa tem uma conta corporativa com autenticação em dois fatores; as permissões são concedidas por grupo (engenharia, ciência de dados, sucesso do cliente) e revisadas a cada trimestre; os acessos à produção ficam registrados em trilha de auditoria; e, na saída de um colaborador, todas as contas são desativadas no mesmo dia. Essas práticas concretizam os controles de segurança prometidos na ficha técnica (Quadro 8) e no contrato de operador exigido pela LGPD.

### 3.3 Estrutura da Equipe de Dados (Data Team Structure)

Nos primeiros meses, os quatro sócios acumulam os papéis que, em uma empresa madura, seriam de equipes diferentes. A divisão adotada segue as competências que a operação exige, e não a hierarquia: cada sócio é o responsável final por uma área, mas todos participam do onboarding e do suporte enquanto a carteira é pequena. A Figura 2 apresenta o organograma funcional, com as áreas, os responsáveis, as contratações previstas e as interações entre as áreas.

Figura 2 – Organograma funcional da Darwin

![Organograma funcional da Darwin](capitulos/figuras/fig02-organograma.png)

Fonte: elaborado pelos autores (2026).

O fluxo da Figura 2 acompanha o pipeline da Figura 1: a Engenharia de Dados entrega dados validados e variáveis prontas; a Ciência de Dados entrega modelos aprovados no backtesting; a Engenharia de Machine Learning e Plataforma coloca esses modelos em produção e garante a entrega das 6h; e a área de Produto, Sucesso do Cliente e Comercial leva o resultado ao comprador e traz de volta os motivos de ajuste dos pedidos, os incidentes e as solicitações de melhoria, que entram no planejamento semanal. O comitê dos sócios se reúne toda semana para revisar prioridades, metas, caixa e riscos. O Quadro 14 detalha os papéis.

Quadro 14 – Papéis da equipe da Darwin e responsáveis

| Papel | Responsável | Responsabilidades principais | Indicador sob sua responsabilidade |
|---|---|---|---|
| Data Engineer (Engenharia de Dados) | Rafael Soares de Albuquerque | Conectores com os ERPs, pipelines de ingestão e transformação (dbt), testes de qualidade de dados, correção de demanda censurada; dedica metade do tempo às implantações. | Percentual de cargas diárias concluídas sem falha; tempo de integração de um novo cliente. |
| Data Scientist (Ciência de Dados) | Jean Pablo de Souza de França | Modelos de previsão e de demanda intermitente, baselines, backtesting no onboarding, calibração do pedido sugerido, auditoria de justiça e model cards; dedica metade do tempo às implantações. | WAPE contra o baseline por cliente e categoria; diferença de erro entre grupos de lojas. |
| Machine Learning Engineer e plataforma (MLOps) | Wellington Júnior Torres de Melo | Pipeline de treinamento e inferência, deploy, API, monitoramento de drift e do prazo das 6h, segurança, infraestrutura como código, custos de nuvem e medição de energia; responde como diretor de tecnologia (CTO). | Disponibilidade e cumprimento do prazo das 6h; custo de nuvem por loja; energia por retreino. |
| Data Analyst / Product Analyst, Sucesso do Cliente e Comercial | Andressa Santos Silva | Prospecção e pilotos, treinamento dos compradores, painéis de resultado, reuniões de revisão com clientes, priorização do roadmap; responde como diretora executiva (CEO). | Novas redes por trimestre; taxa de aceitação do pedido sugerido; retenção de receita e NPS. |

Fonte: elaborado pelos autores (2026).

O Quadro 14 deixa explícito que os quatro perfis do roteiro (cientista de dados, engenheiro de dados, engenheiro de machine learning e analista de dados e produto) estão cobertos desde o primeiro dia, e que a capacidade de duas implantações por mês, base do SOM do Capítulo 1, vem da dedicação parcial do engenheiro de dados e do cientista de dados ao onboarding. O limite dessa estrutura é a carga de suporte, que cresce com a base instalada. Por isso estão previstas quatro contratações, vinculadas a marcos da carteira, e não ao calendário: um analista de suporte e sucesso do cliente no nono mês, quando a operação assistida das primeiras redes pagantes coincide com novas implantações; um engenheiro de dados pleno no décimo terceiro mês, para assumir a manutenção dos conectores e liberar o sócio para novas integrações; um executivo de vendas no décimo quinto mês, com remuneração variável atrelada à receita nova; e um cientista de dados pleno no vigésimo mês, quando a carteira se aproxima de vinte redes. Como referência de custo, o Guia Salarial 2026 da Robert Half indica mediana de R$ 19,1 mil mensais para cientistas de dados e de R$ 20,2 mil para especialistas em IA e machine learning, e a função de atendimento ao cliente em nível pleno varia de R$ 6,85 mil a R$ 11,1 mil (DE BLASI, 2025; ROBERT HALF, 2026); para engenheiros de dados, a mediana registrada no Novo CAGED é de R$ 11,5 mil (NUMERANDO, 2026). Com essas contratações e os encargos, o custo fixo mensal sobe dos R$ 40 mil iniciais para cerca de R$ 110 mil ao fim do segundo ano, o que desloca o ponto de equilíbrio para cerca de 76 lojas, ainda muito abaixo das 260 lojas previstas no SOM.

### 3.4 Governança de Dados e Qualidade do Modelo

Uma empresa de dados que erra em escala erra para todos os clientes ao mesmo tempo. A governança da Darwin parte desse risco e organiza os controles em quatro frentes: qualidade dos dados, validação dos modelos, monitoramento em produção e transparência. Os controles de privacidade, segurança e ética já foram definidos na seção 2.4 e sintetizados no Quadro 11; esta seção trata da forma como eles são executados na operação.

**Qualidade dos dados.** Cada carga diária passa por testes automáticos antes de alimentar qualquer modelo, escritos como testes do dbt e expectativas do Great Expectations (DBT LABS, 2026; GREAT EXPECTATIONS, 2026): esquema e tipos dos campos; ausência de duplicidades por item, loja e dia; integridade entre vendas e cadastro de produtos; volume do dia dentro de uma faixa esperada para aquele dia da semana; ausência de datas faltantes; e valores plausíveis de preço, quantidade e estoque. Falhas críticas, como a falta de vendas de uma loja inteira, bloqueiam o pipeline daquela rede e acionam o suporte antes das 6h; falhas não críticas geram alerta e são registradas em um painel de qualidade compartilhado com o cliente, porque parte dos problemas (cadastro duplicado, estoque negativo) só pode ser corrigida no ERP dele.

**Validação dos modelos.** Como séries temporais não admitem validação cruzada aleatória, que usaria o futuro para prever o passado, a Darwin usa backtesting com origem móvel: o modelo é treinado com os dados até uma data, prevê os 28 dias seguintes e é comparado com o que realmente foi vendido, em pelo menos quatro janelas que cobrem diferentes estações do ano. As métricas são o WAPE e o RMSSE por categoria, sempre comparados aos baselines de média móvel e sazonal, o viés (tendência a prever acima ou abaixo), a cobertura dos quantis (a previsão P80 deve cobrir cerca de 80% dos dias) e, para o negócio, a ruptura e o excesso simulados com o pedido sugerido. Nenhum modelo vai para produção sem passar pelo portão de backtesting: erro igual ou menor que o do modelo em produção, menor que o baseline e sem piora superior a 5 pontos percentuais em nenhum grupo de lojas.

**Monitoramento.** Dois tipos de desvio são acompanhados semanalmente. O desvio de dados (data drift), mudança na distribuição das variáveis de entrada, como a abertura de uma loja, uma nova política de promoções ou a mudança de mix provocada pela reforma tributária, é medido pelo índice de estabilidade populacional (PSI): valores abaixo de 0,1 indicam estabilidade, entre 0,1 e 0,25 pedem atenção, e acima de 0,25 indicam mudança relevante (YURDAKUL, 2018); a Darwin adota o limiar mais conservador de 0,2, já fixado no Quadro 11, para disparar análise. O desvio de conceito (concept drift), mudança na relação entre as variáveis e a demanda, como uma alteração de hábito de compra que o histórico não contém, não aparece nas entradas e só é detectado pelo erro realizado: piora superior a 15% em relação ao backtesting por duas semanas consecutivas aciona retreino e revisão do modelo. Os dois indicadores são calculados pelo Evidently e acompanhados por cliente, categoria e grupo de lojas.

**Transparência.** Cada grupo de categorias de cada cliente tem um model card (MITCHELL et al., 2019), atualizado a cada nova versão, que registra os dados usados no treinamento, as métricas de backtesting por categoria e por grupo de lojas, as limitações conhecidas (partida a frio, demanda intermitente, eventos sem precedente) e os usos não recomendados. O model card é entregue ao cliente no fim do onboarding e revisado nas reuniões periódicas de resultado. O Quadro 15 consolida os controles.

Quadro 15 – Controles de qualidade de dados e de modelos da Darwin

| Etapa | Controle | Ferramenta | Limiar ou regra | Ação quando falha |
|---|---|---|---|---|
| Ingestão | Esquema, duplicidades, datas faltantes, volume esperado | dbt tests e Great Expectations | Zero falhas críticas; volume do dia entre 70% e 130% da média do mesmo dia da semana | Bloqueia o pipeline da rede e aciona o suporte antes das 6h. |
| Transformação | Integridade entre vendas, estoque e cadastro; demanda censurada | dbt tests | Itens vendidos sem cadastro abaixo de 0,5% | Alerta e registro no painel de qualidade do cliente. |
| Treinamento | Backtesting com origem móvel em quatro janelas | MLflow (registro de métricas) | WAPE menor que o baseline e não pior que o modelo em produção; diferença entre grupos de lojas de até 5 p.p. | Modelo não é promovido; produção mantém a versão anterior. |
| Produção | Desvio de dados (PSI) e desvio de conceito (erro realizado) | Evidently | PSI acima de 0,2; erro realizado 15% pior que o backtesting por duas semanas | Análise da equipe e retreino fora do calendário. |
| Entrega | Prazo e disponibilidade | Cloud Monitoring | Publicação até as 6h; disponibilidade de 99,5% ao mês | Alerta às 5h; contorno com a previsão do dia anterior ajustada e aviso ao cliente. |
| Transparência | Documentação de cada modelo | Model cards | 100% dos modelos em produção com model card atualizado | Versão sem model card não é publicada. |

Fonte: elaborado pelos autores (2026).

O Quadro 15 mostra que cada controle tem um limiar numérico e uma ação definida, o que transforma a governança em rotina automatizada e não em boa intenção. O ponto central é que nenhuma falha chega ao comprador sem aviso: se os dados de uma rede falham, o cliente sabe antes de abrir o sistema; se um modelo novo é pior, ele não substitui o anterior; e se o desempenho se degrada em produção, o retreino acontece antes que a perda apareça no estoque.

### 3.5 Capacidade Computacional e Escalabilidade

A capacidade da Darwin é dimensionada por dois números: a quantidade de séries item-loja processadas por dia e a quantidade de requisições dos usuários à aplicação. Uma rede de 20 lojas com 8 mil itens ativos gera cerca de 160 mil séries (seção 2.4.1); na meta de 24 meses, com 260 lojas, são cerca de 2,1 milhões de séries. Considerando que, em um dia típico, cerca de metade dos itens de cada loja registra venda, a ingestão diária fica em torno de 1 milhão de linhas, e o histórico de 24 meses de toda a carteira soma algumas centenas de milhões de linhas, algumas dezenas de gigabytes em formato Parquet, volume pequeno para o BigQuery. O treinamento semanal de uma rede média, com cerca de 100 mil séries e dois anos de histórico diário, foi estimado pelos autores em até uma hora de processamento em uma máquina de 16 processadores virtuais, e a inferência diária, em menos de 15 minutos por rede. Como cada rede é processada por um job independente, as redes rodam em paralelo, e a janela das 2h às 4h comporta dezenas de redes sem alteração da arquitetura.

Do lado dos usuários, a carteira de 20 redes corresponde a cerca de 600 usuários, com pico de uso entre 7h e 10h, quando os compradores revisam os pedidos. Estimando que 10% deles estejam ativos ao mesmo tempo e façam até dez requisições por minuto, o pico é de aproximadamente 600 requisições por minuto. Como a API apenas lê resultados pré-calculados no Cloud SQL, cada instância do Cloud Run atende várias requisições simultâneas, e o serviço adiciona instâncias automaticamente quando a utilização de processamento ou de concorrência ultrapassa a meta configurada (GOOGLE CLOUD, 2026e). A arquitetura inicial será configurada com uma instância mínima, para evitar o atraso da primeira requisição, e um teto de dez instâncias, e passará por teste de carga antes do primeiro piloto, com a meta de atender 1.000 requisições por minuto com tempo de resposta de até 500 milissegundos para 95% delas. Esses números são estimativas dos autores, a serem confirmadas pelo teste de carga e pelos dados reais dos pilotos.

A estratégia de escalabilidade é progressiva: cada componente só muda quando um limite é atingido, e os gatilhos estão definidos antecipadamente, como mostra o Quadro 16.

Quadro 16 – Plano de capacidade e escalabilidade da Darwin

| Componente | Pilotos (até 3 redes, cerca de 40 lojas) | Meta de 24 meses (20 redes, cerca de 260 lojas) | Expansão (60 redes ou mais, cerca de 780 lojas) |
|---|---|---|---|
| Orquestração | Cloud Scheduler e Cloud Workflows | Cloud Scheduler e Cloud Workflows, com execução paralela por rede | Cloud Composer (Airflow gerenciado), com filas e prioridades por cliente |
| Armazenamento e processamento | BigQuery sob demanda; Cloud Storage padrão | Particionamento por data e agrupamento por loja; ciclo de vida do Cloud Storage para classes mais baratas | Reserva de capacidade do BigQuery; avaliação de Spark (Dataproc) para as transformações mais pesadas |
| Treinamento | VM Spot de 8 processadores virtuais | VMs Spot de 16 processadores virtuais, em paralelo por grupo de categorias | Treinamento distribuído por rede em várias VMs; desconto por compromisso de uso nas cargas estáveis |
| Inferência e API | Cloud Run com 1 a 3 instâncias; Cloud SQL sem alta disponibilidade | Cloud Run com 1 a 10 instâncias; Cloud SQL com alta disponibilidade | Cloud SQL com réplica de leitura; cache de consultas; teto de instâncias ampliado |
| Equipe de operação | Quatro sócios | Sócios e três contratados (suporte, engenharia de dados, vendas) | Plantão de operação em rodízio e equipe de dados ampliada |

Fonte: elaborado pelos autores (2026).

O Quadro 16 evidencia que o crescimento até a meta de 24 meses não exige mudança de arquitetura, apenas ajustes de configuração, e que as mudanças estruturais (orquestrador, réplicas, reserva de capacidade) ficam para quando a receita já as financia.

Quanto à otimização de custos (FinOps), a Darwin trata o custo de nuvem como uma métrica de produto, medida por loja, com teto de 4% da receita da assinatura (seção 2.4.1). As práticas adotadas são: rótulos (labels) por cliente em todos os recursos, para medir o custo de cada rede; orçamentos com alertas no faturamento do Google Cloud, por projeto e por ambiente; uso de VMs Spot no treinamento, que tolera interrupções porque é retomado do último ponto salvo; particionamento e agrupamento das tabelas do BigQuery e limite de bytes processados por consulta, para que nenhuma consulta varra o histórico inteiro sem necessidade; regras de ciclo de vida no Cloud Storage, que movem dados brutos com mais de 90 dias para classes de armazenamento mais baratas e eliminam os dados de clientes encerrados em até 30 dias; ambientes de desenvolvimento e homologação desligados fora do horário de trabalho; e revisão mensal do custo por loja pelo engenheiro de plataforma. O Quadro 17 apresenta a estimativa de custo mensal de nuvem nas três fases.

Quadro 17 – Estimativa de custo mensal de nuvem da Darwin

| Item | Pilotos (3 redes) | Meta de 24 meses (20 redes) | Expansão (60 redes) |
|---|---|---|---|
| BigQuery e Cloud Storage | US$ 20 | US$ 170 | US$ 500 |
| Treinamento (VMs Spot) e inferência (Cloud Run Jobs) | US$ 40 | US$ 330 | US$ 1.000 |
| API e aplicação (Cloud Run) | US$ 60 | US$ 100 | US$ 250 |
| Banco de resultados (Cloud SQL) | US$ 80 | US$ 300 | US$ 600 |
| MLflow, orquestração, monitoramento, SFTP e segredos | US$ 80 | US$ 160 | US$ 650 |
| Ambientes de desenvolvimento e homologação | US$ 70 | US$ 250 | US$ 300 |
| Total mensal estimado | US$ 350 (cerca de R$ 1,9 mil) | US$ 1.310 (cerca de R$ 7,2 mil) | US$ 3.300 (cerca de R$ 18,2 mil) |
| Receita mensal de assinaturas (R$ 1.450 por loja) | Pilotos com desconto | R$ 377 mil (260 lojas) | R$ 1,13 milhão (780 lojas) |
| Custo de nuvem sobre a receita | Não aplicável | 1,9% | 1,6% |

Fonte: elaborado pelos autores (2026), com base nos preços públicos de Google Cloud (2026b, 2026c, 2026d, 2026f), acréscimo de 50% para a região de São Paulo e câmbio de referência de R$ 5,50 por dólar.

A análise do Quadro 17 indica que o custo de nuvem permanece abaixo de 2% da receita em todas as fases, metade do teto fixado, mesmo com a margem de segurança de 50% aplicada sobre os preços de referência para cobrir a diferença de preço da região de São Paulo, que pertence a uma faixa de preço superior à das regiões dos Estados Unidos (GOOGLE CLOUD, 2026k). O custo cresce menos que a receita porque os componentes fixos (banco de resultados, aplicação, ambientes de teste) são diluídos entre mais lojas. Na fase de pilotos, o gasto de cerca de R$ 1,9 mil mensais já está contido nos R$ 40 mil de custo fixo do Capítulo 1. Em síntese, este capítulo mostrou que a Darwin opera com uma arquitetura em lote, gerenciada e de baixo custo, conduzida por uma equipe enxuta com papéis definidos e por controles de qualidade com limiares e ações automáticas, capaz de atender a meta de 24 meses sem mudança estrutural. O Capítulo 4 descreve como essa operação chega ao cliente e como a empresa garante que o valor prometido seja efetivamente capturado.
