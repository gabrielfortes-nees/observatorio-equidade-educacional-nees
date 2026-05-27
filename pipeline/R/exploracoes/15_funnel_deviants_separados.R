## 15 — Funnel + positive deviants, SEPARANDO pretos e pardos
## Contrastes: parda vs branca · preta vs branca
## Etapas: 5º EF, 9º EF, 3º EM · disciplina: LP · pública
suppressMessages({
  library(arrow); library(data.table); library(ggplot2)
})
source(here::here("pipeline/R/00_setup.R"))

DIR_OUT <- file.path(PROJ, "pipeline/data/processed")
DIR_FIG_EXPL <- file.path(PROJ, "pipeline/data/processed/expl_figuras")
dir.create(DIR_FIG_EXPL, showWarnings = FALSE, recursive = TRUE)

ARQS <- c("5ef" = "saeb_2023_5ef.parquet",
          "9ef" = "saeb_2023_9ef.parquet",
          "3em" = "saeb_2023_3em.parquet")
ETAPA_LBL <- c("5ef" = "5º EF", "9ef" = "9º EF", "3em" = "3º EM")
MIN_GRP <- 10

processa <- function(et) {
  cat(sprintf("\n=== %s ===\n", ETAPA_LBL[et]))

  dt <- as.data.table(read_parquet(file.path(DIR_PROC, ARQS[et])))
  dt <- dt[in_publica == 1 & !is.na(proficiencia_lp_saeb)]
  dt <- dt[tx_resp_q04 %in% c("A","B","C")]
  dt[, raca := fcase(
    tx_resp_q04 == "A", "Branca",
    tx_resp_q04 == "B", "Preta",
    tx_resp_q04 == "C", "Parda"
  )]

  rodar_contraste <- function(raca_b) {
    sub <- dt[raca %in% c("Branca", raca_b)]
    por_escola <- sub[, .(
      prof_br = mean(proficiencia_lp_saeb[raca == "Branca"]),
      prof_tg = mean(proficiencia_lp_saeb[raca == raca_b]),
      n_br = sum(raca == "Branca"),
      n_tg = sum(raca == raca_b),
      inse_med = mean(inse_aluno, na.rm = TRUE),
      id_regiao = first(id_regiao),
      id_localizacao = first(id_localizacao)
    ), by = id_escola]
    mistas <- por_escola[n_br >= MIN_GRP & n_tg >= MIN_GRP]
    mistas[, gap := prof_br - prof_tg]
    mistas[, n_total := n_br + n_tg]
    mistas[, prof_escola_med := (prof_br + prof_tg) / 2]
    mistas[, regiao := fcase(id_regiao == 1, "Norte",
                             id_regiao == 2, "Nordeste",
                             id_regiao == 3, "Sudeste",
                             id_regiao == 4, "Sul",
                             id_regiao == 5, "Centro-Oeste")]
    mistas[, regiao := factor(regiao, levels = c("Norte","Nordeste","Centro-Oeste","Sudeste","Sul"))]
    mistas[, localizacao := fcase(id_localizacao == 1, "Urbana",
                                  id_localizacao == 2, "Rural")]

    if (nrow(mistas) < 100) {
      cat(sprintf("  [skip %s] escolas mistas: %d\n", raca_b, nrow(mistas)))
      return(NULL)
    }

    ## funnel
    gap_med <- mistas[, weighted.mean(gap, n_total)]
    sigma <- 50
    mistas[, se_esp := sqrt(sigma^2/n_br + sigma^2/n_tg)]
    mistas[, z := (gap - gap_med) / se_esp]
    mistas[, deviant := gap <= 0]

    cat(sprintf("  Branca vs %s · escolas mistas: %s · gap médio: %.2f · deviants (gap<=0): %d (%.1f%%)\n",
                raca_b, format(nrow(mistas), big.mark="."),
                gap_med, sum(mistas$deviant), mean(mistas$deviant)*100))

    ## sumarizar deviants vs padrão
    mistas[, grupo := fcase(deviant, "Deviant (gap<=0)",
                            z > 2,   "Outlier pró-Branca (z>+2)",
                            default = "Padrão (gap>0)")]

    res_regiao <- mistas[, .N, by = .(grupo, regiao)][order(grupo, regiao)]
    res_regiao[, pct := round(N/sum(N)*100, 1), by = grupo]
    res_regiao_w <- dcast(res_regiao, regiao ~ grupo, value.var = "pct", fill = 0)

    res_resumo <- mistas[, .(
      n_escolas = .N,
      inse_medio = round(mean(inse_med, na.rm=TRUE), 2),
      prof_escola_med = round(mean(prof_escola_med, na.rm=TRUE), 1),  ## NOVO: distinguir virtuoso de colapso
      n_total_med = round(mean(n_total), 0),
      pct_rural = round(mean(localizacao == "Rural", na.rm=TRUE) * 100, 1)
    ), by = grupo]

    cat("\n  --- por grupo ---\n")
    print(res_resumo)

    cat("\n  --- distribuição regional (% dentro do grupo) ---\n")
    print(res_regiao_w)

    mistas[, contraste := paste0(raca_b, "_vs_Branca")]
    mistas[, etapa := ETAPA_LBL[et]]
    mistas[, gap_med_grupo := gap_med]
    mistas[, .(id_escola, etapa, contraste, regiao, localizacao,
               inse_med, prof_escola_med, n_total, gap, z, deviant, grupo)]
  }

  rbindlist(lapply(c("Parda","Preta"), rodar_contraste))
}

todos <- rbindlist(lapply(names(ARQS), processa))
fwrite(todos, file.path(DIR_OUT, "expl_funnel_deviants_separados.csv"))

## ---- resumo final consolidado ----
cat("\n\n========================= RESUMO GERAL =========================\n")
resumo <- todos[, .(
  n_escolas = .N,
  pct_deviants = round(mean(deviant) * 100, 1),
  gap_medio_ponderado = round(weighted.mean(gap, n_total), 2)
), by = .(etapa, contraste)]
print(resumo)

cat("\n--- positive deviants: virtuosos (prof alta) vs colapso (prof baixa)? ---\n")
diag <- todos[deviant == TRUE, .(
  n = .N,
  prof_escola_media = round(mean(prof_escola_med, na.rm=TRUE), 1),
  inse_medio = round(mean(inse_med, na.rm=TRUE), 2)
), by = .(etapa, contraste)]
print(diag)

cat("\n=> saída: pipeline/data/processed/expl_funnel_deviants_separados.csv\n")
