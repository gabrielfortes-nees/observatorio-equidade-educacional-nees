## H1 — os cortes de "Avançado" capturam fatias diferentes das distribuições
## empíricas de LP e MT? Se sim, a comparação "% avançado LP vs MT" é em boa
## parte um artefato dos limiares, não diz sobre proficiência relativa.
## Recorte: escolas públicas.
source(here::here("pipeline/R/00_setup.R"))

cortes_avc <- list(
  lp = c("5ef" = 300, "9ef" = 325, "3em" = 375),
  mt = c("5ef" = 275, "9ef" = 350, "3em" = 400)
)
arq_de <- c("5ef" = "saeb_2023_5ef.parquet",
            "9ef" = "saeb_2023_9ef.parquet",
            "3em" = "saeb_2023_3em.parquet")
etapa_lbl <- c("5ef" = "5º EF", "9ef" = "9º EF", "3em" = "3º EM")

cat(sprintf("%-9s %-3s %7s %6s %5s %5s %5s %5s %5s | corte %6s %7s\n",
            "etapa","disc","media","sd","P50","P75","P90","P95","P99",
            "avç","percentil"))
cat(strrep("-", 90), "\n")

for (et in names(arq_de)) {
  dt <- as.data.table(read_parquet(file.path(DIR_PROC, arq_de[[et]])))
  dt <- dt[in_publica == 1]
  for (disc in c("lp","mt")) {
    col <- paste0("proficiencia_", disc, "_saeb")
    p <- dt[[col]]; p <- p[!is.na(p)]
    qs <- quantile(p, c(0.5, 0.75, 0.9, 0.95, 0.99))
    corte <- cortes_avc[[disc]][[et]]
    pct_acima <- mean(p >= corte) * 100      # % em "Avançado"
    pctil <- mean(p < corte) * 100           # percentil em que o corte cai
    cat(sprintf("%-9s %-3s %7.1f %6.1f %5.0f %5.0f %5.0f %5.0f %5.0f | %5d   P%5.1f  (%4.1f%% avç)\n",
                etapa_lbl[[et]], toupper(disc),
                mean(p), sd(p), qs[1], qs[2], qs[3], qs[4], qs[5],
                corte, pctil, pct_acima))
  }
  cat("\n")
}

cat("\n--- Teste do artefato ---\n")
cat("Para cada etapa, calculo qual seria a % de 'Avançado' em MT se usássemos\n")
cat("o mesmo percentil empírico do corte de LP. Se a diferença observada some,\n")
cat("a vantagem MT é artefato dos cortes.\n\n")

for (et in names(arq_de)) {
  dt <- as.data.table(read_parquet(file.path(DIR_PROC, arq_de[[et]])))
  dt <- dt[in_publica == 1]
  p_lp <- dt$proficiencia_lp_saeb; p_lp <- p_lp[!is.na(p_lp)]
  p_mt <- dt$proficiencia_mt_saeb; p_mt <- p_mt[!is.na(p_mt)]
  corte_lp <- cortes_avc$lp[[et]]
  pct_lp_avc <- mean(p_lp >= corte_lp) * 100
  pctil_lp   <- mean(p_lp <  corte_lp)               # percentil (0..1)
  # corte equivalente em MT: o valor de MT no mesmo percentil em que o corte de LP cai
  corte_mt_equiv <- as.numeric(quantile(p_mt, pctil_lp))
  pct_mt_no_corte_equiv <- mean(p_mt >= corte_mt_equiv) * 100
  pct_mt_observ <- mean(p_mt >= cortes_avc$mt[[et]]) * 100
  cat(sprintf("%s | LP avç observado %.1f%% (corte=%d, P%.1f) | MT avç observado %.1f%% (corte=%d) | MT avç com corte equivalente ao LP (=%.0f, P%.1f) seria %.1f%%\n",
              etapa_lbl[[et]], pct_lp_avc, corte_lp, pctil_lp*100,
              pct_mt_observ, cortes_avc$mt[[et]],
              corte_mt_equiv, pctil_lp*100, pct_mt_no_corte_equiv))
}
