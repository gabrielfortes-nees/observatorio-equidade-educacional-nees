## 21 — Dados da demonstração progressiva da landing /interseccionalidade/
## A média do SAEB se desfaz em 4 níveis de estratificação:
##   Nível 0: média Brasil (1 barra)
##   Nível 1: + raça/cor (2 barras)
##   Nível 2: + sexo (4 barras)
##   Nível 3: + nível socioeconômico INSE (8 barras)
## Base: SAEB 2023 · 5º EF · escolas públicas · corte oficial INEP (≥225)
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_5ef.parquet")))
saeb <- saeb[in_publica == 1 & !is.na(proficiencia_lp_saeb)]
saeb <- saeb[tx_resp_q01 %in% c("A", "B") & tx_resp_q04 %in% c("A", "B", "C", "D", "E")]

saeb[, sexo := fcase(tx_resp_q01 == "A", "Meninos", tx_resp_q01 == "B", "Meninas")]
saeb[, raca := fcase(
  tx_resp_q04 %in% c("A", "D"), "brancos",
  tx_resp_q04 %in% c("B", "C"), "pretos",
  tx_resp_q04 == "E",          "indigenas"
)]
saeb <- saeb[raca %in% c("brancos", "pretos")]               # 2 grupos como no L1
saeb[, inse_q := cut(inse_aluno,
                     breaks = quantile(inse_aluno, probs = seq(0, 1, 0.2), na.rm = TRUE),
                     include.lowest = TRUE, labels = paste0("Q", 1:5))]
saeb[, adequado := as.integer(proficiencia_lp_saeb >= ADEQ_LP_5EF)]

pct <- function(dt) round(mean(dt$adequado) * 100, 1)

## ---- Nível 0: média geral ----
nivel0 <- list(list(label = "Todos os estudantes", value = pct(saeb), grupo = "neutro"))

## ---- Nível 1: por raça ----
nivel1 <- list(
  list(label = "Brancos e amarelos", value = pct(saeb[raca == "brancos"]), grupo = "alto"),
  list(label = "Pretos e pardos",    value = pct(saeb[raca == "pretos"]),  grupo = "baixo")
)

## ---- Nível 2: por raça × sexo ----
combos2 <- list(
  c("Meninas", "brancos"), c("Meninos", "brancos"),
  c("Meninas", "pretos"),  c("Meninos", "pretos")
)
nivel2 <- lapply(combos2, function(cc) {
  sub <- saeb[sexo == cc[1] & raca == cc[2]]
  rlab <- ifelse(cc[2] == "brancos", "brancas/brancos", "pretas/pardas")
  rlab <- ifelse(cc[2] == "brancos",
                 ifelse(cc[1] == "Meninas", "brancas", "brancos"),
                 ifelse(cc[1] == "Meninas", "pretas/pardas", "pretos/pardos"))
  list(label = paste(cc[1], rlab), value = pct(sub),
       grupo = ifelse(cc[2] == "brancos", "alto", "baixo"))
})

## ---- Nível 3: raça × sexo × INSE (Q1 baixo, Q5 alto) ----
combos3 <- list(
  c("Meninas", "brancos", "Q5"), c("Meninos", "brancos", "Q5"),
  c("Meninas", "pretos",  "Q5"), c("Meninos", "pretos",  "Q5"),
  c("Meninas", "brancos", "Q1"), c("Meninos", "brancos", "Q1"),
  c("Meninas", "pretos",  "Q1"), c("Meninos", "pretos",  "Q1")
)
nivel3 <- lapply(combos3, function(cc) {
  sub <- saeb[sexo == cc[1] & raca == cc[2] & inse_q == cc[3]]
  rlab <- ifelse(cc[2] == "brancos",
                 ifelse(cc[1] == "Meninas", "brancas", "brancos"),
                 ifelse(cc[1] == "Meninas", "pretas", "pretos"))
  inse_lab <- ifelse(cc[3] == "Q5", "NSE alto", "NSE baixo")
  list(label = paste0(cc[1], " ", rlab, " · ", inse_lab),
       value = pct(sub),
       grupo = ifelse(cc[2] == "brancos", "alto", "baixo"))
})

## ordena nível 3 do maior para o menor (deixa o gap topo-chão claro)
ord <- order(-sapply(nivel3, function(x) x$value))
nivel3 <- nivel3[ord]

vals3 <- sapply(nivel3, function(x) x$value)
topo  <- nivel3[[which.max(vals3)]]
chao  <- nivel3[[which.min(vals3)]]

DEMO <- list(
  meta = list(
    fonte = "SAEB 2023 · 5º ano EF · escolas públicas · corte oficial INEP (proficiência ≥ 225)",
    indicador = "% de estudantes com aprendizagem adequada em Língua Portuguesa",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  passos = list(
    list(
      titulo = "A média nacional",
      legenda = "Um número só. É o que vai para as manchetes.",
      barras = nivel0
    ),
    list(
      titulo = "Quando se separa por raça/cor",
      legenda = "A média se divide em dois. A distância começa a aparecer.",
      barras = nivel1
    ),
    list(
      titulo = "Quando se acrescenta o sexo",
      legenda = "Quatro grupos. Cada marcador social desloca o número.",
      barras = nivel2
    ),
    list(
      titulo = "Quando se acrescenta o nível socioeconômico",
      legenda = sprintf("Oito grupos. Do topo (%s, %s%%) ao chão (%s, %s%%): %s pontos percentuais que a média escondia inteiros.",
                        topo$label, format(topo$value, decimal.mark=","),
                        chao$label, format(chao$value, decimal.mark=","),
                        format(round(topo$value - chao$value, 1), decimal.mark=",")),
      barras = nivel3
    )
  ),
  sintese = list(
    media = nivel0[[1]]$value,
    topo_label = topo$label, topo_value = topo$value,
    chao_label = chao$label, chao_value = chao$value,
    amplitude = round(topo$value - chao$value, 1)
  )
)

write_json(DEMO, file.path(DIR_AGG, "landing_demo.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("landing_demo.json ✓ | média %.1f%% · topo %.1f%% · chão %.1f%% · amplitude %.1f pp",
                 nivel0[[1]]$value, topo$value, chao$value, topo$value - chao$value))
