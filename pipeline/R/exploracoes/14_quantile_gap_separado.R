## 14 — Quantile regression do gap intra-escola, SEPARANDO pretos e pardos
## Contrastes: parda vs branca · preta vs branca
## Etapas: 5º EF, 9º EF, 3º EM · disciplina: LP · pública
## Otimização: amostragem de 100k por modelo (precisão mantida; sem ela, ~50 min total)
suppressMessages({
  library(arrow); library(data.table); library(quantreg)
})
source(here::here("pipeline/R/00_setup.R"))

ARQS <- c("5ef" = "saeb_2023_5ef.parquet",
          "9ef" = "saeb_2023_9ef.parquet",
          "3em" = "saeb_2023_3em.parquet")
ETAPA_LBL <- c("5ef" = "5º EF", "9ef" = "9º EF", "3em" = "3º EM")
MIN_GRP <- 10
N_SAMPLE <- 100000
TAUS <- c(0.10, 0.25, 0.50, 0.75, 0.90)
set.seed(42)

rodar_etapa <- function(et) {
  cat(sprintf("\n=== ETAPA: %s ===\n", ETAPA_LBL[et]))

  dt <- as.data.table(read_parquet(file.path(DIR_PROC, ARQS[et])))
  dt <- dt[in_publica == 1 & !is.na(proficiencia_lp_saeb)]
  dt <- dt[tx_resp_q04 %in% c("A","B","C")]
  dt[, raca := fcase(
    tx_resp_q04 == "A", "Branca",
    tx_resp_q04 == "B", "Preta",
    tx_resp_q04 == "C", "Parda"
  )]

  rodar_contraste <- function(raca_b) {
    cat(sprintf("  contraste: %s vs Branca\n", raca_b))
    sub <- dt[raca %in% c("Branca", raca_b)]
    sub[, is_target := as.integer(raca == raca_b)]

    ## escolas mistas: >=10 de cada lado
    porescola <- sub[, .(n_branca = sum(raca == "Branca"),
                          n_target = sum(raca == raca_b)),
                      by = id_escola]
    mistas <- porescola[n_branca >= MIN_GRP & n_target >= MIN_GRP, id_escola]
    sub_m <- sub[id_escola %in% mistas]
    cat(sprintf("    escolas mistas: %s · N total: %s\n",
                format(length(mistas), big.mark="."),
                format(nrow(sub_m), big.mark=".")))

    if (length(mistas) < 100) {
      cat(sprintf("    [skip — escolas mistas insuficientes]\n"))
      return(NULL)
    }

    ## centralizar pela média da escola (gap intra-escola)
    sub_m[, prof_c := proficiencia_lp_saeb - mean(proficiencia_lp_saeb), by = id_escola]

    ## amostragem para viabilidade computacional
    n_total <- nrow(sub_m)
    if (n_total > N_SAMPLE) {
      idx <- sample.int(n_total, N_SAMPLE)
      sub_samp <- sub_m[idx]
    } else {
      sub_samp <- sub_m
    }
    cat(sprintf("    amostra para quantreg: %s\n", format(nrow(sub_samp), big.mark=".")))

    ## OLS referência
    m_ols <- lm(prof_c ~ is_target, data = sub_samp)
    gap_ols <- coef(m_ols)[2]
    se_ols  <- summary(m_ols)$coefficients[2, 2]

    ## quantile regression
    res_taus <- lapply(TAUS, function(tau) {
      m <- rq(prof_c ~ is_target, data = sub_samp, tau = tau, method = "br")
      s <- summary(m, se = "nid")
      coef <- s$coefficients["is_target", ]
      data.table(tau = tau,
                 gap = unname(coef["Value"]),
                 se  = unname(coef["Std. Error"]))
    })
    out <- rbindlist(res_taus)
    out[, ic_lo := gap - 1.96 * se]
    out[, ic_hi := gap + 1.96 * se]
    out[, contraste := paste0(raca_b, "_vs_Branca")]
    out[, etapa := ETAPA_LBL[et]]
    out[, ols_ref := round(gap_ols, 2)]
    out[, n_escolas_mistas := length(mistas)]
    out[, n_amostra := nrow(sub_samp)]
    out
  }

  rbindlist(lapply(c("Parda","Preta"), rodar_contraste))
}

todos <- rbindlist(lapply(names(ARQS), rodar_etapa))
todos[, `:=`(gap = round(gap, 2), se = round(se, 3),
             ic_lo = round(ic_lo, 2), ic_hi = round(ic_hi, 2))]

cat("\n\n========================= RESUMO =========================\n")
out <- dcast(todos, etapa + contraste ~ tau, value.var = "gap")
setnames(out, as.character(TAUS), sprintf("P%02d", as.integer(TAUS * 100)))
print(out)

cat("\nOLS referência (gap médio intra-escola por contraste/etapa):\n")
print(unique(todos[, .(etapa, contraste, ols_ref, n_escolas_mistas)]))

fwrite(todos, file.path(DIR_PROC, "expl_quantile_gap_separado.csv"))
cat("\n=> saída: pipeline/data/processed/expl_quantile_gap_separado.csv\n")
