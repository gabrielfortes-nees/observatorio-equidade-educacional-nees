## 12 — Funnel plot + positive deviants das escolas (SAEB 5EF · LP · pública)
## Pergunta 1: quais escolas fogem do padrão (gap intra > 2σ ou < -2σ)?
## Pergunta 2: o que têm em comum as escolas onde negros >= brancos?
suppressMessages({
  library(arrow); library(data.table); library(ggplot2)
})
source(here::here("pipeline/R/00_setup.R"))

DIR_OUT <- file.path(PROJ, "pipeline/data/processed")
DIR_FIG_EXPL <- file.path(PROJ, "pipeline/data/processed/expl_figuras")
dir.create(DIR_FIG_EXPL, showWarnings = FALSE, recursive = TRUE)

MIN_GRP <- 10

## ---------- preparar amostra (idêntica L2) ----------
dt <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_5ef.parquet")))
dt <- dt[in_publica == 1 & !is.na(proficiencia_lp_saeb)]
dt <- dt[tx_resp_q04 %in% c("A","B","C","D","E")]
dt[, raca := fcase(
  tx_resp_q04 %in% c("A","D"), "branca_amarela",
  tx_resp_q04 %in% c("B","C"), "preta_parda",
  tx_resp_q04 == "E",          "indigena"
)]
dt <- dt[raca %in% c("branca_amarela","preta_parda")]

## região + INSE médio + tamanho da escola
por_escola <- dt[, .(
  prof_br = mean(proficiencia_lp_saeb[raca == "branca_amarela"]),
  prof_pp = mean(proficiencia_lp_saeb[raca == "preta_parda"]),
  n_br    = sum(raca == "branca_amarela"),
  n_pp    = sum(raca == "preta_parda"),
  inse_med = mean(inse_aluno, na.rm = TRUE),
  id_regiao = first(id_regiao),
  id_uf     = first(id_uf),
  id_localizacao = first(id_localizacao)
), by = id_escola]

mistas <- por_escola[n_br >= MIN_GRP & n_pp >= MIN_GRP]
mistas[, gap := prof_br - prof_pp]
mistas[, n_total := n_br + n_pp]
mistas[, regiao := fcase(id_regiao == 1, "Norte",
                         id_regiao == 2, "Nordeste",
                         id_regiao == 3, "Sudeste",
                         id_regiao == 4, "Sul",
                         id_regiao == 5, "Centro-Oeste")]
mistas[, regiao := factor(regiao, levels = c("Norte","Nordeste","Centro-Oeste","Sudeste","Sul"))]
mistas[, localizacao := fcase(id_localizacao == 1, "Urbana",
                              id_localizacao == 2, "Rural")]

## ---------- enriquecer com infra do Censo Escolar 2025 ----------
ce <- tryCatch(
  as.data.table(read_parquet(file.path(DIR_PROC, "censo_escolar_2025_escola.parquet")))[,
    .(id_escola = co_entidade, in_alimentacao, in_banheiro_pne, in_agua_potavel)
  ],
  error = function(e) NULL
)
if (!is.null(ce)) {
  mistas <- merge(mistas, ce, by = "id_escola", all.x = TRUE)
  cat(sprintf("Infra Censo Escolar 2025 mergeada: %.1f%% das mistas têm match\n",
              mean(!is.na(mistas$in_alimentacao)) * 100))
} else {
  mistas[, `:=`(in_alimentacao = NA_integer_, in_banheiro_pne = NA_integer_,
                in_agua_potavel = NA_integer_)]
  cat("Sem dados de infra disponíveis.\n")
}

cat(sprintf("Escolas mistas analisadas: %s\n", format(nrow(mistas), big.mark=".")))

## ---------- FUNNEL PLOT: gap vs N ----------
## média global do gap (ponderada pelo n_total)
gap_medio <- mistas[, weighted.mean(gap, n_total)]
## SE esperado em função de N — assumindo variância populacional
## var(gap) ≈ (sigma^2 / n_br) + (sigma^2 / n_pp); aproximamos com sigma da L2
sigma <- 50  ## sd típico de proficiência SAEB ≈ 50
mistas[, se_esperado := sqrt(sigma^2/n_br + sigma^2/n_pp)]
mistas[, z := (gap - gap_medio) / se_esperado]
mistas[, outlier_pos := z >  2]  ## escolas com gap MUITO maior (pró-branco extremo)
mistas[, outlier_neg := z < -2]  ## escolas com gap MUITO menor (ou pró-negro)

cat(sprintf("\nGap médio ponderado: %.2f\n", gap_medio))
cat(sprintf("Outliers gap pró-branco (z>+2): %d (%.1f%%)\n",
            sum(mistas$outlier_pos), mean(mistas$outlier_pos)*100))
cat(sprintf("Outliers gap baixo ou negativo (z<-2): %d (%.1f%%)\n",
            sum(mistas$outlier_neg), mean(mistas$outlier_neg)*100))

## funnel plot
n_grid <- seq(MIN_GRP*2, max(mistas$n_total), length.out = 200)
banda <- data.table(n_total = n_grid,
                    se_ref  = sqrt(sigma^2/(n_grid/2) + sigma^2/(n_grid/2)))
banda[, `:=`(banda_2s_lo = gap_medio - 2*se_ref,
             banda_2s_hi = gap_medio + 2*se_ref,
             banda_3s_lo = gap_medio - 3*se_ref,
             banda_3s_hi = gap_medio + 3*se_ref)]

p_funnel <- ggplot(mistas, aes(x = n_total, y = gap)) +
  geom_ribbon(data = banda, aes(x = n_total, ymin = banda_3s_lo, ymax = banda_3s_hi),
              fill = "grey90", alpha = 0.6, inherit.aes = FALSE) +
  geom_ribbon(data = banda, aes(x = n_total, ymin = banda_2s_lo, ymax = banda_2s_hi),
              fill = "grey75", alpha = 0.6, inherit.aes = FALSE) +
  geom_hline(yintercept = gap_medio, linetype = "dashed", color = "grey40") +
  geom_hline(yintercept = 0, color = "black", linewidth = 0.3) +
  geom_point(aes(color = z > 2 | z < -2),
             alpha = 0.4, size = 0.7) +
  scale_color_manual(values = c(`FALSE` = "grey50", `TRUE` = "#D35400"),
                     name = "Outlier (|z| > 2)") +
  scale_x_log10() +
  labs(
    title = "Funnel plot: gap racial intra-escola vs tamanho da escola",
    subtitle = sprintf("Cinza claro = banda 3σ · cinza escuro = banda 2σ · linha pontilhada = gap médio (%.2f)",
                       gap_medio),
    x = "N total (brancos+amarelos + pretos+pardos) — escala log",
    y = "Gap intra-escola (brancos − pretos+pardos)",
    caption = sprintf("SAEB 2023 · 5º EF · LP · %s escolas mistas. Pontos abaixo da banda inferior = escolas onde pretos+pardos performam acima do esperado.",
                      format(nrow(mistas), big.mark="."))
  ) +
  theme_minimal(base_size = 11) +
  theme(panel.grid.minor = element_blank())

ggsave(file.path(DIR_FIG_EXPL, "funnel_gap_intra.png"), p_funnel,
       width = 10, height = 6, dpi = 200)
cat("\n=> figura: pipeline/data/processed/expl_figuras/funnel_gap_intra.png\n")

## ---------- POSITIVE DEVIANTS: gap <= 0 ----------
## Vamos chamar de "positive deviants" as escolas onde gap <= 0
## (pretos+pardos performam ≥ brancos, ignorando ruído estatístico)
mistas[, deviant := gap <= 0]
mistas[, group := fcase(
  deviant, "Positive deviant (gap≤0)",
  z > 2,   "Gap muito maior que esperado (z>+2)",
  default = "Padrão (gap > 0)"
)]

n_deviant <- sum(mistas$deviant)
cat(sprintf("\n========== POSITIVE DEVIANTS ==========\n"))
cat(sprintf("Escolas onde pretos+pardos performam >= brancos: %d (%.1f%% das mistas)\n",
            n_deviant, mean(mistas$deviant)*100))

## comparar deviants vs resto
cat("\n--- Distribuição por REGIÃO (% dentro do grupo) ---\n")
out <- mistas[, .N, by = .(group, regiao)]
out[, pct := N/sum(N)*100, by = group]
print(dcast(out, regiao ~ group, value.var = "pct", fill = 0)[, lapply(.SD, function(x) if (is.numeric(x)) round(x,1) else x)])

cat("\n--- Localização (% dentro do grupo) ---\n")
out <- mistas[!is.na(localizacao), .N, by = .(group, localizacao)]
out[, pct := N/sum(N)*100, by = group]
print(dcast(out, localizacao ~ group, value.var = "pct", fill = 0)[, lapply(.SD, function(x) if (is.numeric(x)) round(x,1) else x)])

cat("\n--- INSE médio (mean por grupo) ---\n")
print(mistas[, .(inse_medio = round(mean(inse_med, na.rm=TRUE), 2),
                 inse_p25  = round(quantile(inse_med, 0.25, na.rm=TRUE), 2),
                 inse_p75  = round(quantile(inse_med, 0.75, na.rm=TRUE), 2),
                 n_escolas = .N), by = group])

cat("\n--- Tamanho da escola (n_total, mean) ---\n")
print(mistas[, .(n_total_medio = round(mean(n_total), 1),
                 n_total_mediana = median(n_total)), by = group])

cat("\n--- Infraestrutura (% com cada item) ---\n")
out <- mistas[!is.na(in_alimentacao), .(
  pct_alimentacao  = round(mean(in_alimentacao == 1) * 100, 1),
  pct_banheiro_pne = round(mean(in_banheiro_pne == 1, na.rm=TRUE) * 100, 1),
  pct_agua_potavel = round(mean(in_agua_potavel == 1, na.rm=TRUE) * 100, 1),
  n = .N
), by = group]
print(out)

## ---------- salvar ----------
fwrite(mistas[, .(id_escola, regiao, localizacao, inse_med, n_total, gap, z,
                  deviant, group, in_alimentacao, in_banheiro_pne, in_agua_potavel)],
       file.path(DIR_OUT, "expl_funnel_deviants_escolas.csv"))
cat("\n=> saída: pipeline/data/processed/expl_funnel_deviants_escolas.csv\n")
