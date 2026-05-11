# Backlog de tickets — fronteiras claras de responsabilidade

## Como interpretar este backlog

Os tickets estão agrupados por **responsável** (front, back, conteúdo, infra), com **prioridade** (P0/P1/P2) e **dependências**. Use como base para uma sprint de 2-3 semanas.

---

## BACK · pipeline e dados

### B1 · [P0] Migrar pipeline R para servidor (cron)
**Contexto:** Hoje o pipeline R roda na máquina do pesquisador. Para o site ficar vivo, precisa rodar agendado.
**Aceitação:**
- [ ] R 4.5+ instalado no servidor com pacotes `data.table`, `arrow`, `jsonlite`, `openpyxl` (Python opcional).
- [ ] Script `run_all.R` que roda os 14 scripts em sequência.
- [ ] Cron mensal (ou pós-publicação INEP) que regera os JSONs em `pipeline/data/agregados/`.
- [ ] Logs persistidos em `pipeline/pipeline_run.log`.

### B2 · [P0] Endpoint estático para servir os JSONs e GeoJSON
**Aceitação:**
- [ ] Servidor web (nginx/Apache/CDN) servindo `pipeline/data/agregados/*.json` e `pipeline/data/agregados/geo/*.geojson` com CORS adequado.
- [ ] Cache-Control compatível com versionamento (ex.: ETag por arquivo).
- [ ] gzip ou brotli ligado (JSONs comprimem 10x).

### B3 · [P1] Validação automática dos JSONs antes de publicar
**Aceitação:** script `validate_jsons.R` que checa:
- [ ] Cada arquivo abre como JSON válido.
- [ ] `meta.n_total` > 100.
- [ ] Em `mapa.json`, cada camada tem 27 chaves (UFs).
- [ ] Nenhuma viz com array vazio.
**Saída esperada:** exit code 0 se OK, 1 se algo falhar. Bloqueia o deploy.

### B4 · [P1] Baixar Taxas de Rendimento INEP (pendente manual)
**Contexto:** A leitura L8 precisa de complemento oficial.
**Aceitação:**
- [ ] Baixar zips de https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/indicadores-educacionais/taxas-de-rendimento-escolar (anos 2023, 2024).
- [ ] Adicionar `06_ler_taxas_rendimento.R` que lê e gera parquet.
- [ ] Atualizar `17_gerar_L8.R` para incluir taxa oficial agregada como complemento da autodeclaração.

### B5 · [P2] Baixar PNAE FNDE (pendente manual)
**Contexto:** Se o contrafactual L3 quiser voltar a falar de PNAE.
**Aceitação:**
- [ ] Baixar dataset PNAE de https://dados.gov.br/dados/conjuntos-dados/programa-nacional-de-alimentacao-escolar-pnae
- [ ] Adicionar `07_ler_pnae.R`.
- [ ] Refazer L3 (ou criar L3b alternativo) com PNAE.

### B6 · [P2] Equivalência SAEB↔IBGE de códigos de município
**Contexto:** Hoje agregamos por UF para evitar mismatch. Município daria mais granularidade.
**Aceitação:**
- [ ] Tabela de-para `id_municipio_saeb` → `co_municipio_ibge` (CO_ENTIDADE não bate — investigar com INEP via LAI ou achar dicionário).
- [ ] Refazer L3 e L4 com agregação por município.

---

## FRONT · apresentação React

### F1 · [P0] Migrar protótipo HTML para React + Vite
**Contexto:** Hoje é um único HTML de 2400 linhas com `<script>` D3 inline. Para produção precisa virar SPA componentizada.
**Stack alvo:** React 18 + Vite + TypeScript + D3 v7 + react-simple-maps (opcional).
**Aceitação:**
- [ ] Repositório Vite criado com TypeScript.
- [ ] Estrutura de pastas:
  ```
  src/
    App.tsx
    components/
      NavBrandBar.tsx
      DimensionCards.tsx
      ReadingTabs.tsx
      StoryCard.tsx
      CounterfactualToggle.tsx
      ExploreMap.tsx
      Sidebar.tsx
    viz/
      VizL1.tsx ... VizL9.tsx
      MapBrasil.tsx
    data/             // JSONs estáticos para dev
    types/            // schemas dos contratos
    styles/           // CSS vars do protótipo
  ```
- [ ] Tipos TypeScript para cada `LX.json` (gerar via `quicktype` a partir dos JSONs atuais).
- [ ] CSS migrado preservando 100% da estética (Lora + Work Sans + paleta laranja-marrom-creme).

### F2 · [P0] Componentizar 9 leituras
**Aceitação:**
- [ ] Cada `VizL*.tsx` recebe `payload: LXData` como prop.
- [ ] D3 dentro de `useEffect` (template no `handoff/01_arquitetura.md`).
- [ ] **Reuso máximo do código D3 do protótipo** — não reinventar as vizs.
- [ ] Test render: cada componente renderiza com payload de teste sem erro.

### F3 · [P0] Componentizar mapa
**Aceitação:**
- [ ] `MapBrasil.tsx` carrega GeoJSON e renderiza com `d3.geoMercator` + `d3.geoPath`.
- [ ] Aceita prop `camada: keyof MapData['camadas']`.
- [ ] Hover destaca UF, click no filtro troca camada.
- [ ] Sidebar de ranking embutida ou componente separado.

### F4 · [P1] Sistema de placeholders dinâmicos
**Contexto:** O protótipo usa `{{narrativa.media_brasil}}` que é substituído após fetch.
**Aceitação:**
- [ ] Helper `applyPlaceholders(template: string, payload: LXData): string`.
- [ ] Templates de copy em arquivo `content/copy.ts` (não em HTML).
- [ ] Editar copy não exige rebuild do código JS.

### F5 · [P1] Loading states e fallbacks
**Aceitação:**
- [ ] Spinner suave enquanto JSONs carregam (não tela em branco).
- [ ] Mensagem amigável se um JSON falhar (não quebra o resto).
- [ ] Mensagem de "atualizando dados — última atualização: dd/mm/aaaa" no rodapé.

### F6 · [P1] Acessibilidade (a11y)
**Aceitação:**
- [ ] Contraste WCAG AA em todas as paletas.
- [ ] Navegação por teclado nos filtros e toggles do contrafactual.
- [ ] ARIA labels em vizs SVG complexas.
- [ ] Texto alternativo para o mapa (lista UFs + valores quando o foco entra no SVG).

### F7 · [P2] Responsive design
**Aceitação:**
- [ ] Mobile (375px): cards empilhados, mapa redimensionado, sidebar embaixo do mapa.
- [ ] Tablet (768px): layout intermediário.

### F8 · [P2] Tooltip rico no mapa
**Contexto:** Hoje é `<title>` SVG do navegador (feio mas funcional).
**Aceitação:**
- [ ] Tooltip HTML customizado, com estética alinhada à paleta do projeto.
- [ ] Mostra: UF, valor da camada atual, comparação Brasil, n alunos.

---

## CONTEÚDO · curadoria e copy

### C1 · [P0] Revisar copy de cada leitura com pesquisadores
**Aceitação:**
- [ ] Cada uma das 9 leituras revisada com 2 pesquisadores do NEES.
- [ ] Validação metodológica dos cortes (especialmente L1 corte ≥ 200; L3 contrafactual; L8 aviso).
- [ ] Citações qualitativas conferidas (Cavalleiro, Yosso, Paraíso, Reay, etc. — referências completas em ABNT).

### C2 · [P0] Página "Sobre" e "Metodologia"
**Aceitação:**
- [ ] Página `/sobre` explicando o Observatório, equipe NEES, instituições parceiras.
- [ ] Página `/metodologia` com tabela de fontes, política de atualização, limitações conhecidas (base em `handoff/04_governanca_dado.md`).

### C3 · [P1] Política de citação + DOI
**Aceitação:**
- [ ] Cadastro do Observatório no DOI Foundation (via UFAL).
- [ ] Cada leitura tem âncora citável.
- [ ] Botão "Copiar citação ABNT" em cada página.

---

## INFRA · deploy e operação

### I1 · [P0] Domínio e DNS
**Aceitação:**
- [ ] Subdomínio `equidade.nees.ufal.br` apontado para hospedagem do build estático.
- [ ] Certificado HTTPS válido.

### I2 · [P0] Pipeline CI/CD
**Aceitação:**
- [ ] GitHub Actions (ou GitLab CI) que: (1) roda validação B3, (2) builda React, (3) faz deploy.
- [ ] Triggers: commit em `main` (deploy front); commit em `pipeline/` ou cron (regera JSONs e redeploy).

### I3 · [P1] Monitoramento
**Aceitação:**
- [ ] Uptime monitor (UptimeRobot ou similar) checando o site a cada 5 min.
- [ ] Google Analytics ou Plausible para tráfego.
- [ ] Alertas se um JSON estiver desatualizado > 90 dias.

### I4 · [P2] Backup
**Aceitação:**
- [ ] Backup semanal de `pipeline/data/processed/*.parquet` (microdados tratados).
- [ ] Backup diário dos JSONs em `pipeline/data/agregados/`.
- [ ] Retenção: 90 dias.

---

## Ordem sugerida

**Sprint 1 (2 semanas):**
- B1, B2 (pipeline rodando no servidor + JSONs servidos)
- F1 (skeleton React + tipos)
- C1 (revisão de copy)
- I1 (domínio)

**Sprint 2 (2 semanas):**
- F2, F3 (vizs + mapa)
- F4 (placeholders)
- B3 (validação)

**Sprint 3 (1-2 semanas):**
- F5, F6 (loading + a11y)
- C2 (sobre + metodologia)
- I2 (CI/CD)
- B4 (Taxas Rendimento INEP)

**Backlog futuro:**
- F7, F8, C3, B5, B6, I3, I4

## Critério de "pronto para publicar"

- [ ] Todos os P0 fechados
- [ ] Validação B3 passa
- [ ] Revisão metodológica C1 concluída
- [ ] HTTPS funcionando
- [ ] Página de Sobre/Metodologia ar
- [ ] Pelo menos 1 ciclo manual de regeneração de JSONs testado
