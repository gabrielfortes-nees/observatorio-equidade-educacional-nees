## 06 — Tabelas do paper MAIHDA
## T1 Caracterização da amostra · T2 Resultados M1A/M1B · T3 Coefs fixos do M1B
## T4 Estratos extremos · TS_sens Sensitivity esquemas de raça (McCall anti-categorial)
suppressMessages({
  library(arrow); library(data.table); library(lme4); library(broom.mixed)
})
source(here::here("pipeline/R/00_setup.R"))

DIR_TAB <- here::here("academico/maihda_saeb2023/paper/tabelas")
dir.create(DIR_TAB, showWarnings = FALSE, recursive = TRUE)

raca_lbl <- c("A"="Branca","B"="Preta","C"="Parda","D"="Amarela","E"="Indigena","F"="NaoDeclarou")
sexo_lbl <- c("A"="Masculino","B"="Feminino")
arqs <- c("5ef"="saeb_2023_5ef.parquet","9ef"="saeb_2023_9ef.parquet","3em"="saeb_2023_3em.parquet")
etapa_nome <- c("5ef"="5º EF","9ef"="9º EF","3em"="3º EM")

## ----- ler microdados (com raça completa para reportar exclusões) -----
carregar_full <- function(et) {
  dt <- as.data.table(read_parquet(file.path(DIR_PROC, arqs[et])))
  dt[, etapa := et]
  dt[, raca_full := raca_lbl[tx_resp_q04]]
  dt[, sexo_full := sexo_lbl[tx_resp_q01]]
  dt[, rede := fifelse(in_publica == 1, "Publica", "Privada")]
  dt
}
raw <- rbindlist(lapply(names(arqs), carregar_full), fill = TRUE)

cat("\n========== Inventário de exclusões ==========\n")
inv <- raw[, .(
  n_total = .N,
  n_amarela    = sum(raca_full == "Amarela", na.rm=TRUE),
  n_indigena   = sum(raca_full == "Indigena", na.rm=TRUE),
  n_naodecl    = sum(raca_full == "NaoDeclarou", na.rm=TRUE),
  n_raca_NA    = sum(is.na(raca_full)),
  n_sexo_NA    = sum(is.na(sexo_full)),
  n_inse_NA    = sum(is.na(inse_aluno)),
  n_rede_NA    = sum(is.na(in_publica)),
  n_lp_NA      = sum(is.na(proficiencia_lp_saeb)),
  n_mt_NA      = sum(is.na(proficiencia_mt_saeb))
), by = etapa]
print(inv)
fwrite(inv, file.path(DIR_TAB, "TS0_inventario_exclusoes.csv"))

## ----- amostra analítica (mesmo critério dos modelos) -----
all_d <- raw[tx_resp_q04 %in% c("A","B","C") & tx_resp_q01 %in% c("A","B") &
             !is.na(inse_aluno) & !is.na(in_publica) &
             !is.na(proficiencia_lp_saeb) & !is.na(proficiencia_mt_saeb),
           .(etapa, raca = raca_full, sexo = sexo_full, rede,
             inse_aluno,
             prof_lp = proficiencia_lp_saeb, prof_mt = proficiencia_mt_saeb)]

brks <- quantile(all_d$inse_aluno, c(0, 1/3, 2/3, 1), na.rm = TRUE)
brks_q <- quantile(all_d$inse_aluno, c(0, 1/5, 2/5, 3/5, 4/5, 1), na.rm = TRUE)
all_d[, inse_tercil := cut(inse_aluno, breaks = brks, labels = c("Baixo","Médio","Alto"), include.lowest = TRUE)]
all_d[, inse_quintil := cut(inse_aluno, breaks = brks_q, labels = paste0("Q",1:5), include.lowest = TRUE)]
all_d[, raca := factor(raca, levels = c("Branca","Parda","Preta"))]
all_d[, sexo := factor(sexo, levels = c("Masculino","Feminino"))]
all_d[, rede := factor(rede, levels = c("Publica","Privada"))]
all_d[, estrato := factor(paste(raca, sexo, inse_tercil, sep = " | "))]

## ============================================================
## TABELA 1 — Caracterização da amostra
## ============================================================
cat("\n========== TABELA 1 — Caracterização da amostra ==========\n")

pct <- function(x, lvl) round(mean(x == lvl, na.rm=TRUE) * 100, 1)

tab1 <- all_d[, .(
  N                  = format(.N, big.mark="."),
  `% Branca`         = pct(raca, "Branca"),
  `% Parda`          = pct(raca, "Parda"),
  `% Preta`          = pct(raca, "Preta"),
  `% Masculino`      = pct(sexo, "Masculino"),
  `% Feminino`       = pct(sexo, "Feminino"),
  `% INSE Baixo`     = pct(inse_tercil, "Baixo"),
  `% INSE Médio`     = pct(inse_tercil, "Médio"),
  `% INSE Alto`      = pct(inse_tercil, "Alto"),
  `% Pública`        = pct(rede, "Publica"),
  `% Privada`        = pct(rede, "Privada"),
  `INSE médio`       = round(mean(inse_aluno, na.rm=TRUE), 2),
  `Prof. LP média`   = round(mean(prof_lp, na.rm=TRUE), 1),
  `Prof. MT média`   = round(mean(prof_mt, na.rm=TRUE), 1)
), by = etapa]
tab1[, etapa := etapa_nome[etapa]]
setnames(tab1, "etapa", "Etapa")
tab1_long <- t(tab1)
print(tab1_long)
fwrite(tab1, file.path(DIR_TAB, "T1_caracterizacao_amostra.csv"))

## ============================================================
## TABELA 2 — Resultados M1A/M1B (VPC, PCV, AUC)
## ============================================================
cat("\n========== TABELA 2 — VPC / PCV / AUC ==========\n")

resultados <- readRDS(file.path(DIR_PROC, "maihda_v1_resultados.rds"))
auc_tab <- fread(file.path(DIR_PROC, "maihda_v1_auc.csv"))
setnames(auc_tab, c("modelo","n","pct_adeq_plus","AUC"))

tab2 <- rbindlist(lapply(resultados, function(r) data.table(
  Etapa = r$etapa, Disciplina = r$disciplina, N = format(r$n, big.mark="."),
  `σ²u M1A`      = round(r$v_u_1a, 2),
  `σ²e M1A`      = round(r$v_e_1a, 2),
  `VPC M1A (%)`  = round(r$vpc_1a * 100, 2),
  `σ²u M1B`      = round(r$v_u_1b, 4),
  `VPC M1B (%)`  = round(r$vpc_1b * 100, 2),
  `PCV (%)`      = round(r$pcv * 100, 2),
  `% Adeq+`      = NA_real_,
  AUC            = NA_real_
)))
# preencher AUC e % Adequado+ a partir do CSV
for (i in seq_len(nrow(tab2))) {
  mod <- paste(tab2$Etapa[i], tab2$Disciplina[i])
  m <- auc_tab[modelo == mod]
  if (nrow(m) == 1) {
    tab2[i, `% Adeq+` := round(m$pct_adeq_plus, 1)]
    tab2[i, AUC := round(m$AUC, 3)]
  }
}
print(tab2)
fwrite(tab2, file.path(DIR_TAB, "T2_resultados_M1A_M1B.csv"))

## ============================================================
## TABELA 3 — Coeficientes fixos do M1B
## ============================================================
cat("\n========== TABELA 3 — Coeficientes fixos M1B ==========\n")

tab3 <- rbindlist(lapply(resultados, function(r) {
  d <- as.data.table(r$coefs)
  d[, Etapa := r$etapa]; d[, Disciplina := r$disciplina]
  d[, .(Etapa, Disciplina,
        Termo = term,
        β = round(estimate, 2),
        EP = round(std.error, 3),
        `IC95% lo` = round(conf.low, 2),
        `IC95% hi` = round(conf.high, 2),
        `t` = round(statistic, 2),
        sig = fcase(abs(statistic) > 3.29, "***",
                    abs(statistic) > 2.58, "**",
                    abs(statistic) > 1.96, "*",
                    default = ""))]
}))
print(tab3)
fwrite(tab3, file.path(DIR_TAB, "T3_coeficientes_M1B.csv"))

## ============================================================
## TABELA 4 — Estratos extremos (5 mais desv. + 5 mais priv.)
## ============================================================
cat("\n========== TABELA 4 — Estratos extremos ==========\n")

tab4 <- rbindlist(lapply(resultados, function(r) {
  dt <- as.data.table(r$ranking)
  dt[, Etapa := r$etapa]; dt[, Disciplina := r$disciplina]
  dt_ord <- dt[order(predicted_1A)]
  out <- rbind(
    head(dt_ord, 5)[, posicao := "Desvantajado"],
    tail(dt_ord, 5)[, posicao := "Privilegiado"]
  )
  out[, sig_uj := fifelse(abs(u_1A/se_1A) > 1.96, "*", "")]
  out[, .(Etapa, Disciplina, posicao,
          Estrato = estrato,
          `Pred (M1A)` = round(predicted_1A, 1),
          `IC95% lo`   = round(ic_lo, 1),
          `IC95% hi`   = round(ic_hi, 1),
          uj_M1A       = round(u_1A, 2),
          uj_M1B       = round(u_1B, 2),
          sig_uj_M1A   = sig_uj,
          sig_uj_M1B   = fifelse(sig_uj_1B, "*", ""))]
}))
print(tab4)
fwrite(tab4, file.path(DIR_TAB, "T4_estratos_extremos.csv"))

## ============================================================
## TABELA SUPL — Sensitivity de raça (McCall anti-categorial)
## ============================================================
cat("\n========== TS_sens — Sensitivity esquemas de raça ==========\n")

# 3 esquemas. Para 'binaria' e 'movneg' rodar com Amarela/Indigena re-incluídas?
# Mantemos o universo analítico do paper (B/P/P) por comparabilidade.
all_d[, raca_3   := raca]  # Branca, Parda, Preta
all_d[, raca_bin := fifelse(raca == "Branca", "Branca", "NaoBranca")]
all_d[, raca_bin := factor(raca_bin, levels = c("Branca","NaoBranca"))]
all_d[, raca_movneg := fcase(raca == "Branca", "Branca",
                             raca %in% c("Parda","Preta"), "Negra")]
all_d[, raca_movneg := factor(raca_movneg, levels = c("Branca","Negra"))]

all_d[, estrato_3      := factor(paste(raca_3, sexo, inse_tercil, sep="|"))]
all_d[, estrato_bin    := factor(paste(raca_bin, sexo, inse_tercil, sep="|"))]
all_d[, estrato_movneg := factor(paste(raca_movneg, sexo, inse_tercil, sep="|"))]

calc <- function(df, outcome, estrato_col, raca_col) {
  f1a <- as.formula(paste(outcome, "~ 1 + (1 |", estrato_col, ")"))
  f1b <- as.formula(paste(outcome, "~", raca_col,
                          "+ sexo + inse_tercil + rede + (1 |", estrato_col, ")"))
  m1a <- lmer(f1a, data=df, REML=TRUE)
  m1b <- lmer(f1b, data=df, REML=TRUE)
  v0 <- as.numeric(VarCorr(m1a)[[1]]); ve0 <- sigma(m1a)^2
  v1 <- as.numeric(VarCorr(m1b)[[1]])
  list(n_estratos = nlevels(df[[estrato_col]]),
       vpc = 100*v0/(v0+ve0), pcv = 100*(v0-v1)/v0)
}

tab_sens <- data.table()
for (et in names(arqs)) {
  df_et <- all_d[etapa == et]
  for (disc in c("lp","mt")) {
    col <- paste0("prof_", disc)
    r3   <- calc(df_et, col, "estrato_3",      "raca_3")
    rbin <- calc(df_et, col, "estrato_bin",    "raca_bin")
    rmov <- calc(df_et, col, "estrato_movneg", "raca_movneg")
    tab_sens <- rbind(tab_sens, data.table(
      Etapa = etapa_nome[et], Disciplina = toupper(disc),
      `VPC B/P/P (18)`           = round(r3$vpc, 2),
      `PCV B/P/P`                = round(r3$pcv, 2),
      `VPC Branca/NB (12)`       = round(rbin$vpc, 2),
      `PCV Branca/NB`            = round(rbin$pcv, 2),
      `VPC Branca/Negra (12)`    = round(rmov$vpc, 2),
      `PCV Branca/Negra`         = round(rmov$pcv, 2)
    ))
  }
}
print(tab_sens)
fwrite(tab_sens, file.path(DIR_TAB, "TS_sens_esquemas_raca.csv"))

cat("\n=> Saídas: paper/tabelas/{T1, T2, T3, T4, TS_sens, TS0}.csv\n")
