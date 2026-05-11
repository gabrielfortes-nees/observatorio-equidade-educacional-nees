# Como rodar — instalação + execução

## Pré-requisitos

- **R 4.5+** (qualquer 4.x recente serve)
- Pacotes R: `data.table`, `arrow`, `jsonlite`
- **Python 3.9+** (só para servir o protótipo localmente; opcional)
- **curl** ou navegador para baixar bases públicas
- **Disco:** ~10 GB livres para microdados originais; ~500 MB para parquets tratados

### Instalar pacotes R

No terminal:

```bash
R -e 'install.packages(c("data.table", "arrow", "jsonlite"), repos="https://cran.r-project.org")'
```

## Estrutura esperada da pasta antes de rodar

```
Observatorio_Equidade_Educacional/
├── pipeline/
│   ├── R/                                 (scripts — já vêm prontos)
│   ├── anexos/                            (dicionários — já vêm prontos)
│   └── data/
│       ├── raw/
│       │   ├── saeb_2023/                 ← MICRODADOS SAEB (≈3 GB)
│       │   ├── censo_escolar_2025/        ← Censo Escolar (≈400 MB)
│       │   ├── censo_superior_2024/       ← Censo Sup (≈430 MB)
│       │   ├── bolsa_familia/             ← ZIP da folha BF (≈340 MB)
│       │   └── censo_demografico_2022/    ← JSON SIDRA (≈8 MB)
│       ├── processed/                     (parquets — gerados pelo pipeline)
│       └── agregados/                     (JSONs — gerados pelo pipeline)
└── prototipo/
    └── insights3_dinamico.html
```

## Baixar dados originais (primeira vez)

| Base | Onde | Tamanho |
|---|---|---|
| SAEB 2023 microdados aluno | gov.br/inep → Microdados → SAEB 2023 | 3 GB |
| Censo Escolar 2025 microdados | gov.br/inep → Microdados → Censo Escolar 2025 | 400 MB |
| Censo Educação Superior 2024 | gov.br/inep → Microdados → Educação Superior 2024 | 430 MB |
| Bolsa Família abr/2025 | `curl -L -o 202504_NovoBolsaFamilia.zip "https://portaldatransparencia.gov.br/download-de-dados/novo-bolsa-familia/202504"` | 340 MB |
| SIDRA tabela 9514 (pop 0-3) | `curl -o pop_0_3_municipios_2022.json "https://apisidra.ibge.gov.br/values/t/9514/n6/all/v/93/p/2022/c287/6557,6558,6559,6560/c2/0"` | 8 MB |
| GeoJSON Brasil | `curl -L -o brazil-states.geojson "https://raw.githubusercontent.com/codeforgermany/click_that_hood/master/public/data/brazil-states.geojson"` | 3 MB |

Para SAEB, Censo Escolar e Censo Superior: baixe os ZIPs do site do INEP, descompacte, mantenha os arquivos `.csv` direto na pasta `raw/<base>/` (sem subpastas extras).

## Executar pipeline completo

```bash
cd ~/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline

# Rodar tudo em ordem (leva ~2-5 min):
Rscript R/01_ler_saeb_2023.R        # ≈22s — 3 parquets de SAEB
Rscript R/02_ler_censo_escolar_2025.R
Rscript R/03_ler_censo_superior_2024.R
Rscript R/04_ler_bolsa_familia.R    # ≈40s — lê 2,2 GB descompactado via pipe
Rscript R/05_ler_sidra.R

# Gerar JSONs (cada um <5s):
Rscript R/10_gerar_L1.R
Rscript R/11_gerar_L2.R
Rscript R/12_gerar_L3.R
Rscript R/13_gerar_L4.R
Rscript R/14_gerar_L5.R
Rscript R/15_gerar_L6.R
Rscript R/16_gerar_L7.R
Rscript R/17_gerar_L8.R
Rscript R/18_gerar_L9.R
Rscript R/20_gerar_mapa.R
```

Output esperado:

```
[hh:mm:ss] L1 ✓  | média BR: 58.6%  | gap racial: 8.4 pp  | gap topo-chão: 25.0 pp
[hh:mm:ss] L2 ✓ | gap mãe = 38.3 pts · gap pai = 32.3 pts · diferença = 6.0
...
[hh:mm:ss] MAPA ✓ | 27 UFs × 6 camadas
```

Cada arquivo final aparece em `pipeline/data/agregados/` (~9 JSONs de leitura + `mapa.json`).

## Servir o protótipo localmente (para testar)

```bash
cd ~/Documents/Claude/Projects/Observatorio_Equidade_Educacional
python3 -m http.server 8731
# Abrir no navegador: http://localhost:8731/prototipo/insights3_dinamico.html
```

⚠️ **Não funciona com `file://`** — o `fetch()` precisa de HTTP. Sem servidor as vizs ficam vazias.

## Atualizar quando uma fonte sair

1. Baixar a nova base em `data/raw/<fonte>/` (sobrescrever a anterior).
2. Re-rodar o leitor correspondente: ex. `Rscript R/01_ler_saeb_2023.R` para nova onda SAEB.
3. Re-rodar todos os geradores afetados (mais simples: rodar todos os `R/1*.R` e `R/20_gerar_mapa.R` de novo).
4. Validar: `python3 -c "import json; [print(json.load(open(f))['meta']['gerado_em']) for f in __import__('glob').glob('pipeline/data/agregados/*.json')]"`
5. Commitar `pipeline/data/agregados/*.json` no repo (são os artefatos publicados).

## Problemas conhecidos e soluções

**`fread` reclama de encoding** — o Bolsa Família vem em Latin-1. Já passamos `encoding = "Latin-1"` no script. Se vier outra base com mesmo issue, mesma flag.

**Memória estoura no `04_ler_bolsa_familia`** — o pipe `unzip -p` lê 2,2 GB. Se sua máquina tem <8 GB RAM, ajustar para ler em chunks:

```r
bf <- fread(..., nrows = 5000000)  # 1ª passada
# repetir com skip = 5000000 nas próximas
```

**Pacote `arrow` não instala** — em macOS, instalar primeiro: `brew install apache-arrow`. Depois: `R -e 'install.packages("arrow")'`.

**Algum gerador retorna `n_total = 0` ou `NA`** — geralmente é variável renomeada ou código alterado entre versões INEP. Conferir o dicionário `pipeline/anexos/Dicionario_Saeb_2023.xlsx`.

## Próxima vez que o INEP descontinuar algo

Históricamente o INEP muda formatos sem aviso (em 2022 descontinuou o microdado aluno-a-aluno do Censo Escolar). Quando isso acontecer:

1. Documentar a mudança em `pipeline/docs/CHANGELOG.md`.
2. Decidir entre: (a) usar agregado oficial, (b) pedir LAI, (c) reescrever a leitura.
3. Atualizar `handoff/04_governanca_dado.md` com a nova limitação.
4. Avisar visitantes via banner no site que aquela leitura específica usa metodologia alternativa pós-data-X.
