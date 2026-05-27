## 08 — Paper figures (English) — Race Ethnicity and Education submission
## Mirrors 07_figuras_paper.R with English labels.
## Terminology choices:
##   - White / Brown / Black (Telles 2004, Bailey 2009 convention for BR race)
##   - Reading / Math (PISA/OECD convention for LP/MT)
##   - 5th / 9th / 12th grade (US convention for 5º EF / 9º EF / 3º EM)
##   - SES tertile (for tercil de INSE)
suppressMessages({
  library(arrow); library(data.table); library(ggplot2); library(lme4); library(pROC); library(scales); library(ggrepel)
})
source(here::here("pipeline/R/00_setup.R"))

DIR_FIG <- here::here("academico/maihda_saeb2023/paper/figures")
dir.create(DIR_FIG, showWarnings = FALSE, recursive = TRUE)

## ----- theme and palette -----
tema_paper <- theme_minimal(base_size = 11, base_family = "Helvetica") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(color = "grey30", size = 10),
    plot.caption = element_text(color = "grey50", size = 8, hjust = 0)
  )
cor_raca <- c("White" = "#3B6AA0", "Brown" = "#D58536", "Black" = "#9E2A2B")
cor_disc <- c("Reading" = "#3B6AA0", "Math" = "#9E2A2B")

## label maps PT -> EN
raca_pt2en  <- c("Branca" = "White", "Parda" = "Brown", "Preta" = "Black")
sexo_pt2en  <- c("Masculino" = "Male", "Feminino" = "Female")
inse_pt2en  <- c("Baixo" = "Low", "Médio" = "Medium", "Alto" = "High")
etapa_pt2en <- c("5º EF" = "5th grade", "9º EF" = "9th grade", "3º EM" = "12th grade")
disc_pt2en  <- c("LP" = "Reading", "MT" = "Math")

resultados <- readRDS(file.path(DIR_PROC, "maihda_v1_resultados.rds"))
auc_tab    <- fread(file.path(DIR_PROC, "maihda_v1_auc.csv"))

## ============================================================
## FIGURE 2 — Caterpillar plot, 6 panels (BLUPs with 95% CI)
## ============================================================
cat("\n========== FIG 2 — Caterpillar plot ==========\n")

cat_dt <- rbindlist(lapply(resultados, function(r) {
  d <- as.data.table(r$ranking)
  d[, Etapa := etapa_pt2en[r$etapa]]
  d[, Disciplina := disc_pt2en[r$disciplina]]
  d[, painel := paste(Etapa, "·", Disciplina)]
  parts <- tstrsplit(d$estrato, " \\| ", names = c("raca","sexo","inse"))
  d[, raca := factor(raca_pt2en[parts$raca], levels = c("White","Brown","Black"))]
  d[, sexo := factor(sexo_pt2en[parts$sexo], levels = c("Male","Female"))]
  d[, inse := factor(inse_pt2en[parts$inse], levels = c("Low","Medium","High"))]
  d
}))
cat_dt[, painel := factor(painel, levels = c(
  "5th grade · Reading","5th grade · Math",
  "9th grade · Reading","9th grade · Math",
  "12th grade · Reading","12th grade · Math"
))]
cat_dt[, ord := frank(predicted_1A), by = painel]

intercept_dt <- rbindlist(lapply(resultados, function(r) data.table(
  painel = paste(etapa_pt2en[r$etapa], "·", disc_pt2en[r$disciplina]),
  intercept = mean(r$ranking$intercept_global)
)))
intercept_dt[, painel := factor(painel, levels = levels(cat_dt$painel))]

## ----- highlighted strata: Black-Male-High in Reading; Black-Female-High in Math
highlight_dt <- cat_dt[
  (raca == "Black" & inse == "High" & sexo == "Male"   & grepl("Reading", painel)) |
  (raca == "Black" & inse == "High" & sexo == "Female" & grepl("Math",    painel))
]
highlight_dt[, lbl := paste0(
  "Black-", sexo, "-High SES\n",
  sprintf("%.0f (CI %.0f-%.0f)", predicted_1A, ic_lo, ic_hi)
)]

p_f2 <- ggplot(cat_dt, aes(x = ord, y = predicted_1A)) +
  geom_hline(data = intercept_dt, aes(yintercept = intercept),
             linetype = "dashed", color = "grey55", linewidth = 0.4) +
  ## 95% CIs as linerange — typically narrower than markers (see caption)
  geom_linerange(aes(ymin = ic_lo, ymax = ic_hi, color = raca, alpha = inse),
                 linewidth = 0.45, show.legend = FALSE) +
  geom_point(aes(color = raca, shape = sexo, alpha = inse),
             size = 2.6, stroke = 0.55) +
  ## ring on highlighted strata
  geom_point(data = highlight_dt,
             aes(x = ord, y = predicted_1A),
             shape = 21, size = 6.5, stroke = 1.1,
             color = "grey15", fill = NA, inherit.aes = FALSE) +
  ## labels on highlighted strata — repelled to avoid panel-edge clipping
  geom_label_repel(data = highlight_dt,
                   aes(x = ord, y = predicted_1A, label = lbl),
                   inherit.aes = FALSE,
                   size = 2.7, lineheight = 0.95,
                   color = "grey15", family = "Helvetica",
                   label.size = 0.25, label.r = unit(0.1, "lines"),
                   label.padding = unit(0.15, "lines"),
                   fill = "white", alpha = 0.95,
                   box.padding = 0.5, point.padding = 0.6,
                   segment.color = "grey50", segment.size = 0.3,
                   min.segment.length = 0,
                   force = 5, max.overlaps = Inf,
                   seed = 42) +
  scale_color_manual(values = cor_raca, name = "Race/color") +
  scale_shape_manual(values = c("Male" = 16, "Female" = 17), name = "Sex") +
  scale_alpha_manual(values = c("Low" = 0.40, "Medium" = 0.70, "High" = 1.00),
                     name = "SES tertile") +
  facet_wrap(~ painel, ncol = 2, scales = "free") +
  labs(
    title    = "Figure 2. Caterpillar plot of intersectional strata (BLUPs with 95% CI)",
    subtitle = "Strata ordered by M1A predicted proficiency within each panel. Dashed line = global intercept of the null model.",
    x        = "Stratum (ordered by predicted proficiency)",
    y        = "Predicted proficiency (SAEB scale, 0-500)",
    caption  = paste(
      "SAEB 2023, student-level microdata; 18 strata = race (3) x sex (2) x SES tertile (3); N = 4.8 million students.",
      "Color = race, shape = sex, transparency = SES tertile (Low / Medium / High).",
      "95% CIs are plotted as vertical lineranges; due to very large within-stratum N, CIs are typically narrower than the markers and may not be visible.",
      "Black rings highlight Black-Male-High SES (Reading panels) and Black-Female-High SES (Math panels):",
      "intersectional positions where high SES does not compensate for the racial-sex disadvantage.",
      "Brown denotes Parda self-identification (mixed-race) in the Brazilian census tradition (Telles 2004).",
      sep = "\n"
    )
  ) +
  tema_paper +
  theme(axis.text.x = element_blank(),
        axis.ticks.x = element_blank(),
        legend.position = "right",
        legend.box = "vertical",
        legend.spacing.y = unit(0.1, "cm"),
        plot.caption = element_text(color = "grey45", size = 8.5, hjust = 0,
                                    margin = margin(t = 8)))

ggsave(file.path(DIR_FIG, "F2_caterpillar.png"), p_f2, width = 12, height = 11.5, dpi = 300)
ggsave(file.path(DIR_FIG, "F2_caterpillar.pdf"), p_f2, width = 12, height = 11.5)
cat("  saved: F2_caterpillar.{png,pdf}\n")

## ============================================================
## FIGURE 2 — Scatter u_M1A vs u_M1B (additivity paradox)
## ============================================================
cat("\n========== FIG 2 — Scatter u_M1A vs u_M1B ==========\n")

scat_dt <- copy(cat_dt)
xy_lim <- max(abs(c(scat_dt$u_1A, scat_dt$u_1B)), na.rm=TRUE) * 1.05

p_f2 <- ggplot(scat_dt, aes(x = u_1A, y = u_1B)) +
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.4) +
  geom_vline(xintercept = 0, color = "grey60", linewidth = 0.4) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = u_1B - 1.96 * se_1B, ymax = u_1B + 1.96 * se_1B),
                width = 0, color = "grey60", alpha = 0.5) +
  geom_errorbar(aes(xmin = u_1A - 1.96 * se_1A, xmax = u_1A + 1.96 * se_1A),
                orientation = "y", height = 0, color = "grey60", alpha = 0.5) +
  geom_point(aes(color = raca, shape = sexo), size = 2.5) +
  scale_color_manual(values = cor_raca, name = "Race/color") +
  scale_shape_manual(values = c("Male" = 16, "Female" = 17), name = "Sex") +
  facet_wrap(~ painel, ncol = 2) +
  coord_fixed(xlim = c(-xy_lim, xy_lim), ylim = c(-xy_lim, xy_lim)) +
  labs(
    title = "Figure 2. Intersectional effects before (M1A) and after (M1B) main-effect adjustment",
    subtitle = "Points on the dashed identity line = no additive explanation. Points collapsing to y=0 = full additivity.",
    x = expression(u[j]~"from null model (M1A)"),
    y = expression(u[j]~"from additive model (M1B), net of race + sex + SES + school sector"),
    caption = paste0(
      "The closer the points fall to y=0, the more the stratum effect is captured by additive main effects. PCV ~ 95% across all six models.\n",
      "Residual deviations from y=0 (notably Black-Male-High SES in Reading) signal genuine multiplicative intersectional effects that the additive model cannot absorb."
    )
  ) +
  tema_paper

ggsave(file.path(DIR_FIG, "F2_scatter_u1A_u1B.png"), p_f2, width = 10, height = 12, dpi = 300)
ggsave(file.path(DIR_FIG, "F2_scatter_u1A_u1B.pdf"), p_f2, width = 10, height = 12)
cat("  saved: F2_scatter_u1A_u1B.{png,pdf}\n")

## ============================================================
## FIGURE 1 — VPC trajectory: raw vs reweighted by cohort composition
## ============================================================
cat("\n========== FIG 1 — VPC trajectory ==========\n")

sobr <- fread(file.path(DIR_PROC, "maihda_v1_sobrevivencia.csv"))
sobr_long <- melt(sobr, id.vars = "disciplina",
                  measure.vars = c("VPC 5EF","VPC 9EF bruto","VPC 9EF reponderado",
                                   "VPC 3EM bruto","VPC 3EM reponderado"),
                  variable.name = "var", value.name = "vpc")
sobr_long[, grade := fcase(grepl("5EF", var), "5th grade",
                           grepl("9EF", var), "9th grade",
                           grepl("3EM", var), "12th grade")]
sobr_long[, grade := factor(grade, levels = c("5th grade","9th grade","12th grade"))]
sobr_long[, kind := fcase(grepl("reponderado", var), "Reweighted",
                          grepl("bruto", var), "Raw",
                          default = "Raw")]
sobr_long[, kind := factor(kind, levels = c("Raw","Reweighted"))]
sobr_long[, subject := disc_pt2en[disciplina]]
sobr_long[, subject := factor(subject, levels = c("Reading","Math"))]

## drawing order: Raw first, Reweighted on top — ensures the dashed line is visible
## when values nearly overlap.
setorder(sobr_long, subject, kind, grade)

threshold_lbl <- data.table(
  grade   = factor("5th grade", levels = c("5th grade","9th grade","12th grade")),
  vpc     = 5.4, subject = "Reading", kind = factor("Raw", levels = c("Raw","Reweighted")),
  lbl     = "Substantive threshold (5%)"
)

p_f1 <- ggplot(sobr_long, aes(x = grade, y = vpc, color = subject,
                              group = interaction(subject, kind))) +
  geom_hline(yintercept = 5, linetype = "dotted", color = "grey55", linewidth = 0.4) +
  geom_hline(yintercept = 1, linetype = "dotted", color = "grey75", linewidth = 0.3) +
  geom_text(data = threshold_lbl, aes(label = lbl), size = 2.9, color = "grey35",
            hjust = 0, vjust = -0.3, show.legend = FALSE, inherit.aes = TRUE,
            family = "Helvetica") +
  ## Raw line (solid, slightly thicker, drawn first)
  geom_line(data = sobr_long[kind == "Raw"],
            aes(linetype = kind), linewidth = 1.0) +
  ## Reweighted line (dashed, drawn on top, intentionally narrower to "ride" on the raw)
  geom_line(data = sobr_long[kind == "Reweighted"],
            aes(linetype = kind), linewidth = 0.8) +
  geom_point(data = sobr_long[kind == "Raw"],
             aes(shape = kind), size = 3.2, stroke = 0.6) +
  geom_point(data = sobr_long[kind == "Reweighted"],
             aes(shape = kind), size = 3.0, stroke = 1.1, fill = "white") +
  scale_color_manual(values = cor_disc, name = "Subject") +
  scale_linetype_manual(values = c("Raw" = "solid", "Reweighted" = "longdash"),
                        name = "Estimate") +
  scale_shape_manual(values = c("Raw" = 16, "Reweighted" = 21),
                     name = "Estimate") +
  scale_y_continuous(labels = function(x) paste0(x, "%"),
                     limits = c(0, max(sobr_long$vpc) * 1.12),
                     expand = expansion(mult = c(0, 0.02))) +
  scale_x_discrete(expand = expansion(add = c(0.4, 0.6))) +
  labs(
    title    = "Figure 1. VPC trajectory across basic-education grades",
    subtitle = "Reweighted estimates simulate the 9th- and 12th-grade cohorts under 5th-grade stratum composition.",
    x        = NULL,
    y        = "VPC (% of variance at stratum level)",
    caption  = paste(
      "Solid lines = raw estimates; dashed lines = post-stratification reweighted estimates.",
      "Raw and reweighted values nearly coincide, indicating that the across-grade VPC decline",
      "is not driven by changes in stratum composition.",
      sep = "\n"
    )
  ) +
  tema_paper +
  theme(legend.position = "right",
        legend.box = "vertical",
        legend.spacing.y = unit(0.1, "cm"),
        plot.caption = element_text(color = "grey45", size = 8.5, hjust = 0,
                                    margin = margin(t = 8)))

ggsave(file.path(DIR_FIG, "F1_vpc_trajectory.png"), p_f1, width = 10.5, height = 6, dpi = 300)
ggsave(file.path(DIR_FIG, "F1_vpc_trajectory.pdf"), p_f1, width = 10.5, height = 6)
cat("  saved: F1_vpc_trajectory.{png,pdf}\n")

## ============================================================
## FIGURE 4 — Heatmap: race x SES x sex mean proficiency
## ============================================================
cat("\n========== FIG 4 — Heatmap ==========\n")

raca_lbl <- c("A"="Branca","B"="Preta","C"="Parda")
sexo_lbl <- c("A"="Masculino","B"="Feminino")
arqs <- c("5ef"="saeb_2023_5ef.parquet","9ef"="saeb_2023_9ef.parquet","3em"="saeb_2023_3em.parquet")
etapa_nome <- c("5ef"="5º EF","9ef"="9º EF","3em"="3º EM")

carregar <- function(et) {
  dt <- as.data.table(read_parquet(file.path(DIR_PROC, arqs[et])))
  dt <- dt[tx_resp_q04 %in% c("A","B","C") & tx_resp_q01 %in% c("A","B") &
           !is.na(inse_aluno) & !is.na(in_publica) &
           !is.na(proficiencia_lp_saeb) & !is.na(proficiencia_mt_saeb)]
  dt[, raca := raca_pt2en[raca_lbl[tx_resp_q04]]]
  dt[, sexo := sexo_pt2en[sexo_lbl[tx_resp_q01]]]
  dt[, etapa := et]
  dt[, .(etapa, raca, sexo, inse_aluno,
         prof_lp = proficiencia_lp_saeb, prof_mt = proficiencia_mt_saeb)]
}
all_d <- rbindlist(lapply(names(arqs), carregar))
brks <- quantile(all_d$inse_aluno, c(0, 1/3, 2/3, 1), na.rm = TRUE)
all_d[, inse_tercil := cut(inse_aluno, breaks = brks,
                            labels = c("Low","Medium","High"), include.lowest = TRUE)]
all_d[, raca := factor(raca, levels = c("White","Brown","Black"))]
all_d[, sexo := factor(sexo, levels = c("Male","Female"))]
all_d[, etapa_lbl := factor(etapa_pt2en[etapa_nome[etapa]],
                             levels = c("5th grade","9th grade","12th grade"))]

heat_lp <- all_d[, .(prof = mean(prof_lp), n = .N),
                 by = .(etapa_lbl, raca, sexo, inse_tercil)]
heat_mt <- all_d[, .(prof = mean(prof_mt), n = .N),
                 by = .(etapa_lbl, raca, sexo, inse_tercil)]
heat_lp[, subject := "Reading"]; heat_mt[, subject := "Math"]
heat <- rbind(heat_lp, heat_mt)
heat[, painel := paste(etapa_lbl, "·", subject)]
heat[, painel := factor(painel, levels = c(
  "5th grade · Reading","5th grade · Math",
  "9th grade · Reading","9th grade · Math",
  "12th grade · Reading","12th grade · Math"
))]

p_f4 <- ggplot(heat, aes(x = inse_tercil, y = raca, fill = prof)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(aes(label = round(prof)), size = 2.8, color = "white", fontface = "bold") +
  scale_fill_viridis_c(option = "magma", direction = -1, name = "Mean\nproficiency") +
  facet_grid(sexo ~ painel) +
  labs(
    title = "Figure 4. Mean proficiency by intersectional position",
    subtitle = "Race (rows) x SES tertile (columns) x sex (outer rows), by grade and subject.",
    x = "SES tertile",
    y = "Self-declared race/color",
    caption = "SAEB 2023, n=4.8 million. Official SAEB scale (0-500). Brown = Parda (mixed-race) in the Brazilian census tradition."
  ) +
  tema_paper +
  theme(panel.grid.major = element_blank(),
        strip.text.x = element_text(size = 9))

ggsave(file.path(DIR_FIG, "F4_heatmap.png"), p_f4, width = 13, height = 5.5, dpi = 300)
ggsave(file.path(DIR_FIG, "F4_heatmap.pdf"), p_f4, width = 13, height = 5.5)
cat("  saved: F4_heatmap.{png,pdf}\n")

## ============================================================
## FIGURE 5 — ROC curves: discriminatory accuracy of M1A vs Adequate+
## ============================================================
cat("\n========== FIG 5 — ROC ==========\n")

cortes_adeq <- list(
  lp = c("5ef"=225,"9ef"=275,"3em"=325),
  mt = c("5ef"=225,"9ef"=300,"3em"=350)
)

roc_long <- data.table()
auc_anota <- data.table()
for (et in names(arqs)) {
  df_et <- all_d[etapa == et]
  df_et[, estrato := factor(paste(raca, sexo, inse_tercil, sep = " | "))]
  for (disc in c("lp","mt")) {
    col <- paste0("prof_", disc)
    cat(sprintf("  fitting M1A %s %s ...", etapa_pt2en[etapa_nome[et]], disc_pt2en[toupper(disc)]))
    m <- lmer(as.formula(paste(col, "~ 1 + (1 | estrato)")), data = df_et, REML = TRUE)
    pred <- as.numeric(predict(m))
    y <- as.integer(df_et[[col]] >= cortes_adeq[[disc]][et])
    set.seed(1); idx <- sample.int(length(pred), min(50000, length(pred)))
    r <- pROC::roc(y[idx], pred[idx], quiet = TRUE)
    df <- data.table(
      fpr = 1 - r$specificities, tpr = r$sensitivities,
      painel = paste(etapa_pt2en[etapa_nome[et]], "·", disc_pt2en[toupper(disc)])
    )
    roc_long <- rbind(roc_long, df)
    auc_anota <- rbind(auc_anota, data.table(
      painel = paste(etapa_pt2en[etapa_nome[et]], "·", disc_pt2en[toupper(disc)]),
      auc = auc_tab[modelo == paste(etapa_nome[et], toupper(disc)), AUC]
    ))
    cat(" done\n")
  }
}
roc_long[, painel := factor(painel, levels = c(
  "5th grade · Reading","5th grade · Math",
  "9th grade · Reading","9th grade · Math",
  "12th grade · Reading","12th grade · Math"
))]
auc_anota[, painel := factor(painel, levels = levels(roc_long$painel))]
auc_anota[, lbl := sprintf("AUC = %.3f", auc)]

p_f5 <- ggplot(roc_long, aes(x = fpr, y = tpr)) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_path(linewidth = 0.7, color = "#3B6AA0") +
  geom_text(data = auc_anota, aes(x = 0.95, y = 0.05, label = lbl),
            hjust = 1, size = 3.2, fontface = "bold") +
  facet_wrap(~ painel, ncol = 2) +
  coord_fixed() +
  scale_x_continuous(labels = label_percent()) +
  scale_y_continuous(labels = label_percent()) +
  labs(
    title = "Figure 5. Discriminatory accuracy: intersectional position vs. Adequate+",
    subtitle = "ROC of M1A predicted values against a binary outcome at the official INEP proficiency threshold. 50,000 sampled per model.",
    x = "False-positive rate (1 - specificity)",
    y = "True-positive rate (sensitivity)",
    caption = "Modest AUC (0.62-0.67) indicates that intersectional position conditions, but does not determine, individual outcomes. Anti-essentialist reading."
  ) +
  tema_paper

ggsave(file.path(DIR_FIG, "F5_roc.png"), p_f5, width = 9, height = 12, dpi = 300)
ggsave(file.path(DIR_FIG, "F5_roc.pdf"), p_f5, width = 9, height = 12)
cat("  saved: F5_roc.{png,pdf}\n")

cat("\n=> Outputs: paper/figures/{F1..F5}.{png,pdf}\n")
