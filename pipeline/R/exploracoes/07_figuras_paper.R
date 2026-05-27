## 07 — Figuras do paper MAIHDA
## F1 Caterpillar 6 painéis · F2 Scatter u_M1A vs u_M1B (paradoxo aditivo)
## F3 Trajetória VPC bruto vs reponderado · F4 Heatmap raça × INSE × sexo
## F5 ROC curves (DA) dos 6 modelos
suppressMessages({
  library(arrow); library(data.table); library(ggplot2); library(lme4); library(pROC); library(scales)
})
source(here::here("pipeline/R/00_setup.R"))

DIR_FIG <- here::here("academico/maihda_saeb2023/paper/figuras")
dir.create(DIR_FIG, showWarnings = FALSE, recursive = TRUE)

## ----- tema e paletas -----
tema_paper <- theme_minimal(base_size = 11, base_family = "Helvetica") +
  theme(
    panel.grid.minor = element_blank(),
    panel.grid.major.x = element_blank(),
    strip.text = element_text(face = "bold"),
    plot.title = element_text(face = "bold", size = 12),
    plot.subtitle = element_text(color = "grey30", size = 10),
    plot.caption = element_text(color = "grey50", size = 8, hjust = 0)
  )
cor_raca <- c("Branca" = "#3B6AA0", "Parda" = "#D58536", "Preta" = "#9E2A2B")
cor_disc <- c("LP" = "#3B6AA0", "MT" = "#9E2A2B")

resultados <- readRDS(file.path(DIR_PROC, "maihda_v1_resultados.rds"))
auc_tab    <- fread(file.path(DIR_PROC, "maihda_v1_auc.csv"))

## ============================================================
## FIGURA 1 — Caterpillar plot 6 painéis (BLUPs com IC95%)
## ============================================================
cat("\n========== FIG 1 — Caterpillar plot ==========\n")

cat_dt <- rbindlist(lapply(resultados, function(r) {
  d <- as.data.table(r$ranking)
  d[, Etapa := r$etapa]; d[, Disciplina := r$disciplina]
  d[, painel := paste(Etapa, "·", Disciplina)]
  ## separar componentes do estrato para colorir/formar
  parts <- tstrsplit(d$estrato, " \\| ", names = c("raca","sexo","inse"))
  d[, raca := factor(parts$raca, levels = c("Branca","Parda","Preta"))]
  d[, sexo := factor(parts$sexo, levels = c("Masculino","Feminino"))]
  d[, inse := factor(parts$inse, levels = c("Baixo","Médio","Alto"))]
  d
}))
cat_dt[, painel := factor(painel, levels = c(
  "5º EF · LP","5º EF · MT","9º EF · LP","9º EF · MT","3º EM · LP","3º EM · MT"
))]
## ordem por valor predito dentro do painel
cat_dt[, ord := frank(predicted_1A), by = painel]

intercept_dt <- rbindlist(lapply(resultados, function(r) data.table(
  painel = paste(r$etapa, "·", r$disciplina),
  intercept = mean(r$ranking$intercept_global)
)))
intercept_dt[, painel := factor(painel, levels = levels(cat_dt$painel))]

p_f1 <- ggplot(cat_dt, aes(x = ord, y = predicted_1A)) +
  geom_hline(data = intercept_dt, aes(yintercept = intercept),
             linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = ic_lo, ymax = ic_hi, color = raca),
                width = 0, linewidth = 0.4, alpha = 0.7) +
  geom_point(aes(color = raca, shape = sexo), size = 2.2, stroke = 0.6) +
  scale_color_manual(values = cor_raca, name = "Raça/cor") +
  scale_shape_manual(values = c("Masculino" = 16, "Feminino" = 17), name = "Sexo") +
  facet_wrap(~ painel, ncol = 2, scales = "free") +
  labs(
    title = "Figura 1. Caterpillar plot dos estratos interseccionais (BLUPs com IC 95%)",
    subtitle = "Estratos ordenados pela proficiência predita do M1A. Linha pontilhada = intercepto global do modelo nulo.",
    x = "Estrato (ordenado)",
    y = "Proficiência predita (escala SAEB)",
    caption = "SAEB 2023, microdados aluno. 18 estratos = raça (3) × sexo (2) × tercil de INSE (3). N=4,8 milhões."
  ) +
  tema_paper +
  theme(axis.text.x = element_blank())

ggsave(file.path(DIR_FIG, "F1_caterpillar.png"), p_f1, width = 10, height = 10, dpi = 300)
ggsave(file.path(DIR_FIG, "F1_caterpillar.pdf"), p_f1, width = 10, height = 10)
cat("  salvo: F1_caterpillar.{png,pdf}\n")

## ============================================================
## FIGURA 2 — Scatter u_M1A vs u_M1B (paradoxo da aditividade)
## ============================================================
cat("\n========== FIG 2 — Scatter u_M1A vs u_M1B ==========\n")

scat_dt <- copy(cat_dt)
## limites para os 6 painéis
xy_lim <- max(abs(c(scat_dt$u_1A, scat_dt$u_1B)), na.rm=TRUE) * 1.05

p_f2 <- ggplot(scat_dt, aes(x = u_1A, y = u_1B)) +
  geom_hline(yintercept = 0, color = "grey60", linewidth = 0.4) +
  geom_vline(xintercept = 0, color = "grey60", linewidth = 0.4) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "grey50") +
  geom_errorbar(aes(ymin = u_1B - 1.96 * se_1B, ymax = u_1B + 1.96 * se_1B),
                width = 0, color = "grey60", alpha = 0.5) +
  geom_errorbarh(aes(xmin = u_1A - 1.96 * se_1A, xmax = u_1A + 1.96 * se_1A),
                 height = 0, color = "grey60", alpha = 0.5) +
  geom_point(aes(color = raca, shape = sexo), size = 2.5) +
  scale_color_manual(values = cor_raca, name = "Raça/cor") +
  scale_shape_manual(values = c("Masculino" = 16, "Feminino" = 17), name = "Sexo") +
  facet_wrap(~ painel, ncol = 2) +
  coord_fixed(xlim = c(-xy_lim, xy_lim), ylim = c(-xy_lim, xy_lim)) +
  labs(
    title = "Figura 2. Efeito interseccional bruto (M1A) vs residual (M1B)",
    subtitle = "Pontos sobre a linha pontilhada = aditividade nula. Pontos colapsando para y=0 = aditividade total.",
    x = expression(u[j]~"do modelo nulo (M1A)"),
    y = expression(u[j]~"do modelo aditivo (M1B), após remover raça + sexo + INSE + rede"),
    caption = "Quanto mais próximos do eixo y=0, mais o efeito do estrato é explicado por efeitos principais aditivos. PCV ~ 95% em todos os modelos."
  ) +
  tema_paper

ggsave(file.path(DIR_FIG, "F2_scatter_u1A_u1B.png"), p_f2, width = 10, height = 12, dpi = 300)
ggsave(file.path(DIR_FIG, "F2_scatter_u1A_u1B.pdf"), p_f2, width = 10, height = 12)
cat("  salvo: F2_scatter_u1A_u1B.{png,pdf}\n")

## ============================================================
## FIGURA 3 — Trajetória do VPC bruto e reponderado por etapa
## ============================================================
cat("\n========== FIG 3 — Trajetória do VPC ==========\n")

sobr <- fread(file.path(DIR_PROC, "maihda_v1_sobrevivencia.csv"))
# transformar wide -> long
sobr_long <- melt(sobr, id.vars = "disciplina",
                  measure.vars = c("VPC 5EF","VPC 9EF bruto","VPC 9EF reponderado",
                                   "VPC 3EM bruto","VPC 3EM reponderado"),
                  variable.name = "var", value.name = "vpc")
sobr_long[, etapa := fcase(grepl("5EF", var), "5º EF",
                           grepl("9EF", var), "9º EF",
                           grepl("3EM", var), "3º EM")]
sobr_long[, etapa := factor(etapa, levels = c("5º EF","9º EF","3º EM"))]
sobr_long[, tipo := fcase(grepl("reponderado", var), "Reponderado (composição 5EF)",
                          grepl("bruto", var), "Bruto",
                          default = "Bruto")]

limiar_lbl <- data.table(etapa = factor("5º EF", levels = c("5º EF","9º EF","3º EM")),
                         vpc = 5.4, disciplina = "LP", tipo = "Bruto",
                         lbl = "limiar substantivo (5%)")

p_f3 <- ggplot(sobr_long, aes(x = etapa, y = vpc, color = disciplina, group = interaction(disciplina, tipo))) +
  geom_hline(yintercept = 5, linetype = "dotted", color = "grey50") +
  geom_hline(yintercept = 1, linetype = "dotted", color = "grey70") +
  geom_text(data = limiar_lbl, aes(label = lbl), size = 2.8, color = "grey40",
            hjust = 0, show.legend = FALSE, inherit.aes = TRUE) +
  geom_line(aes(linetype = tipo), linewidth = 0.7) +
  geom_point(aes(shape = tipo), size = 3) +
  scale_color_manual(values = cor_disc, name = "Disciplina") +
  scale_linetype_manual(values = c("Bruto" = "solid", "Reponderado (composição 5EF)" = "dashed"),
                        name = "Estimativa") +
  scale_shape_manual(values = c("Bruto" = 16, "Reponderado (composição 5EF)" = 1),
                     name = "Estimativa") +
  scale_y_continuous(labels = function(x) paste0(x, "%"), limits = c(0, max(sobr_long$vpc)*1.1)) +
  labs(
    title = "Figura 3. Trajetória do VPC ao longo da educação básica",
    subtitle = "Versão reponderada simula coorte do 3º EM com a composição de estratos do 5º EF.",
    x = NULL,
    y = "VPC (% da variância no nível do estrato)",
    caption = "Reponderação não recupera o VPC do 5º EF. Queda do VPC não é (substantivamente) artefato de composição."
  ) +
  tema_paper

ggsave(file.path(DIR_FIG, "F3_trajetoria_vpc.png"), p_f3, width = 8, height = 5, dpi = 300)
ggsave(file.path(DIR_FIG, "F3_trajetoria_vpc.pdf"), p_f3, width = 8, height = 5)
cat("  salvo: F3_trajetoria_vpc.{png,pdf}\n")

## ============================================================
## FIGURA 4 — Heatmap raça × INSE × sexo de proficiência média
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
  dt[, raca := raca_lbl[tx_resp_q04]]
  dt[, sexo := sexo_lbl[tx_resp_q01]]
  dt[, etapa := et]
  dt[, .(etapa, raca, sexo, inse_aluno,
         prof_lp = proficiencia_lp_saeb, prof_mt = proficiencia_mt_saeb)]
}
all_d <- rbindlist(lapply(names(arqs), carregar))
brks <- quantile(all_d$inse_aluno, c(0, 1/3, 2/3, 1), na.rm = TRUE)
all_d[, inse_tercil := cut(inse_aluno, breaks = brks, labels = c("Baixo","Médio","Alto"), include.lowest = TRUE)]
all_d[, raca := factor(raca, levels = c("Branca","Parda","Preta"))]
all_d[, sexo := factor(sexo, levels = c("Masculino","Feminino"))]
all_d[, etapa_lbl := factor(etapa_nome[etapa], levels = c("5º EF","9º EF","3º EM"))]

heat_lp <- all_d[, .(prof = mean(prof_lp), n = .N), by = .(etapa_lbl, raca, sexo, inse_tercil)]
heat_mt <- all_d[, .(prof = mean(prof_mt), n = .N), by = .(etapa_lbl, raca, sexo, inse_tercil)]
heat_lp[, disciplina := "LP"]; heat_mt[, disciplina := "MT"]
heat <- rbind(heat_lp, heat_mt)
heat[, painel := paste(etapa_lbl, "·", disciplina)]
heat[, painel := factor(painel, levels = c(
  "5º EF · LP","5º EF · MT","9º EF · LP","9º EF · MT","3º EM · LP","3º EM · MT"
))]

p_f4 <- ggplot(heat, aes(x = inse_tercil, y = raca, fill = prof)) +
  geom_tile(color = "white", linewidth = 0.4) +
  geom_text(aes(label = round(prof)), size = 2.8, color = "white", fontface = "bold") +
  scale_fill_viridis_c(option = "magma", direction = -1, name = "Proficiência\nmédia") +
  facet_grid(sexo ~ painel) +
  labs(
    title = "Figura 4. Proficiência média por posição interseccional",
    subtitle = "Raça (linhas) × tercil de INSE (colunas) × sexo (linhas externas), por etapa e disciplina.",
    x = "Tercil de INSE",
    y = "Raça/cor autodeclarada",
    caption = "SAEB 2023, n=4,8 milhões. Escala oficial SAEB 0-500."
  ) +
  tema_paper +
  theme(panel.grid.major = element_blank(),
        strip.text.x = element_text(size = 9))

ggsave(file.path(DIR_FIG, "F4_heatmap.png"), p_f4, width = 13, height = 5.5, dpi = 300)
ggsave(file.path(DIR_FIG, "F4_heatmap.pdf"), p_f4, width = 13, height = 5.5)
cat("  salvo: F4_heatmap.{png,pdf}\n")

## ============================================================
## FIGURA 5 — ROC curves do M1A vs Adequado+ para os 6 modelos
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
    cat(sprintf("  rodando M1A %s %s ...", etapa_nome[et], toupper(disc)))
    m <- lmer(as.formula(paste(col, "~ 1 + (1 | estrato)")), data = df_et, REML = TRUE)
    pred <- as.numeric(predict(m))
    y <- as.integer(df_et[[col]] >= cortes_adeq[[disc]][et])
    ## ROC com amostra para acelerar (n grande)
    set.seed(1); idx <- sample.int(length(pred), min(50000, length(pred)))
    r <- pROC::roc(y[idx], pred[idx], quiet = TRUE)
    df <- data.table(
      fpr = 1 - r$specificities, tpr = r$sensitivities,
      painel = paste(etapa_nome[et], "·", toupper(disc))
    )
    roc_long <- rbind(roc_long, df)
    auc_anota <- rbind(auc_anota, data.table(
      painel = paste(etapa_nome[et], "·", toupper(disc)),
      auc = auc_tab[modelo == paste(etapa_nome[et], toupper(disc)), AUC]
    ))
    cat(" ok\n")
  }
}
roc_long[, painel := factor(painel, levels = c(
  "5º EF · LP","5º EF · MT","9º EF · LP","9º EF · MT","3º EM · LP","3º EM · MT"
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
    title = "Figura 5. Discriminatory Accuracy: posição interseccional vs Adequado+",
    subtitle = "ROC do M1A predito contra desfecho dicotomizado em corte oficial INEP. Amostra de 50 mil por modelo.",
    x = "Falso positivo (1 - especificidade)",
    y = "Verdadeiro positivo (sensibilidade)",
    caption = "AUC modesto (0,62-0,67) indica que pertencer a um estrato interseccional condiciona, mas não determina, o resultado individual."
  ) +
  tema_paper

ggsave(file.path(DIR_FIG, "F5_roc.png"), p_f5, width = 9, height = 12, dpi = 300)
ggsave(file.path(DIR_FIG, "F5_roc.pdf"), p_f5, width = 9, height = 12)
cat("  salvo: F5_roc.{png,pdf}\n")

cat("\n=> Saídas: paper/figuras/{F1..F5}.{png,pdf}\n")
