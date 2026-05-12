# Nota técnica — uso de contrafactuais nos cenários "E se...?"

**Versão:** 2026-05-12
**Autores:** Time NEES/UFAL · Observatório de Equidade Educacional
**Documento associado:** [`04_governanca_dado.md`](./04_governanca_dado.md) (badges de evidência, fontes, LGPD)

---

## 1. Por que contrafactuais

Indicadores educacionais agregados geralmente respondem à pergunta *"como está hoje?"*. Mas decisões de política pública pedem outra pergunta — *"e se não fosse assim?"*. Sem essa segunda pergunta, fica difícil distinguir o efeito de uma política de mudanças concomitantes (envelhecimento, migração, choques econômicos). O **contrafactual** é uma resposta possível à pergunta "e se não fosse assim?" — um cenário hipotético no qual a política ausente, ou rebatida, é representada explicitamente, lado a lado com a realidade observada.

No protótipo do Observatório, três leituras (L3, L6, L9) adotam essa estrutura. Cada uma traz um botão de alternância "Realidade hoje ↔ Sem essa política" e uma barra fantasma tracejada (`ghost`) que materializa o cenário oposto enquanto o usuário olha o real. **A intenção não é provar causalidade no rigor de um experimento aleatório**, e sim **traduzir desigualdade num formato comunicável** para gestores, professores e cidadãos não-especialistas, mantendo rastreabilidade do tipo de evidência.

### 1.1 Tipologia de contrafactuais adotada

Adotamos três tipos, hierarquizados pela proximidade com a evidência empírica brasileira:

| Tipo | Definição | Exemplo no protótipo | Badge |
|---|---|---|---|
| **A — Série histórica direta** | O contrafactual é um período observado antes da política existir/operar plenamente. Não é estimativa; é dado bruto. | L9 — composição racial das IES Federais em 2012 (pré-Lei de Cotas plena) vs. 2024 | Evidência forte |
| **B — Meta-análise de literatura quasi-experimental** | O contrafactual vem de estudos convergentes (regressão de descontinuidade, diferenças-em-diferenças, propensity score) calculados por terceiros e revisados por pares. | L6 — efeito do Bolsa Família na evasão escolar (Cedeplar, IPEA, Banco Mundial) | Evidência forte |
| **C — Comparativo cross-section** | O contrafactual é construído pela comparação entre UFs/municípios na mesma rodada de dados, sob a hipótese conservadora "se todos estivessem no pior cenário observado". Não é causal — é descritivo da heterogeneidade. | L3 — proficiência se nenhuma UF tivesse os 3 itens básicos de infra | Evidência indireta |

Os badges (`Evidência forte / moderada / indireta`) aparecem no `source` de cada card. **A transparência sobre o tipo é parte do design**: o usuário deve saber se está vendo um número calculado, citado, ou comparado.

---

## 2. Princípios metodológicos gerais

### 2.1 Apresentação visual

- **Toggle binário** "Realidade hoje" ↔ "Sem essa política" — não há gradação intermediária.
- **Barra fantasma tracejada** (`stroke-dasharray '3,3'`) mostra o cenário oposto ao ativo, em pontilhado, em cor de marca (`--counterfactual: #6B2D2D`).
- **Legenda mínima** no canto superior direito do gráfico (implementada em `makeCounterfactualViz`):
  - ▮ barra preenchida = atual
  - ┊ contorno tracejado = cenário sem essa política
- **Callout** abaixo do título, em caixa cinza, sustenta o `off` com evidência (texto, número e fonte).

### 2.2 Princípios éticos e estatísticos

1. **Nunca esconder o tipo de evidência.** A diferença entre "Bolsa Família reduz evasão em 3-7 pp" (medido) e "se todas as UFs caíssem ao pior cenário" (extrapolação descritiva) precisa estar visível.
2. **Conservadorismo no `off`.** Quando há dúvida sobre o cenário sem política, escolhemos a hipótese que **subestima** a desigualdade, não que a infla. É uma escolha epistêmica: o protótipo deve resistir à crítica metodológica de qualquer ponto da sociedade civil.
3. **Não há cenário "ideal" com toda política ativa.** Só real ↔ ausência da política específica. Cenários compostos seriam tentadores mas multiplicariam pressupostos.
4. **n mínimo por célula:** 100 alunos / 5 UFs / 100 municípios. Abaixo disso, exibe `null` (não tenta extrapolar).

### 2.3 Limitações estruturais que devem ser comunicadas

- Os três contrafactuais não foram calculados por modelagem causal própria do Observatório (DiD, RDD, IV). São, em ordem: dado bruto histórico, transcrição da literatura, e comparação cross-section.
- A escolha do **denominador** (escolas públicas? rede municipal? todas?) afeta o valor absoluto mostrado. Mantemos públicas como padrão (representa 87% da matrícula da educação básica brasileira).
- A escolha do **corte de "adequado"** afeta L3 (vinculado ao SAEB). Adotamos o corte oficial INEP (≥ 225 para LP 5º EF; ≥ 275 para 9º EF; ≥ 325 para 3º EM), documentado em `04_governanca_dado.md`.

---

## 3. Caso 1 — L3 · "Infraestrutura como direito" (Tipo C — comparativo cross-section)

### 3.1 Pergunta de leitura

> *"E se nenhuma escola pública brasileira tivesse os três itens básicos de infraestrutura (água potável, banheiro acessível PNE, alimentação escolar)?"*

### 3.2 Fontes e cálculo

**Bases:**
- Censo Escolar 2025 — `Tabela_Escola_2025.csv`, indicadores `IN_AGUA_POTAVEL`, `IN_BANHEIRO_PNE`, `IN_ALIMENTACAO` (180.540 escolas em funcionamento).
- SAEB 2023 microdados aluno — `PROFICIENCIA_LP_SAEB`, escolas públicas (`IN_PUBLICA == 1`).

**Passos** (em [`pipeline/R/12_gerar_L3.R`](../pipeline/R/12_gerar_L3.R)):

1. Marca cada escola com `infra_3_3 = (IN_AGUA_POTAVEL == 1) & (IN_BANHEIRO_PNE == 1) & (IN_ALIMENTACAO == 1)`.
2. Agrega por UF: `pct_3_3 = mean(infra_3_3) * 100` (% de escolas com os 3 itens). Resultado nacional: **45,7%** das escolas têm todos os 3 itens; **54,3% faltam ao menos um**.
3. Por UF, calcula `% alunos adequados` (proficiência ≥ 225 em LP), ponderado pelo número de alunos da UF.
4. Ordena as 27 UFs pela `pct_3_3` e quartiliza em Q1 (menos infra) a Q4 (mais infra), 6-7 UFs por grupo.
5. **Contrafactual `off`**: todas as UFs caem para o valor de `% adequado` observado em Q1 (24,8%).

> **Por que essa formulação de `off`?** A interpretação intuitiva é: *"se nenhuma escola tivesse os itens básicos, a aprendizagem em todas as UFs convergiria para o pior cenário hoje observável".* Mais conservador do que extrapolar uma "curva de dose-resposta" inexistente.

### 3.3 Mini-relatório dos resultados

| Quartil | Infra (% escolas 3/3) | % adequado (real) | % adequado (off) | Diferença |
|---|---|---|---|---|
| Q1 (menos infra) | 30,8% | **24,8%** | 24,8% | 0,0 pp |
| Q2 | 43,9% | **38,8%** | 24,8% | −14,0 pp |
| Q3 | 51,6% | **41,9%** | 24,8% | −17,1 pp |
| Q4 (mais infra) | 65,5% | **44,3%** | 24,8% | −19,5 pp |

**Leitura:** UFs no Q1 já operam no patamar do contrafactual; UFs no Q4 perderiam 19,5 pp de aprendizagem adequada se a infraestrutura básica fosse removida — sem mencionar todos os efeitos secundários (frequência, evasão) que o exercício não captura. **A magnitude total subestima**.

### 3.4 Limitações

- **Não é causal.** Mostra correlação entre infra e aprendizagem após controle estrutural por UF. Não controla por NSE, gestão local, ou outros confundidores.
- O mismatch de chaves (`id_escola` SAEB ≠ `co_entidade` Censo Escolar) força agregação por UF — fica grosseiro. Município daria mais granularidade.
- O `off = Q1` é uma escolha conservadora; outros analistas poderiam adotar `off = média global pré-intervenção` (não disponível).

---

## 4. Caso 2 — L6 · "Bolsa Família como âncora de permanência" (Tipo B — literatura quasi-experimental)

### 4.1 Pergunta de leitura

> *"E se o Bolsa Família não condicionasse o benefício à frequência escolar?"*

### 4.2 Fontes e cálculo

**Bases:**
- Folha do Novo Bolsa Família, abril/2025, Portal da Transparência (CGU). Arquivo `202504_NovoBolsaFamilia.zip` (340 MB ZIP, 2,2 GB descompactado).
- Literatura quasi-experimental brasileira convergente: Cedeplar/UFMG (Cireno, Silva & Proença 2013), IPEA TD 2447 (Pereira & Soares 2019), Banco Mundial (Bourguignon et al. 2003), Fundação Itaú Social (FGV 2017).

**Passos** (em [`pipeline/R/15_gerar_L6.R`](../pipeline/R/15_gerar_L6.R) + leitor em [`04_ler_bolsa_familia.R`](../pipeline/R/04_ler_bolsa_familia.R)):

1. CSV de 2,2 GB lido em uma passada via `fread(cmd = "unzip -p ZIP CSV", select = c(3,4,9))` — só 3 colunas (UF, código município SIAFI, valor da parcela).
2. Agregação por UF e por município. Total nacional confirmado: **20.363.840 benefícios** em **5.570 municípios**, totalizando **R$ 13,6 bilhões** em abril/2025.
3. As **4 barras** mostradas no gráfico **não são recalculadas** internamente. Os valores `real` e `off` representam **estimativas convergentes da literatura** sobre o efeito do programa na conclusão do EM até 19 anos por quintil de renda.

> **Por que não recalcular?** Estimar o efeito causal do Bolsa Família exige microdado longitudinal (RAIS, CadÚnico, INEP integrados via SUS), pareamento por propensity score e controle por elegibilidade, recursos que extrapolam o escopo de uma plataforma de visualização. A literatura existente atende com rigor adequado e convergente.

### 4.3 Mini-relatório dos resultados

| Quintil de renda municipal | % conclui EM até 19 (real) | % conclui EM até 19 (off — sem PBF) | Diferença |
|---|---|---|---|
| 20% mais ricos | 92% | 91% | −1 pp |
| Renda média | 75% | 71% | −4 pp |
| 40% mais pobres | 58% | 51% | −7 pp |
| 20% mais pobres | 47% | 38% | −9 pp |

**Leitura:** o efeito é desigual por quintil — concentrado nos mais pobres, como esperado. A literatura converge em **3–7 pontos percentuais** de redução de evasão atribuível ao Bolsa Família. O **dado real da folha BF abril/2025 sustenta o callout temporal**: confirma a magnitude e a atualidade do programa, sem inferir efeito por dentro.

### 4.4 Limitações

- O contrafactual aqui é **citado, não medido pelo Observatório**. Toda a credibilidade está na revisão por pares da literatura referenciada.
- Folha de **1 mês** (abr/2025) pode não capturar sazonalidade (período de matrícula vs final do ano). Trocar por média anual quando for viável.
- A magnitude exata varia por estudo (3 pp em Cedeplar; 7 pp no Banco Mundial), por motivos metodológicos. Adotamos o intervalo conservador.

---

## 5. Caso 3 — L9 · "Sem Lei de Cotas, a composição racial regrediria" (Tipo A — série histórica direta)

### 5.1 Pergunta de leitura

> *"Como seria a composição racial dos ingressantes em IES públicas federais se a Lei 12.711/2012 não estivesse plenamente implementada?"*

### 5.2 Fontes e cálculo

**Bases:**
- Censo da Educação Superior 2024 — `MICRODADOS_CADASTRO_CURSOS_2024.CSV`, variáveis `QT_ING_BRANCA`, `QT_ING_PRETA`, `QT_ING_PARDA`, `QT_ING_AMARELA`, `QT_ING_INDIGENA`, `TP_CATEGORIA_ADMINISTRATIVA` (720.349 cursos / locais de oferta).
- Referência histórica pré-cotas: Censo da Educação Superior 2012 (INEP) e Pesquisa do Perfil Socioeconômico dos Estudantes de Graduação (ANDIFES, IV edição, 2014).

**Passos** (em [`pipeline/R/18_gerar_L9.R`](../pipeline/R/18_gerar_L9.R)):

1. Agrega ingressantes por categoria administrativa (`TP_CATEGORIA_ADMINISTRATIVA == 1` para Pública Federal).
2. Soma por raça/cor declarada (excluindo `CORND` — "cor/raça não dispõe da informação").
3. Calcula % sobre total de ingressantes com raça declarada.
4. **Contrafactual `off`:** valores observados em 2012 — `pre_pretos = 4,6%`, `pre_pardos = 23,5%`, `pre_brancos = 65,8%`, `pre_indigenas = 0,4%`. Esses são **dados brutos da série histórica**, não estimativas.

> **Por que esse tipo é "Forte"?** O contrafactual é literal — o que existia antes da política. Não há estimativa. A única hipótese implícita é "se a tendência pré-2012 tivesse continuado linearmente, sem outros choques", o que é frágil em janela de 12 anos. Por isso o badge cita "Evidência moderada", não "forte" — o efeito está no dado, mas a contagem do quanto é da Lei (vs políticas correlatas como Reuni, ProUni, Bolsa Permanência) exige modelagem adicional.

### 5.3 Mini-relatório dos resultados

| Raça | % ingressantes federais 2024 (real) | % ingressantes federais 2012 (off) | Diferença |
|---|---|---|---|
| Pretos | **11,9%** | 4,6% | +7,3 pp |
| Pardos | **39,9%** | 23,5% | +16,4 pp |
| Brancos | **45,7%** | 65,8% | −20,1 pp |
| Indígenas | **1,4%** | 0,4% | +1,0 pp |

**Pretos + Pardos:** **51,8%** em 2024 vs. 28,1% em 2012 → **+23,7 pontos percentuais** em 12 anos. Em termos absolutos: **168.688 ingressantes pretos+pardos** em IES Federais em 2024. **Brancos** caíram de 65,8% para 45,7% — não em número absoluto (que pode ter crescido), mas em participação relativa.

### 5.4 Limitações

- A Lei de Cotas é a hipótese central, mas opera em conjunto com Reuni (expansão de vagas, 2007-2012), ProUni (bolsas privadas, 2004), Bolsa Permanência (2013) e mudanças no ENEM. **Decompor o efeito puro da Lei exige diff-in-diff** entre federais (tratadas) e estaduais não-aderentes (controle), trabalho fora do escopo deste protótipo.
- Em 2012 as cotas já existiam parcialmente em algumas universidades (UnB desde 2004, UFBA desde 2005). A "Lei plena" da 12.711/2012 é a referência para o `off`, mas o cenário não é "zero cotas".
- O efeito retroativo no Ensino Médio (efeito-horizonte) é hipótese teórica derivada — não medida neste card.

---

## 6. Síntese — escolher o tipo certo

| Critério | Tipo A (série histórica) | Tipo B (literatura) | Tipo C (cross-section) |
|---|---|---|---|
| Qualidade da inferência | Alta (dado observado) | Alta (revisado por pares) | Baixa (descritivo, não causal) |
| Custo de produção | Médio (precisa série) | Baixo (citação) | Médio (cálculo próprio) |
| Risco de viés | Baixo se janela curta | Médio (depende dos estudos) | Alto (confundidores) |
| Quando usar | Política com pré/pós claro | Política com literatura sólida | Política sem janela clara, mas com heterogeneidade observável |
| Cuidado curatorial | Documentar tendência pré-política | Citar metodologias múltiplas | Conservadorismo no `off` |

**Recomendação para próximas rodadas:**

1. Migrar L3 de Tipo C para Tipo A quando o protótipo puder usar série histórica do Censo Escolar (2018→2025) e detectar UFs/municípios que mudaram de quartil de infra.
2. Substituir L8 (atualmente autodeclaração SAEB Q20) por contrafactual Tipo A baseado em Taxas de Rendimento INEP, quando essa base for incorporada ao pipeline.
3. Adicionar um quarto contrafactual sobre PNAE (Programa Nacional de Alimentação Escolar) seguindo o padrão Tipo B (literatura UFV, UnB, FGV) — pendência mencionada no [`05_backlog.md`](./05_backlog.md) (ticket B5).

## 7. Reprodutibilidade

Todos os números deste documento podem ser regenerados executando:

```bash
cd pipeline
Rscript R/12_gerar_L3.R   # L3
Rscript R/15_gerar_L6.R   # L6
Rscript R/18_gerar_L9.R   # L9
```

Os JSONs resultantes ficam em `pipeline/data/agregados/L3.json`, `L6.json`, `L9.json`. Cada um tem o timestamp `meta.gerado_em` para rastreabilidade.

Pipeline completo descrito em [`06_como_rodar.md`](./06_como_rodar.md).

---

*Documento aberto a comentários. Sugestões e correções vão via Pull Request no GitHub ou email para a equipe NEES/UFAL.*
