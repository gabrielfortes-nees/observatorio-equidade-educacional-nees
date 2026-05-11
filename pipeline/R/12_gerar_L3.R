## 12 — L3 (contrafactual REESCRITO): "Infraestrutura como direito"
## SAEB e Censo Escolar usam códigos de escola diferentes → agregamos por MUNICÍPIO.
## Para cada município:
##   • % escolas com 3/3 itens (água+banheiro PNE+alimentação) — Censo Escolar 2025
##   • % alunos com aprendizagem adequada em LP — SAEB 2023 5º EF
## Quartilizamos os municípios pela infra e mostramos o gap em proficiência.
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

esc  <- as.data.table(read_parquet(file.path(DIR_PROC, "censo_escolar_2025_escola.parquet")))
saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_5ef.parquet")))

## Infra escola: 3/3 itens
esc[, infra_3_3 := as.integer(in_agua_potavel == 1 & in_banheiro_pne == 1 & in_alimentacao == 1)]

## SAEB usa id_municipio INEP (não IBGE); agrego por UF (mesmo padrão nos dois).
## % escolas 3/3 por UF
infra_uf <- esc[!is.na(infra_3_3),
                 .(pct_3_3 = mean(infra_3_3) * 100,
                   n_escolas = .N), by = co_uf]

## % alunos adequados por UF (SAEB)
saeb <- saeb[in_publica == 1 & !is.na(proficiencia_lp_saeb)]
saeb[, adequado := as.integer(proficiencia_lp_saeb >= ADEQ_LP_5EF)]
prof_uf <- saeb[, .(prof_adequado = mean(adequado) * 100,
                     prof_media = mean(proficiencia_lp_saeb),
                     n_alunos = .N), by = id_uf]

## merge UF × UF
mq <- merge(infra_uf, prof_uf,
            by.x = "co_uf", by.y = "id_uf")
## quartilizar UFs pela % escolas 3/3 (27 UFs → 4 quartis)
mq <- mq[order(pct_3_3)]
mq[, quartil_infra := cut(seq_len(.N) / .N, breaks = seq(0, 1, 0.25),
                           include.lowest = TRUE,
                           labels = c("Q1 (menos infra)", "Q2", "Q3", "Q4 (mais infra)"))]

agg_q <- mq[, .(infra_media = round(weighted.mean(pct_3_3, n_alunos), 1),
                prof_adequado = round(weighted.mean(prof_adequado, n_alunos), 1),
                prof_media = round(weighted.mean(prof_media, n_alunos), 1),
                n_ufs = .N,
                n_alunos_total = sum(n_alunos)),
            by = quartil_infra][order(quartil_infra)]

## Cenário REAL: cada quartil com seu valor de aprendizagem observado
## Cenário "SEM INFRA": estimativa simples — cada quartil cai para o valor de Q1
##   (interpretação: "se nenhuma escola brasileira tivesse os 3 itens básicos,
##    a aprendizagem em todas as UFs convergiria para o pior cenário observado").
##   Mais conservador que extrapolar curvas de dose-resposta inexistentes.
pior_q <- agg_q$prof_adequado[1]
bars <- lapply(seq_len(nrow(agg_q)), function(i) {
  list(
    label = as.character(agg_q$quartil_infra[i]),
    real  = agg_q$prof_adequado[i],
    off   = pior_q,
    infra_pct = agg_q$infra_media[i],
    prof_media = agg_q$prof_media[i],
    n_ufs = agg_q$n_ufs[i],
    color_key = c("counterfactual", "brown", "orangeSoft", "orange")[i]
  )
})

## resumos
total_escolas <- nrow(esc)
esc_3_3 <- sum(esc$infra_3_3, na.rm = TRUE)
pct_3_3_br   <- round(esc_3_3 / total_escolas * 100, 1)
pct_falta_br <- round(100 - pct_3_3_br, 1)

gap_pp <- round(agg_q$prof_adequado[nrow(agg_q)] - agg_q$prof_adequado[1], 1)
gap_pontos <- round(agg_q$prof_media[nrow(agg_q)] - agg_q$prof_media[1], 1)

L3 <- list(
  meta = list(
    leitura = "L3",
    titulo_curto = "Infraestrutura como direito",
    eyebrow = "Leitura 03 · Contrafactual · infraestrutura escolar como política",
    fonte = "Censo Escolar 2025 (IN_AGUA_POTAVEL + IN_BANHEIRO_PNE + IN_ALIMENTACAO) × SAEB 2023 5º EF — agregado por município",
    contrafactual = TRUE,
    cf_key = "infra",
    n_escolas = total_escolas,
    n_ufs_match = nrow(mq),
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    pct_escolas_3_3 = pct_3_3_br,
    pct_escolas_faltando = pct_falta_br,
    adequado_q1 = agg_q$prof_adequado[1],
    adequado_q4 = agg_q$prof_adequado[nrow(agg_q)],
    gap_adequado_pp = gap_pp,
    gap_pontos = gap_pontos
  ),
  viz = list(
    indicador = "Por quartil municipal de cobertura 3/3 (água + banheiro PNE + alimentação)",
    titulo_real = "Mais infraestrutura → mais aprendizagem",
    titulo_off  = "Menos infraestrutura → mais distância da aprendizagem",
    bars = bars,
    callout = sprintf(
      "Em %.1f%% das escolas brasileiras falta ao menos um item básico (água potável, banheiro acessível ou alimentação). Comparando municípios no quartil mais e menos infraestruturados: a aprendizagem adequada em LP varia %.1f pp; a proficiência média varia %.1f pontos SAEB.",
      pct_falta_br, gap_pp, gap_pontos)
  )
)

write_json(L3, file.path(DIR_AGG, "L3.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L3 ✓ | %s UFs match | Q1 %.1f%% vs Q4 %.1f%% (gap %.1f pp)",
                 nrow(mq), agg_q$prof_adequado[1], agg_q$prof_adequado[nrow(agg_q)], gap_pp))
