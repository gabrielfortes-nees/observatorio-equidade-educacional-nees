## 11 — Quantile regression do gap racial INTRA-ESCOLA (SAEB 5EF · LP · pública)
## Pergunta: o gap branco vs preto+pardo dentro da escola é uniforme ao longo
## da distribuição? Ou é maior no piso (P10) ou no topo (P90)?
##
## Comparação esperada: a L2 atual reporta gap intra-escola médio = 4.0 pontos.
## Quantile regression mostra esse gap em cada quantil.
suppressMessages({
  library(arrow); library(data.table); library(quantreg)
})
source(here::here("pipeline/R/00_setup.R"))

MIN_GRP <- 10  ## mesmo critério da L2

dt <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_5ef.parquet")))
dt <- dt[in_publica == 1 & !is.na(proficiencia_lp_saeb)]
dt <- dt[tx_resp_q04 %in% c("A","B","C","D","E")]
dt[, raca := fcase(
  tx_resp_q04 %in% c("A","D"), "branca_amarela",
  tx_resp_q04 %in% c("B","C"), "preta_parda",
  tx_resp_q04 == "E",          "indigena"
)]
dt <- dt[raca %in% c("branca_amarela","preta_parda")]
dt[, is_preto := as.integer(raca == "preta_parda")]

## ---------- escolas mistas (mesmas da L2) ----------
porescola <- dt[, .(n_br = sum(raca == "branca_amarela"),
                    n_pp = sum(raca == "preta_parda")),
                by = id_escola]
mistas <- porescola[n_br >= MIN_GRP & n_pp >= MIN_GRP, id_escola]
dt_m <- dt[id_escola %in% mistas]
cat(sprintf("Escolas mistas (>=%d brancos e >=%d pretos+pardos): %s\n",
            MIN_GRP, MIN_GRP, format(length(mistas), big.mark=".")))
cat(sprintf("N estudantes nessas escolas: %s\n\n", format(nrow(dt_m), big.mark=".")))

## ---------- centralizar pela média da escola (intra-school) ----------
## prof_centrada = prof - média_da_escola(prof)
## Quantile regression de prof_centrada ~ is_preto reproduz o gap intra-escola
## em cada quantil sem precisar de milhares de dummies de escola.
dt_m[, prof_centrada := proficiencia_lp_saeb - mean(proficiencia_lp_saeb), by = id_escola]

## ---------- quantile regression ----------
taus <- c(0.10, 0.25, 0.50, 0.75, 0.90)
cat("Rodando quantile regression (5 quantis) ...\n")

resultados <- lapply(taus, function(tau) {
  cat(sprintf("  tau = %.2f ...", tau))
  t0 <- Sys.time()
  ## "br" method (Barrodale-Roberts) — eficiente para n grande
  m <- rq(prof_centrada ~ is_preto, data = dt_m, tau = tau, method = "br")
  ## SE via summary
  s <- summary(m, se = "nid")  ## nid = niid não disponível em rq grande, nid OK
  coef <- s$coefficients["is_preto", ]
  cat(sprintf(" %.1fs\n", as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  data.table(
    tau = tau,
    estimate = coef["Value"],
    se = coef["Std. Error"],
    t_value = coef["t value"],
    p = coef["Pr(>|t|)"]
  )
})
resq <- rbindlist(resultados)
resq[, ic_lo := estimate - 1.96 * se]
resq[, ic_hi := estimate + 1.96 * se]

## ---------- também: gap OLS intra-escola para referência ----------
m_ols <- lm(prof_centrada ~ is_preto, data = dt_m)
s_ols <- summary(m_ols)
gap_ols <- coef(m_ols)["is_preto"]
se_ols  <- s_ols$coefficients["is_preto", "Std. Error"]
cat(sprintf("\nReferência OLS intra-escola: %.2f (SE %.3f, IC95%% [%.2f, %.2f])\n",
            gap_ols, se_ols, gap_ols - 1.96*se_ols, gap_ols + 1.96*se_ols))
cat(sprintf("L2 atual reportada: gap intra-escola médio = 4.0 (com peso por massa de aluno)\n"))
cat(sprintf("Diferença OLS aqui vs L2: %.2f\n\n", abs(gap_ols) - 4.0))

## ---------- imprimir resultado ----------
cat("\n========== QUANTILE REGRESSION DO GAP INTRA-ESCOLA ==========\n")
cat("Coef is_preto = diferença esperada (pretos+pardos − brancos+amarelos) em cada quantil\n")
cat("Valor negativo = pretos+pardos abaixo dos brancos\n\n")

out <- resq[, .(
  tau = sprintf("P%02d", as.integer(tau * 100)),
  gap = round(estimate, 2),
  SE = round(se, 3),
  IC95 = sprintf("[%.2f, %.2f]", round(ic_lo, 2), round(ic_hi, 2)),
  sig = fifelse(p < 0.001, "***", fifelse(p < 0.01, "**", fifelse(p < 0.05, "*", "")))
)]
print(out)

cat("\nLeitura:\n")
cat("- Gap mais NEGATIVO em quantil X = desigualdade racial é MAIOR naquela parte da distribuição\n")
cat("- Se gaps em P10 e P90 são similares → desigualdade é uniforme\n")
cat("- Se |gap_P10| > |gap_P90| → desigualdade concentrada no PISO\n")
cat("- Se |gap_P90| > |gap_P10| → desigualdade concentrada no TOPO (efeito teto)\n\n")

## ---------- salvar ----------
fwrite(resq, file.path(DIR_PROC, "expl_quantile_gap_intra.csv"))
cat("=> saída: pipeline/data/processed/expl_quantile_gap_intra.csv\n")
