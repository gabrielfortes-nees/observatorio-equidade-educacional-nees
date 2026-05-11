## 11 — L2: escolaridade da mãe (Q08) e do pai (Q09) × proficiência SAEB 9º EF
## CÓDIGOS REAIS (SAEB 2023 9EF): A=não compl. EF, B=EF 5º ano, C=EF compl.,
##                                D=EM compl., E=Sup. compl., F=não sei (descartar)
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_9ef.parquet")))
saeb <- saeb[!is.na(proficiencia_lp_saeb) & in_publica == 1]

niveis_ord <- c("A", "B", "C", "D", "E")
niveis_lbl <- c("não compl.\nfund.", "EF até\n5º ano", "EF\ncompl.", "EM\ncompl.", "Superior\ncompl.")

curva_calc <- function(dt, var_name) {
  out <- dt[get(var_name) %in% niveis_ord,
            .(prof = mean(proficiencia_lp_saeb, na.rm = TRUE), n = .N),
            by = c(var_name)]
  setnames(out, var_name, "nivel")
  out[order(match(nivel, niveis_ord))]
}

mae <- curva_calc(saeb, "tx_resp_q08")
pai <- curva_calc(saeb, "tx_resp_q09")

curva_to_list <- function(dt) {
  lapply(seq_len(nrow(dt)), function(i) {
    list(
      x       = match(dt$nivel[i], niveis_ord),
      x_label = niveis_lbl[match(dt$nivel[i], niveis_ord)],
      y       = round(dt$prof[i], 1),
      n       = dt$n[i]
    )
  })
}

gap_mae <- round(tail(mae$prof, 1) - head(mae$prof, 1), 1)
gap_pai <- round(tail(pai$prof, 1) - head(pai$prof, 1), 1)

L2 <- list(
  meta = list(
    leitura = "L2",
    titulo_curto = "Escolaridade da mãe explica mais",
    eyebrow = "Leitura 02 · SAEB 2023 · 9º ano · escolaridade dos pais (5 níveis)",
    fonte = "SAEB 2023 9º EF — TX_RESP_Q08 (mãe) / Q09 (pai) × PROFICIENCIA_LP_SAEB · escolas públicas · A-E úteis · F (não sei) descartado",
    n_total = nrow(saeb[tx_resp_q08 %in% niveis_ord]),
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    gap_mae_pontos = gap_mae,
    gap_pai_pontos = gap_pai,
    gap_diff = round(gap_mae - gap_pai, 1),
    prof_mae_nao_ef = round(mae$prof[1], 1),
    prof_mae_sup    = round(tail(mae$prof, 1), 1),
    prof_pai_nao_ef = round(pai$prof[1], 1),
    prof_pai_sup    = round(tail(pai$prof, 1), 1)
  ),
  viz = list(
    indicador = "Proficiência SAEB do filho (LP, 9º EF) por escolaridade dos pais",
    eixo_x = niveis_lbl,
    eixo_y_min = floor(min(c(mae$prof, pai$prof)) - 5),
    eixo_y_max = ceiling(max(c(mae$prof, pai$prof)) + 5),
    serie_mae = curva_to_list(mae),
    serie_pai = curva_to_list(pai),
    anotacao = sprintf("mãe: +%.0f pontos · pai: +%.0f pontos", gap_mae, gap_pai)
  )
)

write_json(L2, file.path(DIR_AGG, "L2.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L2 ✓ | gap mãe = %.1f pts · gap pai = %.1f pts · diferença = %.1f",
                 gap_mae, gap_pai, gap_mae - gap_pai))
