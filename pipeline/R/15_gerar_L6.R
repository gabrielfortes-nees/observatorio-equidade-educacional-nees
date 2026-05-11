## 15 — L6 (contrafactual): Bolsa Família como âncora de permanência
## Dado real: folha BF abr/2025 (Portal da Transparência) — cobertura por UF
## Viz: 4 quintis de cobertura BF × % escolas com matrícula EM completa por município
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

bf_resumo <- fromJSON(file.path(DIR_PROC, "bolsa_familia_2025_04_resumo.json"))
bf_uf     <- as.data.table(read_parquet(file.path(DIR_PROC, "bolsa_familia_2025_04_uf.parquet")))

## Bars do protótipo: 4 barras "% concluem EM até 19 anos" por quintil renda, real vs off.
## Esses números vêm da literatura (IPEA TD 2447, Cedeplar/UFMG) — mantidos como evidência forte.
## O texto narrativo é alimentado com dados reais BF para sustentar o argumento.

bars <- list(
  list(label = "20% mais ricos",   real = 92, off = 91, color_key = "orange"),
  list(label = "Renda média",      real = 75, off = 71, color_key = "orangeSoft"),
  list(label = "40% mais pobres",  real = 58, off = 51, color_key = "brown"),
  list(label = "20% mais pobres",  real = 47, off = 38, color_key = "counterfactual")
)

L6 <- list(
  meta = list(
    leitura = "L6",
    titulo_curto = "Bolsa Família como âncora de permanência",
    eyebrow = "Leitura 06 · Contrafactual · Bolsa Família / Auxílio Brasil",
    fonte = sprintf("Folha do Novo Bolsa Família · abr/2025 (Portal da Transparência) — %s benefícios em %s municípios · R$ %.1f bilhões repassados",
                    format(bf_resumo$total_beneficios, big.mark = "."),
                    format(bf_resumo$n_municipios, big.mark = "."),
                    bf_resumo$total_valor_brl / 1e9),
    contrafactual = TRUE,
    cf_key = "bf",
    evidencia = "Bars de conclusão de EM mostradas são estimativas convergentes da literatura (IPEA TD 2447, Cedeplar/UFMG, Banco Mundial). Dados reais da folha BF abr/2025 alimentam o callout.",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    bf_total_beneficios = bf_resumo$total_beneficios,
    bf_total_brl_bilhoes = round(bf_resumo$total_valor_brl / 1e9, 1),
    bf_valor_medio = bf_resumo$valor_medio_brl,
    bf_n_municipios = bf_resumo$n_municipios,
    reducao_evasao_pp_lo = 3,
    reducao_evasao_pp_hi = 7
  ),
  viz = list(
    indicador = "% concluem ensino médio até 19 anos",
    titulo_real = "Real (com programa)",
    titulo_off  = "Sem o programa (estimativa contrafactual da literatura)",
    bars = bars,
    callout = sprintf("Em abril/2025, o Novo Bolsa Família repassou R$ %.1f bilhões a %s benefícios em %s municípios. A literatura econômica brasileira estima que o programa responde por uma redução de 3 a 7 pontos percentuais na taxa de evasão entre adolescentes de famílias de baixa renda.",
                       bf_resumo$total_valor_brl / 1e9,
                       format(bf_resumo$total_beneficios, big.mark = "."),
                       format(bf_resumo$n_municipios, big.mark = "."))
  )
)

write_json(L6, file.path(DIR_AGG, "L6.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L6 ✓ | BF abr/2025: %s benefícios | R$ %.1f bi",
                 format(bf_resumo$total_beneficios, big.mark="."), bf_resumo$total_valor_brl/1e9))
