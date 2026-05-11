# Observatório de Equidade Educacional

Iniciativa NEES/UFAL para qualificar a leitura pública dos dados educacionais brasileiros com lente interseccional. Nove leituras curatoriais (3 dimensões × 3 cards, sendo 3 contrafactuais) + mapa navegável. Será app web que se vincula ao site do observatório.

## Status atual (2026-05-11)

### Bases na máquina

| Pasta | Tamanho | Conteúdo | Cobre leituras |
|---|---|---|---|
| `pipeline/data/raw/saeb_2023/` | 3,0 GB | SAEB 2023 microdados — aluno 5EF (2,44 M linhas), aluno 9EF (2,50 M), aluno 3EM (2,09 M) + escola, diretor, professor, item | L1, L2, L5 (parte), L7 |
| `pipeline/data/raw/censo_escolar_2025/` | 399 MB | Censo Escolar 2025 **agregado por escola** (Escola 214k linhas, Matrícula 178k linhas — `QT_MAT_BAS_FEM/MASC/BRANCA/PRETA/PARDA/AMARELA/INDIGENA`) | L4 (creche), L5 (infra), mapa |
| `pipeline/data/raw/censo_superior_2024/` | 433 MB | Censo Ed. Superior 2024 — cadastro IES (2.562) + cadastro cursos (com `QT_ING_PRETA/PARDA/BRANCA` × `TP_CATEGORIA_ADMINISTRATIVA`) | L9 (Lei de Cotas) |
| `pipeline/data/raw/bolsa_familia/` | 342 MB (ZIP) · 2,2 GB (CSV abr/2025) | Novo Bolsa Família — folha de pagamento nacional abril 2025 (Portal da Transparência) | L6 (contrafactual) |
| `pipeline/data/raw/censo_demografico_2022/` | 8 MB | SIDRA tabela 9514 — pop. 0-3 anos por município (5570) Censo 2022 (JSON) | L4 (denominador creche) |

### Dicionários em `pipeline/anexos/`

- `Dicionario_Saeb_2023.xlsx` (e `.ods`) — confirmado: Q01 (sexo), Q04 (raça), Q08/Q09 (escolaridade pais), Q19 (reprovação), Q20 (abandono), Q21c (trabalho doméstico), Q23a-i (clima), INSE_ALUNO, PROFICIENCIA_LP/MT — todas presentes em 5EF e 9EF.
- `dicionário_dados_educação_básica.xlsx` — Tabelas Escola/Matrícula/Docente/Turma/Gestor/Curso Técnico (cabeçalho na linha 7).
- `dicionário_dados_educação_superior.xlsx` — cadastro_ies + cadastro_cursos.

### Cobertura das 9 leituras

| Leitura | Status | Observação |
|---|---|---|
| L1 SAEB raça×sexo×INSE | ✅ pronto | SAEB 2023 + INSE_ALUNO |
| L2 escolaridade da mãe | ✅ pronto | Q08/Q09 SAEB 9EF |
| L3 PNAE contrafactual | ⏳ download manual | Página FNDE é JS dinâmico — baixar de https://dados.gov.br/dados/conjuntos-dados/programa-nacional-de-alimentacao-escolar-pnae |
| L4 creche → SAEB | ✅ pronto | QT_MAT_INF_CRE (Censo Escolar 2025) ÷ pop 0-3 (SIDRA 9514) |
| L5 tempo+infra+clima | ✅ pronto | SAEB Q21c/Q23 + IN_BANHEIRO_PNE / TP_LOCALIZACAO Censo Escolar |
| L6 Bolsa Família | ✅ base na mão | folha abr/2025 (1 mês representativo; série anual depois) |
| L7 reprovação→abandono | ✅ pronto | SAEB Q19/Q20 |
| **L8 coorte 2022→2023** | ⚠️ **REESCRITA** | Censo Escolar agregado desde 2022 não tem `CO_PESSOA_FISICA`. **Decisão: usar Taxas de Rendimento INEP pré-calculadas + ser transparente no relatório** que não é coorte longitudinal real, é taxa anual de abandono |
| L9 Lei de Cotas | ✅ pronto | QT_ING_PRETA/PARDA × TP_CATEGORIA_ADMINISTRATIVA Censo Superior 2024 |
| Mapa navegável | ✅ pronto | Tabela_Escola_2025 (LAT/LONG) + agregações por município |

### Pendências para download manual

Páginas dinâmicas (JS) não cedem a raspagem. Sugestão de download manual via navegador:

1. **Taxas de Rendimento Escolar 2024** (para L8 reescrita) — https://www.gov.br/inep/pt-br/acesso-a-informacao/dados-abertos/indicadores-educacionais/taxas-de-rendimento-escolar → aba 2024 → ZIP municípios. Colocar em `pipeline/data/raw/taxas_rendimento_inep/`.
2. **PNAE — execução por município/ano** (para L3 contrafactual) — https://dados.gov.br/dados/conjuntos-dados/programa-nacional-de-alimentacao-escolar-pnae → recurso CSV transferências. Colocar em `pipeline/data/raw/pnae/`.

## Estrutura do projeto

```
Observatorio_Equidade_Educacional/
├── README.md                          este arquivo
├── prototipo/                         HTMLs em D3 (insights3.html é o vigente)
├── pipeline/
│   ├── R/                             scripts R (a escrever)
│   ├── anexos/                        dicionários oficiais INEP
│   ├── data/
│   │   ├── raw/                       dumps originais (ZIPs/CSV)
│   │   ├── processed/                 parquet tratado por fonte (a gerar)
│   │   └── agregados/                 JSONs pré-computados para o front (a gerar)
│   └── docs/                          dicionário do projeto + notas QuantCrit
└── handoff/                           entregáveis para time de front e back
    └── 01_arquitetura.md              estratégia em 3 fases (criado)
```

## Status atual (2026-05-11)

- ✅ Pipeline R completo (5 leitores + 9 geradores + mapa) gerando JSONs em `pipeline/data/agregados/`
- ✅ Protótipo dinâmico em `prototipo/insights3_dinamico.html` consumindo os JSONs via `fetch()`
- ✅ Mapa navegável com geometria real do Brasil + 6 camadas + ranking
- ✅ Pacote de handoff em `handoff/` pronto para o time de produção

## Como rodar localmente

Ver [handoff/06_como_rodar.md](handoff/06_como_rodar.md). Rápido:

```bash
# Rodar pipeline
cd pipeline
for s in R/01_*.R R/02_*.R R/03_*.R R/04_*.R R/05_*.R; do Rscript "$s"; done
for s in R/1*_gerar_*.R R/20_gerar_mapa.R; do Rscript "$s"; done

# Servir protótipo
cd ..
python3 -m http.server 8731
# Navegar para http://localhost:8731/prototipo/insights3_dinamico.html
```

## Entrega para o time de produção

Pacote completo em [handoff/README.md](handoff/README.md). Conteúdo: arquitetura, data contract, spec funcional, governança, backlog e instruções de execução.
