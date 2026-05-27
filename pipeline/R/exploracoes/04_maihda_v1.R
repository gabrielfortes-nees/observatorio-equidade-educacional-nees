## 04 — I-MAIHDA: 6 modelos (3 etapas × 2 disciplinas) no SAEB 2023
## Estratos: raça (3: Branca/Parda/Preta) × sexo (2) × INSE_tercil (3) = 18
## Outcomes: proficiência LP, MT (escala SAEB 0-500)
## Covariada fixa: rede (Pública × Privada)
## Referência: Evans, Leckie, Subramanian, Bell & Merlo (2024) SSM-Population Health
suppressMessages({
  library(arrow); library(data.table); library(lme4); library(broom.mixed)
})
source(here::here("pipeline/R/00_setup.R"))

raca_lbl <- c("A"="Branca","B"="Preta","C"="Parda")
sexo_lbl <- c("A"="Masculino","B"="Feminino")
tercil_lbl <- c("Baixo","Médio","Alto")
cortes_adeq <- list(
  lp = c("5ef"=225,"9ef"=275,"3em"=325),
  mt = c("5ef"=225,"9ef"=300,"3em"=350)
)
arqs <- c("5ef"="saeb_2023_5ef.parquet","9ef"="saeb_2023_9ef.parquet","3em"="saeb_2023_3em.parquet")
etapa_nome <- c("5ef"="5º EF","9ef"="9º EF","3em"="3º EM")

## ----- preparar dados -----
carregar <- function(et) {
  dt <- as.data.table(read_parquet(file.path(DIR_PROC, arqs[et])))
  dt <- dt[tx_resp_q04 %in% c("A","B","C") & tx_resp_q01 %in% c("A","B") &
           !is.na(inse_aluno) & !is.na(in_publica) &
           !is.na(proficiencia_lp_saeb) & !is.na(proficiencia_mt_saeb)]
  dt[, raca := raca_lbl[tx_resp_q04]]
  dt[, sexo := sexo_lbl[tx_resp_q01]]
  dt[, rede := fifelse(in_publica == 1, "Publica", "Privada")]
  dt[, etapa := et]
  dt[, .(etapa, raca, sexo, rede, inse_aluno, prof_lp = proficiencia_lp_saeb, prof_mt = proficiencia_mt_saeb)]
}
all_d <- rbindlist(lapply(names(arqs), carregar))

brks <- quantile(all_d$inse_aluno, c(0, 1/3, 2/3, 1), na.rm = TRUE)
all_d[, inse_tercil := cut(inse_aluno, breaks = brks, labels = tercil_lbl, include.lowest = TRUE)]
all_d[, raca := factor(raca, levels = c("Branca","Parda","Preta"))]
all_d[, sexo := factor(sexo, levels = c("Masculino","Feminino"))]
all_d[, rede := factor(rede, levels = c("Publica","Privada"))]
all_d[, inse_tercil := factor(inse_tercil, levels = tercil_lbl)]
all_d[, estrato := factor(paste(raca, sexo, inse_tercil, sep = " | "))]

cat(sprintf("N total: %s · estratos: %d\n", format(nrow(all_d), big.mark = "."), nlevels(all_d$estrato)))
cat("Cortes INSE (tercis, pooled):\n"); print(round(brks, 2))
cat("N por etapa:\n"); print(all_d[, .N, by = etapa])

## ----- AUC manual rápido (Mann–Whitney) -----
auc_fast <- function(pred, y) {
  ok <- !is.na(pred) & !is.na(y)
  pred <- pred[ok]; y <- y[ok]
  n1 <- sum(y == 1L); n0 <- length(y) - n1
  if (n1 == 0 || n0 == 0) return(NA_real_)
  r <- rank(pred, ties.method = "average")
  (sum(r[y == 1L]) - n1 * (n1 + 1) / 2) / (n1 * n0)
}

## ----- 1 modelo MAIHDA -----
run_maihda <- function(df, outcome_col, etapa_lbl, disc_lbl, corte_adeq) {
  cat(sprintf("\n=== %s · %s (n=%s) ===\n", etapa_lbl, disc_lbl, format(nrow(df), big.mark = ".")))

  cat("  M1A null ..."); t0 <- Sys.time()
  m1a <- lmer(as.formula(paste(outcome_col, "~ 1 + (1 | estrato)")), data = df, REML = TRUE)
  v_u_1a <- as.numeric(VarCorr(m1a)$estrato); v_e_1a <- sigma(m1a)^2
  vpc_1a <- v_u_1a / (v_u_1a + v_e_1a)
  cat(sprintf(" %.1fs · σ²u=%.2f σ²e=%.2f VPC=%.2f%%\n", as.numeric(difftime(Sys.time(), t0, units="secs")), v_u_1a, v_e_1a, 100*vpc_1a))

  cat("  M1B aditivo ..."); t0 <- Sys.time()
  m1b <- lmer(as.formula(paste(outcome_col, "~ raca + sexo + inse_tercil + rede + (1 | estrato)")),
              data = df, REML = TRUE)
  v_u_1b <- as.numeric(VarCorr(m1b)$estrato); v_e_1b <- sigma(m1b)^2
  vpc_1b <- v_u_1b / (v_u_1b + v_e_1b)
  pcv <- (v_u_1a - v_u_1b) / v_u_1a
  cat(sprintf(" %.1fs · σ²u_res=%.4f VPC_res=%.2f%% PCV=%.2f%%\n", as.numeric(difftime(Sys.time(), t0, units="secs")), v_u_1b, 100*vpc_1b, 100*pcv))

  cat("  DA (AUC) ..."); t0 <- Sys.time()
  y <- df[[outcome_col]]
  bin_y <- as.integer(y >= corte_adeq)
  pred <- as.numeric(predict(m1a))
  auc_val <- auc_fast(pred, bin_y)
  cat(sprintf(" %.1fs · AUC=%.3f\n", as.numeric(difftime(Sys.time(), t0, units="secs")), auc_val))

  ranef_1a <- ranef(m1a, condVar = TRUE)$estrato
  ranef_1b <- ranef(m1b, condVar = TRUE)$estrato
  pv_1a <- as.numeric(attr(ranef_1a, "postVar"))
  pv_1b <- as.numeric(attr(ranef_1b, "postVar"))
  ranking <- data.table(
    estrato = rownames(ranef_1a),
    u_1A = ranef_1a[,1], se_1A = sqrt(pv_1a),
    u_1B = ranef_1b[,1], se_1B = sqrt(pv_1b)
  )
  ranking[, intercept_global := fixef(m1a)[[1]]]
  ranking[, predicted_1A := intercept_global + u_1A]
  ranking[, ic_lo := predicted_1A - 1.96 * se_1A]
  ranking[, ic_hi := predicted_1A + 1.96 * se_1A]
  ranking[, sig_uj_1B := abs(u_1B / se_1B) > 1.96]

  list(
    etapa = etapa_lbl, disciplina = disc_lbl, n = nrow(df),
    v_u_1a = v_u_1a, v_e_1a = v_e_1a, vpc_1a = vpc_1a,
    v_u_1b = v_u_1b, v_e_1b = v_e_1b, vpc_1b = vpc_1b,
    pcv = pcv, auc = auc_val,
    coefs = broom.mixed::tidy(m1b, effects = "fixed", conf.int = TRUE),
    ranking = ranking
  )
}

## ----- rodar 6 modelos -----
resultados <- list()
for (et in names(arqs)) {
  df_et <- all_d[etapa == et]
  resultados[[paste0(et,"_lp")]] <- run_maihda(df_et, "prof_lp", etapa_nome[et], "LP", cortes_adeq$lp[et])
  resultados[[paste0(et,"_mt")]] <- run_maihda(df_et, "prof_mt", etapa_nome[et], "MT", cortes_adeq$mt[et])
}

## ----- resumo -----
cat("\n=========== RESUMO ===========\n")
resumo <- rbindlist(lapply(resultados, function(r) data.table(
  etapa = r$etapa, disciplina = r$disciplina, n = r$n,
  VPC_M1A_pct = round(r$vpc_1a*100, 2),
  PCV_pct     = round(r$pcv*100, 2),
  VPC_M1B_pct = round(r$vpc_1b*100, 2),
  AUC_DA      = round(r$auc, 3)
)))
print(resumo)

saveRDS(resultados, file.path(DIR_PROC, "maihda_v1_resultados.rds"))
fwrite(resumo, file.path(DIR_PROC, "maihda_v1_resumo.csv"))
cat("\n=> Saídas: maihda_v1_resultados.rds + maihda_v1_resumo.csv\n")
