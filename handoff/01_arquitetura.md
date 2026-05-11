# Arquitetura — Observatório de Equidade Educacional

Documento base para o time de front e back. Define a estratégia em 3 fases e a stack escolhida para que o protótipo HTML+D3 (`prototipo/insights3.html`) vire app navegável vinculado ao site do observatório.

## Princípio de desenho

O protótipo é uma peça **storytelling-first**: cada uma das nove leituras é uma viz D3 acompanhada de copy curatorial e diálogo com pesquisa qualitativa. Isso impõe três restrições:

1. **Estética custom não-negociável** — fontes Lora + Work Sans, paleta laranja-marrom-creme, layout em duas colunas com narrativa e gráfico lado a lado. Dashboards genéricos (Shiny default, Power BI, Looker) não cabem.
2. **Cada viz tem lógica própria em D3** — não é "uma viz parametrizável por tipo". São nove vizs custom + um mapa.
3. **Os dados são pré-computados** — agregados públicos do INEP, IBGE, Portal da Transparência etc. Nunca rodaríamos microdados em runtime (4 GB de SAEB não cabem no browser; e há implicação de LGPD em microdados, mesmo agregando).

A consequência prática: a separação certa é **dado / apresentação**, não **API ao vivo / cliente**. Pré-computar JSONs e servir estático cobre 100% do uso público sem servidor de aplicação rodando.

## Stack recomendada

| Camada | Escolha | Justificativa |
|---|---|---|
| **Ingestão e tratamento** | **R + `arrow` + `data.table`** | Usuário já tem fluência em R; SAEB tem 1 GB por arquivo — `data.table::fread` segura; saída em parquet é leve para iteração. |
| **Agregação para o front** | R script que lê `processed/*.parquet` e escreve `agregados/*.json` | Um JSON por leitura + um JSON do mapa. Versionados no git. |
| **Prototipagem dinâmica** (Fase 1) | HTML único + D3 com `fetch('/agregados/L1.json')` | Adapta o protótipo atual com mínima mudança. Roda em qualquer servidor web (Python `http.server` para dev). |
| **Produção** (Fase 3) | **React + Vite + D3 + TopoJSON** | Comunidade BR grande; `react-simple-maps` para o mapa do Brasil; D3 funciona dentro de `useEffect`; build estático sai como pasta `dist/`. |
| **Estilização** | CSS atual (já bem estruturado em `:root` vars) — opcionalmente migrar para Tailwind no React | Manter paleta e fontes exatas do protótipo. |
| **Hospedagem** | **Subdomínio `equidade.nees.ufal.br`** apontando para build estático no servidor NEES OU subpasta `/observatorio/equidade/` | Build estático cabe em qualquer hospedagem; sem servidor de aplicação. |
| **Atualização de dados** | Cron mensal/anual rodando o pipeline R → commit dos JSONs → redeploy automático | INEP publica anualmente; portal transparência mensalmente. |

### Por que **não** Shiny

- Estética custom é trabalhosa em Shiny (HTML/CSS sobrescrito) — não compensa.
- shinyapps.io free tem limite de horas; servidor próprio Shiny exige R rodando.
- Time de front trabalha com JS, não R.

### Por que **não** Streamlit / Dash / Observable

- Streamlit/Dash: mesma crítica do Shiny — dashboard genérico não cobre storytelling.
- Observable Notebook: ótimo para protótipo, mas para produção embedada no site institucional fica frágil.

### Por que **não** Quarto Dashboard

- Quarto é ótimo para relatório, mas as três dimensões + 9 leituras + mapa interativo + contrafactual com toggle são interações que extrapolam o que Quarto faz natural — empurraria de volta para JS custom.

## Estratégia em 3 fases

### Fase 1 — Protótipo Dinâmico

**Quem faz:** Claude + usuário, nesta e nas próximas conversas.
**Objetivo:** Substituir os dados hardcoded do `insights3.html` por `fetch()` aos JSONs reais gerados pelo pipeline.
**Entrega:** versão `insights3_dinamico.html` + pasta `agregados/` com 10 JSONs (L1-L9 + mapa). Roda local com `python3 -m http.server`. Stakeholders podem navegar.

**Passos:**

1. **Pipeline R** (`pipeline/R/`):
   - `01_ler_saeb_2023.R` — lê CSVs do SAEB com `fread`, mantém só vars usadas, grava parquet em `processed/`.
   - `02_ler_censo_escolar_2025.R` — lê Tabela_Escola + Tabela_Matricula, joga em parquet.
   - `03_ler_censo_superior_2024.R` — lê cadastro de cursos, agrega por TP_CATEGORIA × cor.
   - `04_ler_bolsa_familia.R` — lê CSV de 2,2 GB em chunks, agrega por município.
   - `05_ler_sidra.R` — converte JSON SIDRA para parquet (pop 0-3 por município).
2. **Agregador** (`pipeline/R/10_gerar_jsons.R`):
   - Cada leitura tem função `gerar_L1()`, `gerar_L2()`, etc., que produz o JSON exato no schema do contrato de dados.
   - Output em `data/agregados/L*.json` e `mapa.json`.
3. **HTML dinâmico** (`prototipo/insights3_dinamico.html`):
   - Copia o atual, remove os arrays hardcoded dentro das funções `viz`, substitui por `await fetch('data/agregados/L1.json').then(r=>r.json())`.

### Fase 2 — Handoff para o time

**Quem faz:** Claude + usuário, depois da Fase 1 funcional.
**Objetivo:** Empacotar tudo para um time de front+back receber e construir a versão React produção.
**Entrega:** pasta `handoff/` com:

- `01_arquitetura.md` (este documento)
- `02_spec-funcional.md` — uma página por leitura: copy, viz, variáveis, recortes, fonte
- `03_data-contract.md` — schema JSON de cada `L*.json` e do `mapa.json`, com exemplo
- `04_governanca-dado.md` — fontes, badges de evidência, política de atualização, LGPD, citação
- `05_backlog.md` — tickets desagregados (front, back, conteúdo)
- `prototipo/insights3_dinamico.html` — referência visual viva
- `data/agregados/*.json` — dados estáticos para o front desenvolver sem depender do back ainda

### Fase 3 — Produção

**Quem faz:** time de front e back do observatório/NEES, com supervisão do usuário.
**Objetivo:** App React deployado em `equidade.nees.ufal.br` ou subpasta do site, lendo JSONs servidos pelo backend.
**Entrega:** repositório React + pipeline R em CI, atualização agendada.

**Componentes que o time monta a partir do nosso protótipo:**

```
src/
├── App.tsx                            roteamento + navegação principal
├── components/
│   ├── NavBrandBar.tsx
│   ├── PageHeader.tsx
│   ├── DimensionCards.tsx             3 cards de dimensão (level 1)
│   ├── ReadingTabs.tsx                3 tabs por dimensão (level 2)
│   ├── StoryCard.tsx                  card de leitura — recebe `reading: L1Data`
│   ├── CounterfactualToggle.tsx       toggle "real / e se..."
│   ├── EvidenceBadge.tsx              badge "evidência forte/moderada/indireta"
│   ├── QualiInDialog.tsx              bloco "em diálogo com a pesquisa qualitativa"
│   └── ExploreMap.tsx                 mapa do Brasil + filtros + ranking
├── viz/
│   ├── VizL1.tsx ... VizL9.tsx        nove componentes D3 (cada um um useEffect)
│   └── MapBrasil.tsx                  d3-geo + TopoJSON IBGE
├── data/                              JSONs estáticos OU URLs do backend
└── styles/                            CSS vars do protótipo
```

**Cada `VizL*.tsx`** segue o template:

```tsx
import { useEffect, useRef } from 'react';
import * as d3 from 'd3';

export function VizL1({ data }: { data: L1Data }) {
  const ref = useRef<SVGSVGElement>(null);
  useEffect(() => {
    if (!data || !ref.current) return;
    // código D3 do protótipo, com `data` em vez de hardcoded
  }, [data]);
  return <svg ref={ref} viewBox="0 0 520 320" />;
}
```

A ideia é que o time não reinvente as vizs — copia o D3 do protótipo, troca os dados pelas props.

## Plano de vinculação ao site do observatório

Três cenários, em ordem de preferência:

1. **Subdomínio** `equidade.nees.ufal.br` — apontar DNS para o build estático (S3+CloudFront, Vercel, Netlify, ou Apache do servidor NEES). Mais limpo. **Recomendado.**
2. **Subpasta** `www.nees.ufal.br/observatorio/equidade/` — exige que o React seja buildado com `vite build --base=/observatorio/equidade/`. Funciona, demanda configuração de routing no Apache/nginx.
3. **iframe embed** dentro de uma página do site institucional. Menos limpo, mas zero fricção de deploy. Útil só para fase de comunicação inicial.

## Replicabilidade do layout

O HTML atual do protótipo pode ser replicado 1:1 em React. Provas:

- **Tipografia**: Lora + Work Sans via `@import` Google Fonts — funciona igual.
- **Layout**: grid CSS já está modular (`level-1`, `level-2`, `story-card`) — vira componentes JSX.
- **Cores**: variáveis CSS `:root` — viram tokens do design system.
- **Animações**: `transition` CSS e D3 `.transition()` — funcionam em React.
- **Mapa do Brasil**: `react-simple-maps` + TopoJSON do IBGE — equivalente ao SVG estático do protótipo.

**O risco real do handoff não é técnico — é fidelidade.** O time pode "embelezar" e quebrar a estética curatorial. Mitigação:

- Entregar o protótipo dinâmico como **referência visual viva**.
- Spec funcional incluir screenshots anotados de cada card.
- Code review obrigatório com o usuário a cada componente entregue.

## Pendências técnicas conhecidas

1. **Tamanho do CSV do Bolsa Família** (2,2 GB descompactado) — pipeline R deve ler em chunks com `data.table::fread(..., nrows=, skip=)` ou via `arrow::open_dataset()`. Nunca carregar inteiro em memória.
2. **L8 reescrita** — usar Taxas de Rendimento INEP pré-calculadas em vez de coorte longitudinal. **No copy do card, ser explícito**: "Taxa anual de abandono escolar — não é coorte rastreada individualmente. O INEP descontinuou em 2022 a publicação do microdado aluno-a-aluno que permitiria o matching `CO_PESSOA_FISICA`."
3. **Censo Escolar 2025 é agregado por escola** — cruzamentos finos (raça × sexo × INSE × etapa por aluno individual) não dão pelo Censo Escolar atual; só pelo SAEB (que tem questionário aluno).
4. **Atualização do mapa**: precisa decidir periodicidade. SAEB é bienal (2021 → 2023 → 2025), Censo Escolar é anual, Censo Demográfico é decenal. Os anos das séries no mapa não são todos iguais — copy precisa indicar.
