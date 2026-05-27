## 13 — Perfil de pretas e pardas SEPARADAS no Adequado+
## Para 5º EF, 9º EF e 3º EM · LP · escolas públicas
suppressMessages({
  library(arrow); library(data.table); library(broom)
})
source(here::here("pipeline/R/00_setup.R"))

DIR_OUT <- file.path(PROJ, "pipeline/data/processed")

## cortes oficiais INEP para Adequado+ LP por etapa
CORTES <- c("5ef" = 225, "9ef" = 275, "3em" = 325)
ARQS   <- c("5ef" = "saeb_2023_5ef.parquet",
            "9ef" = "saeb_2023_9ef.parquet",
            "3em" = "saeb_2023_3em.parquet")
ETAPA_LBL <- c("5ef" = "5º EF", "9ef" = "9º EF", "3em" = "3º EM")

processa_etapa <- function(et) {
  cat(sprintf("\n========================================\n"))
  cat(sprintf("ETAPA: %s\n", ETAPA_LBL[et]))
  cat(sprintf("========================================\n"))

  dt <- as.data.table(read_parquet(file.path(DIR_PROC, ARQS[et])))
  dt <- dt[in_publica == 1 & !is.na(proficiencia_lp_saeb)]
  dt <- dt[tx_resp_q04 %in% c("A","B","C")]
  dt[, raca := fcase(
    tx_resp_q04 == "A", "Branca",
    tx_resp_q04 == "B", "Preta",
    tx_resp_q04 == "C", "Parda"
  )]
  dt[, raca := factor(raca, levels = c("Branca","Parda","Preta"))]

  cat(sprintf("N total (Branca/Parda/Preta, pública, LP não NA): %s\n",
              format(nrow(dt), big.mark = ".")))
  print(dt[, .N, by = raca])

  corte <- CORTES[et]
  dt[, alto := as.integer(proficiencia_lp_saeb >= corte)]

  cat(sprintf("\n--- %% Adequado+ (corte = %d) por raça ---\n", corte))
  out <- dt[, .(n = .N,
                pct_adequado = round(mean(alto) * 100, 1)), by = raca]
  print(out)

  ## preparar covariadas
  escol_map <- c(A=1, B=2, C=3, D=4, E=5, F=6)
  dt[, escol_mae := escol_map[tx_resp_q08]]
  dt[, sexo := fcase(tx_resp_q01 == "A", "Masculino", tx_resp_q01 == "B", "Feminino")]
  dt[, trab_dom := fcase(tx_resp_q21c == "A", "Nenhum",
                         tx_resp_q21c == "B", "Menos 1h",
                         tx_resp_q21c == "C", "1-2h",
                         tx_resp_q21c == "D", "Mais 2h")]
  dt[, trab_dom := factor(trab_dom, levels = c("Nenhum","Menos 1h","1-2h","Mais 2h"))]
  dt[, reprov := fcase(tx_resp_q19 == "A", "Nunca",
                       tx_resp_q19 == "B", "Uma vez",
                       tx_resp_q19 == "C", "Duas+")]
  dt[, reprov := factor(reprov, levels = c("Nunca","Uma vez","Duas+"))]
  dt[, regiao := fcase(id_regiao == 1, "Norte",
                       id_regiao == 2, "Nordeste",
                       id_regiao == 3, "Sudeste",
                       id_regiao == 4, "Sul",
                       id_regiao == 5, "Centro-Oeste")]
  dt[, regiao := factor(regiao, levels = c("Norte","Nordeste","Centro-Oeste","Sudeste","Sul"))]

  ## taxa Adequado+ por atributo, SEPARANDO Parda de Preta
  taxa_por <- function(var, racas_alvo) {
    dt[raca %in% racas_alvo & !is.na(get(var)),
       .(pct_adequado = round(mean(alto)*100, 1), n = .N),
       by = c("raca", var)]
  }

  cat("\n--- Taxa Adequado+ por escolaridade da MÃE (Parda vs Preta) ---\n")
  print(dcast(taxa_por("escol_mae", c("Parda","Preta")),
              escol_mae ~ raca, value.var = "pct_adequado", fill = NA)[order(escol_mae)])

  cat("\n--- Taxa Adequado+ por reprovação ---\n")
  print(dcast(taxa_por("reprov", c("Parda","Preta")),
              reprov ~ raca, value.var = "pct_adequado", fill = NA))

  cat("\n--- Taxa Adequado+ por sexo ---\n")
  print(dcast(taxa_por("sexo", c("Parda","Preta")),
              sexo ~ raca, value.var = "pct_adequado", fill = NA))

  cat("\n--- Taxa Adequado+ por trabalho doméstico ---\n")
  print(dcast(taxa_por("trab_dom", c("Parda","Preta")),
              trab_dom ~ raca, value.var = "pct_adequado", fill = NA))

  cat("\n--- Taxa Adequado+ por região ---\n")
  print(dcast(taxa_por("regiao", c("Parda","Preta")),
              regiao ~ raca, value.var = "pct_adequado", fill = NA))

  ## modelo logístico: P(Adequado+) ~ covariadas, INTERAGINDO com raça (parda vs preta)
  ## Para simplicidade, rodamos um modelo só com pretas+pardas e raça como variável
  cat("\n--- MODELO LOGÍSTICO: P(Adequado+) entre Pardas+Pretas, com raça como preditor ---\n")
  mod_dt <- dt[raca %in% c("Parda","Preta") &
               !is.na(inse_aluno) & !is.na(escol_mae) & !is.na(sexo) &
               !is.na(trab_dom) & !is.na(reprov) & !is.na(regiao)]
  mod_dt[, raca := droplevels(raca)]
  cat(sprintf("N modelo: %s\n", format(nrow(mod_dt), big.mark=".")))

  mod <- glm(alto ~ raca + inse_aluno + escol_mae + sexo + trab_dom + reprov + regiao,
             data = mod_dt, family = binomial())
  res <- broom::tidy(mod, exponentiate = TRUE, conf.int = TRUE)
  setDT(res)
  res[, sig := fcase(p.value < 0.001, "***",
                     p.value < 0.01,  "**",
                     p.value < 0.05,  "*",
                     default = "")]
  res[, etapa := ETAPA_LBL[et]]
  res[, `:=`(estimate = round(estimate, 3),
             conf.low = round(conf.low, 3),
             conf.high = round(conf.high, 3))]
  print(res[, .(term, OR = estimate, ci_lo = conf.low, ci_hi = conf.high, sig)])
  res
}

todos <- rbindlist(lapply(names(ARQS), processa_etapa), fill = TRUE)
fwrite(todos, file.path(DIR_OUT, "expl_perfil_3racas_3etapas_logistic.csv"))
cat("\n\n=> saída: pipeline/data/processed/expl_perfil_3racas_3etapas_logistic.csv\n")
