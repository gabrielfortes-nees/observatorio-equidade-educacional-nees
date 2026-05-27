## Exploração — estudantes por faixa de proficiência Saeb 2023
## Classificação Todos pela Educação / Anuário Brasileiro da Educação Básica
## (escala SAEB pós-2019). 4 faixas: Insuficiente / Básico / Adequado / Avançado.
## Disciplinas: LP e MT · Etapas: 5º EF, 9º EF, 3º EM · Recorte: escolas públicas.
source(here::here("pipeline/R/00_setup.R"))

## ---------- Cortes ----------
cortes <- list(
  lp = list("5ef" = c(150, 225, 300),
            "9ef" = c(200, 275, 325),
            "3em" = c(250, 325, 375)),
  mt = list("5ef" = c(175, 225, 275),
            "9ef" = c(225, 300, 350),
            "3em" = c(250, 350, 400))
)
niveis <- c("Insuficiente", "Básico", "Adequado", "Avançado")

classificar <- function(prof, cuts) {
  cut(prof,
      breaks = c(-Inf, cuts[1], cuts[2], cuts[3], Inf),
      labels = niveis,
      right  = FALSE)
}

## ---------- Função por etapa ----------
faixas_de <- function(parquet_file, etapa_chave, etapa_label) {
  dt <- as.data.table(read_parquet(file.path(DIR_PROC, parquet_file)))
  dt <- dt[in_publica == 1]

  lp <- data.table(disciplina = "LP",
                   faixa = classificar(dt$proficiencia_lp_saeb, cortes$lp[[etapa_chave]]))
  mt <- data.table(disciplina = "MT",
                   faixa = classificar(dt$proficiencia_mt_saeb, cortes$mt[[etapa_chave]]))
  res <- rbindlist(list(lp, mt))
  res <- res[!is.na(faixa)]
  res <- res[, .N, by = .(disciplina, faixa)]
  res[, pct := round(N / sum(N) * 100, 1), by = disciplina]
  res[, etapa := etapa_label]
  res[order(disciplina, faixa)]
}

tab <- rbindlist(list(
  faixas_de("saeb_2023_5ef.parquet", "5ef", "5º ano EF"),
  faixas_de("saeb_2023_9ef.parquet", "9ef", "9º ano EF"),
  faixas_de("saeb_2023_3em.parquet", "3em", "3º ano EM")
))
setcolorder(tab, c("etapa", "disciplina", "faixa", "N", "pct"))

## ---------- Imprimir ----------
fmt_n <- function(x) formatC(x, big.mark = ".", format = "d")
for (e in c("5º ano EF", "9º ano EF", "3º ano EM")) {
  cat("\n====================  ", e, "  ====================\n")
  for (d in c("LP", "MT")) {
    sub <- tab[etapa == e & disciplina == d]
    cat(sprintf("\n  %s — n total avaliado: %s\n", d, fmt_n(sum(sub$N))))
    cat(sprintf("    %-13s %12s   %6s\n", "faixa", "estudantes", "%"))
    cat(sprintf("    %s\n", strrep("-", 36)))
    for (i in seq_len(nrow(sub))) {
      cat(sprintf("    %-13s %12s   %5.1f%%\n",
                  as.character(sub$faixa[i]), fmt_n(sub$N[i]), sub$pct[i]))
    }
  }
}

## ---------- CSV ----------
out_csv <- file.path(DIR_PROC, "exploracao_faixas_saeb_2023.csv")
fwrite(tab, out_csv)
cat("\n=> Tabela salva em:", out_csv, "\n")
