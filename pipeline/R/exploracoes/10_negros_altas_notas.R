## 10 — Perfil de estudantes pretos+pardos com altas notas (SAEB 5EF · LP)
## Pergunta: quem são os pretos+pardos que atingem Adequado+ ou estão no P90 nacional?
## Quais variáveis os distinguem dos que ficam abaixo?
suppressMessages({
  library(arrow); library(data.table); library(broom)
})
source(here::here("pipeline/R/00_setup.R"))

DIR_OUT <- file.path(PROJ, "pipeline/data/processed")

ADEQ_5EF_LP <- 225  ## corte oficial INEP

## ---------- preparar amostra ----------
dt <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_5ef.parquet")))
dt <- dt[in_publica == 1 & !is.na(proficiencia_lp_saeb)]
dt <- dt[tx_resp_q04 %in% c("A","B","C","D","E")]
dt[, raca := fcase(
  tx_resp_q04 %in% c("A","D"), "branca_amarela",
  tx_resp_q04 %in% c("B","C"), "preta_parda",
  tx_resp_q04 == "E",          "indigena"
)]

## foco: pretos + pardos
pp <- dt[raca == "preta_parda"]
n_total <- nrow(pp)
cat(sprintf("N pretos+pardos no SAEB 5EF público com LP: %s\n", format(n_total, big.mark = ".")))

## limiares para "alta nota"
p90_nacional <- quantile(dt$proficiencia_lp_saeb, 0.90, na.rm = TRUE)
cat(sprintf("Cortes: Adequado+ = %d · P90 nacional = %.1f\n\n",
            ADEQ_5EF_LP, p90_nacional))

pp[, alto_adequado := as.integer(proficiencia_lp_saeb >= ADEQ_5EF_LP)]
pp[, alto_p90      := as.integer(proficiencia_lp_saeb >= p90_nacional)]

cat(sprintf("Pretos+pardos no Adequado+: %s (%.1f%%)\n",
            format(sum(pp$alto_adequado), big.mark="."),
            mean(pp$alto_adequado) * 100))
cat(sprintf("Pretos+pardos no P90 nacional: %s (%.1f%%)\n\n",
            format(sum(pp$alto_p90), big.mark="."),
            mean(pp$alto_p90) * 100))

## ---------- preparar covariadas ----------
## escolaridade dos pais (Q08 mãe, Q09 pai): ordinal 1-6 (A-F)
escol_map <- c(A=1, B=2, C=3, D=4, E=5, F=6)
escol_lbl <- c("Nunca estudou","EF incompleto","EF completo","EM incompleto","EM completo","Superior+")
pp[, escol_mae := escol_map[tx_resp_q08]]
pp[, escol_pai := escol_map[tx_resp_q09]]
pp[, escol_mae_lbl := factor(escol_lbl[escol_mae], levels = escol_lbl)]

## sexo
pp[, sexo := fcase(tx_resp_q01 == "A", "Masculino",
                   tx_resp_q01 == "B", "Feminino")]

## trabalho doméstico (Q21c): A=nenhum, B=<1h, C=1-2h, D=>2h
pp[, trab_dom := fcase(tx_resp_q21c == "A", "Nenhum",
                       tx_resp_q21c == "B", "Menos 1h",
                       tx_resp_q21c == "C", "1-2h",
                       tx_resp_q21c == "D", "Mais 2h")]
pp[, trab_dom := factor(trab_dom, levels = c("Nenhum","Menos 1h","1-2h","Mais 2h"))]

## reprovação (Q19): A=não, B=1x, C=2+
pp[, reprov := fcase(tx_resp_q19 == "A", "Nunca",
                     tx_resp_q19 == "B", "Uma vez",
                     tx_resp_q19 == "C", "Duas+")]
pp[, reprov := factor(reprov, levels = c("Nunca","Uma vez","Duas+"))]

## região
pp[, regiao := fcase(id_regiao == 1, "Norte",
                     id_regiao == 2, "Nordeste",
                     id_regiao == 3, "Sudeste",
                     id_regiao == 4, "Sul",
                     id_regiao == 5, "Centro-Oeste")]
pp[, regiao := factor(regiao, levels = c("Norte","Nordeste","Centro-Oeste","Sudeste","Sul"))]

## INSE em tercis (cortes da amostra geral, não só pretos+pardos)
brks_inse <- quantile(dt$inse_aluno, c(0, 1/3, 2/3, 1), na.rm = TRUE)
pp[, inse_tercil := cut(inse_aluno, breaks = brks_inse,
                         labels = c("Baixo","Médio","Alto"), include.lowest = TRUE)]

## ---------- TABELA COMPARATIVA: alto vs baixo (Adequado+) ----------
cat("\n========== PERFIL: pretos+pardos no Adequado+ vs abaixo ==========\n\n")

prof_pct <- function(g, var) {
  tab <- pp[!is.na(get(var)), .N, by = c("alto_adequado", var)][order(get(var))]
  tab[, pct := N/sum(N)*100, by = alto_adequado]
  dcast(tab, get(var) ~ alto_adequado, value.var = "pct", fill = 0)
}

cat("\n--- INSE tercil (% dentro do grupo) ---\n")
out <- prof_pct(pp, "inse_tercil")
setnames(out, c("INSE tercil","Abaixo (%)","Adequado+ (%)"))
print(out[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 1) else x)])

cat("\n--- Escolaridade da MÃE (% dentro do grupo) ---\n")
out <- prof_pct(pp, "escol_mae_lbl")
setnames(out, c("Escolaridade Mãe","Abaixo (%)","Adequado+ (%)"))
print(out[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 1) else x)])

cat("\n--- Sexo ---\n")
out <- prof_pct(pp, "sexo"); setnames(out, c("Sexo","Abaixo","Adequado+"))
print(out[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 1) else x)])

cat("\n--- Trabalho doméstico ---\n")
out <- prof_pct(pp, "trab_dom"); setnames(out, c("Trab. doméstico","Abaixo","Adequado+"))
print(out[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 1) else x)])

cat("\n--- Reprovação ---\n")
out <- prof_pct(pp, "reprov"); setnames(out, c("Reprovou?","Abaixo","Adequado+"))
print(out[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 1) else x)])

cat("\n--- Região ---\n")
out <- prof_pct(pp, "regiao"); setnames(out, c("Região","Abaixo","Adequado+"))
print(out[, lapply(.SD, function(x) if (is.numeric(x)) round(x, 1) else x)])

## ---------- TAXA DE Adequado+ POR ATRIBUTO ----------
cat("\n\n========== TAXA DE Adequado+ DENTRO DE CADA CATEGORIA ==========\n")
cat("(% de pretos+pardos que atingem Adequado+, separado por atributo)\n\n")

taxa <- function(var) {
  pp[!is.na(get(var)), .(pct_adequado = round(mean(alto_adequado)*100, 1),
                          n = .N),
     by = c(var)][order(-pct_adequado)]
}

cat("--- por escolaridade da MÃE ---\n"); print(taxa("escol_mae_lbl"))
cat("\n--- por INSE tercil ---\n");        print(taxa("inse_tercil"))
cat("\n--- por região ---\n");              print(taxa("regiao"))
cat("\n--- por sexo ---\n");                print(taxa("sexo"))
cat("\n--- por reprovação ---\n");          print(taxa("reprov"))
cat("\n--- por trabalho doméstico ---\n");  print(taxa("trab_dom"))

## ---------- MODELO LOGÍSTICO: o que prevê Adequado+ entre pretos+pardos? ----------
cat("\n\n========== MODELO LOGÍSTICO ==========\n")
cat("Outcome: pretos+pardos atingiram Adequado+ (sim/não)\n")
cat("Covariadas: INSE contínuo, escolaridade mãe (ordinal), sexo, trab. doméstico, reprovação, região\n\n")

mod_dt <- pp[!is.na(inse_aluno) & !is.na(escol_mae) & !is.na(sexo) &
             !is.na(trab_dom) & !is.na(reprov) & !is.na(regiao)]
cat(sprintf("N modelo: %s · taxa Adequado+ na subamostra: %.1f%%\n\n",
            format(nrow(mod_dt), big.mark="."),
            mean(mod_dt$alto_adequado) * 100))

mod <- glm(alto_adequado ~ inse_aluno + escol_mae + sexo + trab_dom + reprov + regiao,
           data = mod_dt, family = binomial())
res <- broom::tidy(mod, exponentiate = TRUE, conf.int = TRUE)
setDT(res)
res[, sig := fcase(p.value < 0.001, "***",
                   p.value < 0.01,  "**",
                   p.value < 0.05,  "*",
                   default = "")]
res[, `:=`(estimate = round(estimate, 3),
           conf.low = round(conf.low, 3),
           conf.high = round(conf.high, 3))]
print(res[, .(term, OR = estimate, ci_lo = conf.low, ci_hi = conf.high, p = round(p.value, 4), sig)])

## ---------- guardar ----------
fwrite(res, file.path(DIR_OUT, "expl_pp_altas_notas_logistic.csv"))
saveRDS(list(
  n_total = n_total,
  n_adequado = sum(pp$alto_adequado),
  pct_adequado = mean(pp$alto_adequado) * 100,
  n_p90 = sum(pp$alto_p90),
  pct_p90 = mean(pp$alto_p90) * 100,
  modelo = mod,
  amostra_modelo = mod_dt[, .(alto_adequado, inse_aluno, escol_mae_lbl, sexo, trab_dom, reprov, regiao)]
), file.path(DIR_OUT, "expl_pp_altas_notas.rds"))

cat("\n=> saídas:\n")
cat("   pipeline/data/processed/expl_pp_altas_notas_logistic.csv\n")
cat("   pipeline/data/processed/expl_pp_altas_notas.rds\n")
