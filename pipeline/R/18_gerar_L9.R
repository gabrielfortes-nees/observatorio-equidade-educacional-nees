## 18 — L9 (contrafactual): Lei de Cotas — composição racial das IES federais
## Censo da Educação Superior 2024: QT_ING_PRETA/PARDA/BRANCA × TP_CATEGORIA_ADMINISTRATIVA
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

cur <- as.data.table(read_parquet(file.path(DIR_PROC, "censo_superior_2024_cursos.parquet")))

## TP_CATEGORIA_ADMINISTRATIVA: 1=Pública Federal, 2=Pública Estadual, 3=Pública Municipal,
##  4=Privada com fins lucrativos, 5=Privada sem fins... (varia ano a ano).
## Para o protótipo, federais públicas = 1.
cur[, cat_lbl := fcase(
  tp_categoria_administrativa == 1, "Pública Federal",
  tp_categoria_administrativa == 2, "Pública Estadual",
  tp_categoria_administrativa == 3, "Pública Municipal",
  tp_categoria_administrativa %in% 4:7, "Privada",
  default = "Outras"
)]

agg <- cur[, .(
  ing_branca   = sum(qt_ing_branca, na.rm = TRUE),
  ing_preta    = sum(qt_ing_preta,  na.rm = TRUE),
  ing_parda    = sum(qt_ing_parda,  na.rm = TRUE),
  ing_amarela  = sum(qt_ing_amarela, na.rm = TRUE),
  ing_indigena = sum(qt_ing_indigena, na.rm = TRUE),
  ing_cornd    = sum(qt_ing_cornd, na.rm = TRUE),
  ing_total    = sum(qt_ing, na.rm = TRUE)
), by = cat_lbl]

agg[, ing_declarada := ing_branca + ing_preta + ing_parda + ing_amarela + ing_indigena]
agg[, pct_pretos := round(ing_preta / ing_declarada * 100, 1)]
agg[, pct_pardos := round(ing_parda / ing_declarada * 100, 1)]
agg[, pct_negros := round((ing_preta + ing_parda) / ing_declarada * 100, 1)]
agg[, pct_brancos := round(ing_branca / ing_declarada * 100, 1)]
agg[, pct_indigenas := round(ing_indigena / ing_declarada * 100, 1)]

## bars do protótipo: comparar real (2024) com contrafactual pré-cotas (literatura)
fed <- agg[cat_lbl == "Pública Federal"]

## valores pré-cotas (2010-2012) — da literatura INEP/IPEA
## fonte: INEP Censo Sup. 2012 ANDIFES IV PNAES
pre_pretos   <- 4.6
pre_pardos   <- 23.5
pre_brancos  <- 65.8
pre_indigena <- 0.4

bars <- list(
  list(label = "Pretos",   real = fed$pct_pretos[1],    off = pre_pretos,   color_key = "orange"),
  list(label = "Pardos",   real = fed$pct_pardos[1],    off = pre_pardos,   color_key = "orangeSoft"),
  list(label = "Brancos",  real = fed$pct_brancos[1],   off = pre_brancos,  color_key = "brown"),
  list(label = "Indígenas",real = fed$pct_indigenas[1], off = pre_indigena, color_key = "counterfactual")
)

L9 <- list(
  meta = list(
    leitura = "L9",
    titulo_curto = "Sem Lei de Cotas, conclusão por raça regrediria",
    eyebrow = "Leitura 09 · Contrafactual · Lei 12.711/2012 · efeito-horizonte",
    fonte = "Censo da Educação Superior 2024 (INEP) — QT_ING_* × TP_CATEGORIA_ADMINISTRATIVA · contrafactual ancorado em Censo Sup. 2010-2012 e ANDIFES",
    contrafactual = TRUE,
    cf_key = "cotas",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    fed_pct_pretos_2024 = fed$pct_pretos[1],
    fed_pct_pardos_2024 = fed$pct_pardos[1],
    fed_pct_negros_2024 = fed$pct_negros[1],
    pre_pct_pretos = pre_pretos,
    pre_pct_negros = pre_pretos + pre_pardos,
    delta_negros_pp = round((fed$pct_negros[1]) - (pre_pretos + pre_pardos), 1),
    ing_negros_2024 = fed$ing_preta[1] + fed$ing_parda[1]
  ),
  viz = list(
    indicador = "% de ingressantes em IES Públicas Federais — Censo Educação Superior 2024",
    titulo_real = "2024 · com Lei de Cotas em vigor",
    titulo_off  = "2012 · antes da implementação plena",
    bars = bars,
    callout = sprintf("Em 2024, %.1f%% dos ingressantes em IES Públicas Federais se autodeclararam pretos ou pardos — em 2012, antes da implementação plena da Lei de Cotas, essa proporção era de %.1f%%. Diferença: +%.1f pp.",
                       fed$pct_negros[1], pre_pretos + pre_pardos,
                       fed$pct_negros[1] - (pre_pretos + pre_pardos))
  )
)

write_json(L9, file.path(DIR_AGG, "L9.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L9 ✓ | federal pretos+pardos 2024 = %.1f%% (vs %.1f%% pré-cotas)",
                 fed$pct_negros[1], pre_pretos + pre_pardos))
