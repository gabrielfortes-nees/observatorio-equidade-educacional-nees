## 09 — Paper tables (English) — Race Ethnicity and Education submission
## Mirrors 06_tabelas_paper.R with English labels.
## Terminology aligned with 08_figures_paper_en.R.
suppressMessages({
  library(arrow); library(data.table); library(lme4); library(broom.mixed)
})
source(here::here("pipeline/R/00_setup.R"))

DIR_TAB <- here::here("academico/maihda_saeb2023/paper/tables")
dir.create(DIR_TAB, showWarnings = FALSE, recursive = TRUE)

## label maps PT -> EN
raca_pt2en  <- c("Branca" = "White", "Parda" = "Brown", "Preta" = "Black")
sexo_pt2en  <- c("Masculino" = "Male", "Feminino" = "Female")
inse_pt2en  <- c("Baixo" = "Low", "Médio" = "Medium", "Alto" = "High")
etapa_pt2en <- c("5º EF" = "5th grade", "9º EF" = "9th grade", "3º EM" = "12th grade")
disc_pt2en  <- c("LP" = "Reading", "MT" = "Math")

raca_lbl <- c("A"="Branca","B"="Preta","C"="Parda","D"="Amarela","E"="Indigena","F"="NotDeclared")
sexo_lbl <- c("A"="Masculino","B"="Feminino")
arqs <- c("5ef"="saeb_2023_5ef.parquet","9ef"="saeb_2023_9ef.parquet","3em"="saeb_2023_3em.parquet")
etapa_nome_pt <- c("5ef"="5º EF","9ef"="9º EF","3em"="3º EM")

## ----- read microdata (with full race coding to report exclusions) -----
carregar_full <- function(et) {
  dt <- as.data.table(read_parquet(file.path(DIR_PROC, arqs[et])))
  dt[, etapa := et]
  dt[, raca_full := raca_lbl[tx_resp_q04]]
  dt[, sexo_full := sexo_lbl[tx_resp_q01]]
  dt[, rede := fifelse(in_publica == 1, "Public", "Private")]
  dt
}
raw <- rbindlist(lapply(names(arqs), carregar_full), fill = TRUE)

cat("\n========== Exclusion inventory (TS0) ==========\n")
inv <- raw[, .(
  grade = etapa_pt2en[etapa_nome_pt[etapa]],
  n_total_raw          = .N,
  n_excl_Yellow        = sum(raca_full == "Amarela", na.rm=TRUE),
  n_excl_Indigenous    = sum(raca_full == "Indigena", na.rm=TRUE),
  n_excl_NotDeclared   = sum(raca_full == "NotDeclared", na.rm=TRUE),
  n_NA_race            = sum(is.na(raca_full)),
  n_NA_sex             = sum(is.na(sexo_full)),
  n_NA_SES             = sum(is.na(inse_aluno)),
  n_NA_sector          = sum(is.na(in_publica)),
  n_NA_reading         = sum(is.na(proficiencia_lp_saeb)),
  n_NA_math            = sum(is.na(proficiencia_mt_saeb))
), by = etapa]
inv[, etapa := NULL]
print(inv)
fwrite(inv, file.path(DIR_TAB, "TS0_exclusion_inventory.csv"))

## ----- analytic sample (same criteria as the 6 models) -----
all_d <- raw[tx_resp_q04 %in% c("A","B","C") & tx_resp_q01 %in% c("A","B") &
             !is.na(inse_aluno) & !is.na(in_publica) &
             !is.na(proficiencia_lp_saeb) & !is.na(proficiencia_mt_saeb),
           .(etapa,
             raca = raca_pt2en[raca_full],
             sexo = sexo_pt2en[sexo_full],
             rede,
             inse_aluno,
             prof_reading = proficiencia_lp_saeb,
             prof_math    = proficiencia_mt_saeb)]

brks <- quantile(all_d$inse_aluno, c(0, 1/3, 2/3, 1), na.rm = TRUE)
all_d[, ses_tertile := cut(inse_aluno, breaks = brks,
                            labels = c("Low","Medium","High"), include.lowest = TRUE)]
all_d[, raca := factor(raca, levels = c("White","Brown","Black"))]
all_d[, sexo := factor(sexo, levels = c("Male","Female"))]
all_d[, rede := factor(rede, levels = c("Public","Private"))]
all_d[, grade := factor(etapa_pt2en[etapa_nome_pt[etapa]],
                         levels = c("5th grade","9th grade","12th grade"))]
all_d[, stratum := factor(paste(raca, sexo, ses_tertile, sep = " | "))]

## ============================================================
## TABLE 1 — Sample characterization
## ============================================================
cat("\n========== TABLE 1 — Sample characterization ==========\n")

pct <- function(x, lvl) round(mean(x == lvl, na.rm=TRUE) * 100, 1)

tab1 <- all_d[, .(
  N                  = format(.N, big.mark=","),
  `% White`          = pct(raca, "White"),
  `% Brown`          = pct(raca, "Brown"),
  `% Black`          = pct(raca, "Black"),
  `% Male`           = pct(sexo, "Male"),
  `% Female`         = pct(sexo, "Female"),
  `% SES Low`        = pct(ses_tertile, "Low"),
  `% SES Medium`     = pct(ses_tertile, "Medium"),
  `% SES High`       = pct(ses_tertile, "High"),
  `% Public`         = pct(rede, "Public"),
  `% Private`        = pct(rede, "Private"),
  `Mean SES`         = round(mean(inse_aluno, na.rm=TRUE), 2),
  `Mean Reading`     = round(mean(prof_reading, na.rm=TRUE), 1),
  `Mean Math`        = round(mean(prof_math,    na.rm=TRUE), 1)
), by = grade]
setnames(tab1, "grade", "Grade")
print(t(tab1))
fwrite(tab1, file.path(DIR_TAB, "T1_sample_characterization.csv"))

## ============================================================
## TABLE 2 — M1A / M1B results (VPC, PCV, AUC)
## ============================================================
cat("\n========== TABLE 2 — M1A / M1B results ==========\n")

resultados <- readRDS(file.path(DIR_PROC, "maihda_v1_resultados.rds"))
auc_tab    <- fread(file.path(DIR_PROC, "maihda_v1_auc.csv"))
setnames(auc_tab, c("modelo","n","pct_adeq_plus","AUC"))

tab2 <- rbindlist(lapply(resultados, function(r) data.table(
  Grade        = etapa_pt2en[r$etapa],
  Subject      = disc_pt2en[r$disciplina],
  N            = format(r$n, big.mark=","),
  `Var(u) M1A` = round(r$v_u_1a, 2),
  `Var(e) M1A` = round(r$v_e_1a, 2),
  `VPC M1A (%)`= round(r$vpc_1a * 100, 2),
  `Var(u) M1B` = round(r$v_u_1b, 4),
  `VPC M1B (%)`= round(r$vpc_1b * 100, 2),
  `PCV (%)`    = round(r$pcv * 100, 2),
  `% Adequate+`= NA_real_,
  AUC          = NA_real_
)))
## fill AUC and % Adequate+ from auc_tab
for (i in seq_len(nrow(tab2))) {
  # auc_tab uses PT etapa labels e.g. "5º EF LP"; map back
  etapa_pt <- names(etapa_pt2en)[match(tab2$Grade[i], etapa_pt2en)]
  disc_pt  <- names(disc_pt2en)[match(tab2$Subject[i], disc_pt2en)]
  m <- auc_tab[modelo == paste(etapa_pt, disc_pt)]
  if (nrow(m) == 1) {
    tab2[i, `% Adequate+` := round(m$pct_adeq_plus, 1)]
    tab2[i, AUC := round(m$AUC, 3)]
  }
}
print(tab2)
fwrite(tab2, file.path(DIR_TAB, "T2_M1A_M1B_results.csv"))

## ============================================================
## TABLE 3 — Fixed effects of M1B
## ============================================================
cat("\n========== TABLE 3 — Fixed effects of M1B ==========\n")

## mapping for term labels
term_pt2en <- c(
  "(Intercept)"      = "(Intercept)",
  "racaParda"        = "Race: Brown",
  "racaPreta"        = "Race: Black",
  "sexoFeminino"     = "Sex: Female",
  "inse_tercilMédio" = "SES: Medium",
  "inse_tercilAlto"  = "SES: High",
  "redePrivada"      = "School: Private"
)

tab3 <- rbindlist(lapply(resultados, function(r) {
  d <- as.data.table(r$coefs)
  d[, Grade   := etapa_pt2en[r$etapa]]
  d[, Subject := disc_pt2en[r$disciplina]]
  d[, Term    := term_pt2en[term]]
  d[, .(Grade, Subject, Term,
        beta       = round(estimate, 2),
        SE         = round(std.error, 3),
        `CI95% lo` = round(conf.low, 2),
        `CI95% hi` = round(conf.high, 2),
        `t`        = round(statistic, 2),
        sig        = fcase(abs(statistic) > 3.29, "***",
                           abs(statistic) > 2.58, "**",
                           abs(statistic) > 1.96, "*",
                           default = ""))]
}))
print(tab3)
fwrite(tab3, file.path(DIR_TAB, "T3_M1B_fixed_effects.csv"))

## ============================================================
## TABLE 4 — Extreme strata (5 most disadvantaged + 5 most advantaged)
## ============================================================
cat("\n========== TABLE 4 — Extreme strata ==========\n")

translate_stratum <- function(s) {
  ## "Branca | Feminino | Alto" -> "White | Female | High"
  sapply(strsplit(s, " \\| "), function(parts) {
    paste(raca_pt2en[parts[1]], sexo_pt2en[parts[2]], inse_pt2en[parts[3]], sep = " | ")
  })
}

tab4 <- rbindlist(lapply(resultados, function(r) {
  dt <- as.data.table(r$ranking)
  dt[, Grade   := etapa_pt2en[r$etapa]]
  dt[, Subject := disc_pt2en[r$disciplina]]
  dt[, estrato_en := translate_stratum(estrato)]
  dt_ord <- dt[order(predicted_1A)]
  out <- rbind(
    head(dt_ord, 5)[, position := "Disadvantaged"],
    tail(dt_ord, 5)[, position := "Advantaged"]
  )
  out[, sig_uj_M1A := fifelse(abs(u_1A/se_1A) > 1.96, "*", "")]
  out[, sig_uj_M1B_lbl := fifelse(sig_uj_1B, "*", "")]
  out[, .(Grade, Subject, position,
          Stratum    = estrato_en,
          `Pred (M1A)` = round(predicted_1A, 1),
          `CI95% lo` = round(ic_lo, 1),
          `CI95% hi` = round(ic_hi, 1),
          uj_M1A     = round(u_1A, 2),
          uj_M1B     = round(u_1B, 2),
          sig_M1A    = sig_uj_M1A,
          sig_M1B    = sig_uj_M1B_lbl)]
}))
print(tab4)
fwrite(tab4, file.path(DIR_TAB, "T4_extreme_strata.csv"))

## ============================================================
## SUPPLEMENTARY — Sensitivity of race coding (McCall anti-categorical)
## ============================================================
cat("\n========== TS_sens — Race coding sensitivity ==========\n")

## three schemes
all_d[, race_3      := raca]                                       # White, Brown, Black
all_d[, race_bin    := fifelse(raca == "White", "White", "Non-White")]
all_d[, race_bin    := factor(race_bin, levels = c("White","Non-White"))]
all_d[, race_movneg := fcase(raca == "White", "White",
                             raca %in% c("Brown","Black"), "Black (incl. Brown)")]
all_d[, race_movneg := factor(race_movneg, levels = c("White","Black (incl. Brown)"))]

all_d[, stratum_3      := factor(paste(race_3,      sexo, ses_tertile, sep="|"))]
all_d[, stratum_bin    := factor(paste(race_bin,    sexo, ses_tertile, sep="|"))]
all_d[, stratum_movneg := factor(paste(race_movneg, sexo, ses_tertile, sep="|"))]

calc <- function(df, outcome, stratum_col, race_col) {
  f1a <- as.formula(paste(outcome, "~ 1 + (1 |", stratum_col, ")"))
  f1b <- as.formula(paste(outcome, "~", race_col,
                          "+ sexo + ses_tertile + rede + (1 |", stratum_col, ")"))
  m1a <- lmer(f1a, data=df, REML=TRUE)
  m1b <- lmer(f1b, data=df, REML=TRUE)
  v0 <- as.numeric(VarCorr(m1a)[[1]]); ve0 <- sigma(m1a)^2
  v1 <- as.numeric(VarCorr(m1b)[[1]])
  list(vpc = 100*v0/(v0+ve0), pcv = 100*(v0-v1)/v0)
}

tab_sens <- data.table()
for (gr in levels(all_d$grade)) {
  df_g <- all_d[grade == gr]
  for (subj in c("reading","math")) {
    col <- paste0("prof_", subj)
    r3   <- calc(df_g, col, "stratum_3",      "race_3")
    rbin <- calc(df_g, col, "stratum_bin",    "race_bin")
    rmov <- calc(df_g, col, "stratum_movneg", "race_movneg")
    tab_sens <- rbind(tab_sens, data.table(
      Grade   = gr,
      Subject = ifelse(subj == "reading", "Reading", "Math"),
      `VPC W/Br/Bl (18 strata)`        = round(r3$vpc, 2),
      `PCV W/Br/Bl`                    = round(r3$pcv, 2),
      `VPC W/Non-W (12 strata)`        = round(rbin$vpc, 2),
      `PCV W/Non-W`                    = round(rbin$pcv, 2),
      `VPC W/Black-incl-Brown (12)`    = round(rmov$vpc, 2),
      `PCV W/Black-incl-Brown`         = round(rmov$pcv, 2)
    ))
  }
}
print(tab_sens)
fwrite(tab_sens, file.path(DIR_TAB, "TS_sens_race_coding.csv"))

cat("\n=> Outputs: paper/tables/{T1, T2, T3, T4, TS_sens, TS0}.csv\n")
