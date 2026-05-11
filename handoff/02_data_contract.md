# Data contract — JSONs consumidos pelo front

O front faz `fetch('./pipeline/data/agregados/<arquivo>.json')` e renderiza com D3. Cada arquivo tem o mesmo formato base; mudanças no schema **quebram o front**. Sempre versionar e validar.

## Formato geral

Todo arquivo `LX.json` segue:

```jsonc
{
  "meta": {
    "leitura": "LX",
    "titulo_curto": "...",
    "eyebrow": "...",         // sub-cabeçalho do card
    "fonte": "...",           // citação completa
    "n_total": 123456,        // tamanho da base após filtros
    "gerado_em": "2026-05-11 01:19:07",
    "contrafactual": true|false,  // só em L3, L6, L9
    "cf_key": "infra"|"bf"|"cotas",
    "aviso_metodologico": "..."   // só em L8
  },
  "narrativa": {              // valores escalares para popular o texto via {{narrativa.xxx}}
    "media_brasil": 58.6,
    "gap_racial_pp": 8.4,
    ...
  },
  "viz": {                    // tudo que a função viz consome
    "indicador": "...",
    "grupos": [...],          // ou bars, panel_a_dados etc.
    "anotacao": "..."
  }
}
```

## Schema por leitura

### L1 — % aprendizagem adequada × raça × sexo × INSE

```jsonc
{
  "meta": {...},
  "narrativa": {
    "media_brasil": 58.6,
    "media_branca_amarela": 64.4,
    "media_preta_parda": 56.0,
    "gap_racial_pp": 8.4
  },
  "viz": {
    "indicador": "% aprendizagem adequada em LP (proficiência ≥ 200)",
    "media_brasil": 58.6,
    "grupos": [
      { "label": "Meninos brancos · INSE alto", "value": 72.8, "n": 83527 },
      ...  // 8 grupos, ordem fixa
    ],
    "anotacao": "do topo ao chão: 25 pontos"
  }
}
```

### L2 — proficiência por escolaridade dos pais

```jsonc
{
  "viz": {
    "indicador": "...",
    "eixo_x": ["não compl.\nfund.", "EF até\n5º ano", "EF\ncompl.", "EM\ncompl.", "Superior\ncompl."],
    "eixo_y_min": 222,
    "eixo_y_max": 290,
    "serie_mae": [ { "x": 1, "x_label": "...", "y": 232.7, "n": 118488 }, ... ],
    "serie_pai": [ ... ],
    "anotacao": "mãe: +38 pontos · pai: +32 pontos"
  }
}
```

### L3 — contrafactual de infraestrutura

```jsonc
{
  "meta": { "contrafactual": true, "cf_key": "infra", ... },
  "viz": {
    "indicador": "...",
    "titulo_real": "Mais infraestrutura → mais aprendizagem",
    "titulo_off":  "Menos infraestrutura → mais distância da aprendizagem",
    "bars": [
      {
        "label": "Q1 (menos infra)",
        "real": 40.2,         // valor observado
        "off":  40.2,         // cenário "se todas UFs estivessem no pior quartil" — todas convergem para Q1
        "infra_pct": 30.8,    // % escolas 3/3 no quartil
        "n_ufs": 6,
        "color_key": "counterfactual"  // mapeia para a paleta JS (counterfactual|brown|orangeSoft|orange)
      },
      ...  // 4 quartis
    ],
    "callout": "Em 54.3% das escolas..."
  }
}
```

### L4 — creche × SAEB (dois painéis)

```jsonc
{
  "viz": {
    "panel_a_titulo": "A · % CRIANÇAS 0-3 EM CRECHE — POR QUINTIL DE UFS",
    "panel_a_dados":  [ { "q": 1, "value": 19.0, "n": 5 }, ... ],
    "meta_pne": 50,
    "panel_b_titulo": "B · % APRENDIZAGEM ADEQUADA LP — 5º ANO — MESMA QUINTILIZAÇÃO",
    "panel_b_dados":  [ { "q": 1, "value": 47.2, "n": 5 }, ... ],
    "anotacao": "mesma forma da curva, dez anos depois"
  }
}
```

### L5 — 2x2 small multiples

```jsonc
{
  "viz": {
    "q1_titulo": "1. HORAS SEMANAIS DE TRABALHO DOMÉSTICO",
    "q1_dados":  [ { "label": "Meninos brancos", "v": 10.2 }, ... ],   // 4 grupos, ordem fixa
    "q2_titulo": "...",  "q2_dados": [...],
    "q3_titulo": "...",  "q3_dados": [...],                            // urbana/rural (2 grupos)
    "q4_titulo": "...",  "q4_dados": [...]
  }
}
```

### L6 — contrafactual Bolsa Família

```jsonc
{
  "meta": { "contrafactual": true, "cf_key": "bf", ... },
  "viz": {
    "indicador": "% concluem ensino médio até 19 anos",
    "bars": [
      { "label": "20% mais ricos", "real": 92, "off": 91, "color_key": "orange" },
      ...
    ],
    "callout": "Em abril/2025, o Novo Bolsa Família repassou..."
  }
}
```

### L7 — reprovação → abandono (bars horizontais com curva)

```jsonc
{
  "viz": {
    "indicador": "% que declaram ter abandonado pelo menos uma vez",
    "bars": [
      { "label": "Nunca foi reprovado", "value": 4.5, "n": ... },
      { "label": "Reprovou 1 vez",      "value": 19.0, "n": ... },
      { "label": "Reprovou 2+ vezes",   "value": 38.0, "n": ... }
    ],
    "anotacao": "4.6× chance"
  }
}
```

### L8 — autodeclaração de abandono × raça

```jsonc
{
  "meta": { "aviso_metodologico": "Microdado aluno-a-aluno do Censo Escolar foi descontinuado..." },
  "viz": {
    "bars": [
      { "label": "Brancos",   "value": 12.0, "valor_2x": ..., "n": ... },
      { "label": "Pardos",    "value": 17.0, ... },
      { "label": "Pretos",    "value": 20.4, ... },
      { "label": "Amarelos",  "value": ...,  ... },
      { "label": "Indígenas", "value": 32.8, ... }
    ],
    "anotacao": "pretos: 1,70× brancos · indígenas: 2,74× brancos"
  }
}
```

### L9 — contrafactual Lei de Cotas

```jsonc
{
  "meta": { "contrafactual": true, "cf_key": "cotas", ... },
  "viz": {
    "indicador": "% INGRESSANTES EM IES PÚBLICAS FEDERAIS (2024 VS 2012)",
    "bars": [
      { "label": "Pretos",   "real": 13.5, "off": 4.6,  "color_key": "orange" },
      { "label": "Pardos",   "real": 38.3, "off": 23.5, "color_key": "orangeSoft" },
      ...
    ],
    "callout": "Em 2024, 51,8%..."
  }
}
```

### mapa.json

```jsonc
{
  "meta": {
    "indicador": "% aprendizagem adequada em LP — 5º EF",
    "fonte": "...",
    "camadas_disponiveis": ["geral","meninos_brancos","meninas_brancas","meninos_pretos","meninas_pretas","indigenas"],
    "gerado_em": "..."
  },
  "camadas": {
    "geral":           { "AC": 56.2, "AL": 51.6, ... },   // 27 UFs por camada
    "meninos_brancos": { ... },
    "meninas_brancas": { ... },
    "meninos_pretos":  { ... },
    "meninas_pretas":  { ... },
    "indigenas":       { ... }
  },
  "n_alunos": { ... }     // mesmo formato, conta por UF
}
```

**Importante:** as chaves de `camadas.*` são **siglas UF** (`AC`, `SP`, etc.). Se um R script futuro serializar como array, o front quebra. O gerador `20_gerar_mapa.R` usa `as.list(setNames(...))` para forçar objeto JSON.

## Geometria do mapa

`pipeline/data/agregados/geo/brazil-states.geojson` — 3,2 MB.  Fonte: [click_that_hood/brazil-states](https://github.com/codeforgermany/click_that_hood) (com qualidade média). Substituir por TopoJSON simplificado IBGE em produção (~500KB) se quiser otimizar carga.

Propriedade-chave usada: `feature.properties.sigla` (ex.: `"AC"`).

## Convenções

- **Encoding** — UTF-8.
- **Decimais** — ponto, não vírgula. O front converte para vírgula na hora de renderizar.
- **`null`** — significa "não calculado / amostra insuficiente". O front renderiza `—`.
- **Arrays** — ordem importa em todos os campos `bars`, `grupos`, `panel_*_dados` (espelha a ordem da viz).
- **Cores** — não vêm hardcoded como hex. Vêm via `color_key`: `orange`, `orangeSoft`, `brown`, `counterfactual`. O front mapeia para variáveis CSS.

## Como validar antes de subir

1. Cada arquivo deve abrir como JSON válido (`python3 -c 'import json; json.load(open("L1.json"))'`).
2. `meta.gerado_em` precisa ser recente.
3. `meta.n_total` precisa ser > 100 — senão indica filtro mal feito.
4. Em L1 a soma proporcional dos `grupos[i].n` deve bater com `meta.n_total` (±10%).
5. Em `mapa.json`, cada camada deve ter **exatamente 27 chaves** (siglas UF).
