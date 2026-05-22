## 13 — L4: cobertura de creche × proficiência LP 5º EF, agregado por UF
##   • Censo Escolar 2025 (QT_MAT_INF_CRE × CO_UF) → matrículas creche por UF
##   • SIDRA pop 0-3 (município → UF via sufixo do nome)
##   • SAEB 2023 5EF (% adequado por id_uf)
## SAEB e Censo Escolar usam códigos de município diferentes → unidade comum: UF
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

esc <- as.data.table(read_parquet(file.path(DIR_PROC, "censo_escolar_2025_escola.parquet")))
mat <- as.data.table(read_parquet(file.path(DIR_PROC, "censo_escolar_2025_matricula.parquet")))
pop <- as.data.table(read_parquet(file.path(DIR_PROC, "sidra_pop_0_3_municipios_2022.parquet")))
saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_5ef.parquet")))

## ---------- matrículas creche por UF (Censo Escolar 2025) ----------
em <- merge(mat[, .(co_entidade, qt_mat_inf_cre)],
            esc[, .(co_entidade, co_uf, sg_uf)], by = "co_entidade")
cre_uf <- em[, .(mat_creche = sum(qt_mat_inf_cre, na.rm = TRUE)), by = .(co_uf, sg_uf)]

## ---------- pop 0-3 por UF (SIDRA municípios → soma por UF via sufixo) ----------
pop[, sg_uf := sub(".*- ", "", municipio_uf)]
pop_uf <- pop[, .(pop_0_3 = sum(pop_0_3, na.rm = TRUE)), by = sg_uf]

## ---------- merge cobertura ----------
cob_uf <- merge(cre_uf, pop_uf, by = "sg_uf")
cob_uf[, cobertura := pmin(100, mat_creche / pop_0_3 * 100)]

## ---------- SAEB 5EF % adequado por UF ----------
saeb <- saeb[in_publica == 1 & !is.na(proficiencia_lp_saeb)]
saeb[, adequado := as.integer(proficiencia_lp_saeb >= ADEQ_LP_5EF)]
saeb_uf <- saeb[, .(adequado_pct = mean(adequado) * 100, n_alunos = .N), by = id_uf]

## ---------- merge tudo por UF ----------
uf_full <- merge(cob_uf, saeb_uf, by.x = "co_uf", by.y = "id_uf")
uf_full <- uf_full[order(cobertura)]

## quintilizar UFs (27 → 5 grupos)
uf_full[, quintil := cut(seq_len(.N) / .N, breaks = seq(0, 1, 0.2),
                          include.lowest = TRUE,
                          labels = paste0("Q", 1:5))]

agg_q <- uf_full[, .(
  cobertura_media = round(weighted.mean(cobertura, w = pop_0_3), 1),
  saeb_media     = round(weighted.mean(adequado_pct, w = n_alunos), 1),
  n_ufs = .N
), by = quintil][order(quintil)]

## resumos nacionais
cob_nacional <- round(sum(cob_uf$mat_creche) / sum(cob_uf$pop_0_3) * 100, 1)
saeb_nacional <- round(saeb[, mean(adequado) * 100], 1)

## panels
panel_a <- lapply(seq_len(nrow(agg_q)), function(i) {
  list(q = i, value = agg_q$cobertura_media[i], n = agg_q$n_ufs[i])
})
panel_b <- lapply(seq_len(nrow(agg_q)), function(i) {
  list(q = i, value = agg_q$saeb_media[i], n = agg_q$n_ufs[i])
})

L4 <- list(
  meta = list(
    leitura = "L4",
    titulo_curto = "Creche que não chegou ressoa no SAEB",
    eyebrow = "Leitura 04 · Censo Escolar 2025 + Censo Demográfico 2022 · cobertura de creche por UF",
    fonte = "QT_MAT_INF_CRE (Censo Escolar 2025) / pop 0-3 anos (SIDRA t9514) × SAEB 2023 5º EF — agregado por UF (quintis das 27 unidades)",
    n_ufs = nrow(uf_full),
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    cobertura_q1 = agg_q$cobertura_media[1],
    cobertura_q5 = agg_q$cobertura_media[nrow(agg_q)],
    cobertura_nacional = cob_nacional,
    meta_pne = 50,
    saeb_q1 = agg_q$saeb_media[1],
    saeb_q5 = agg_q$saeb_media[nrow(agg_q)],
    saeb_nacional = saeb_nacional,
    gap_pp = round(agg_q$saeb_media[nrow(agg_q)] - agg_q$saeb_media[1], 1)
  ),
  viz = list(
    panel_a_titulo = "A · % DE CRIANÇAS DE 0 A 3 ANOS EM CRECHE · POR GRUPO DE ESTADOS",
    panel_a_dados = panel_a,
    meta_pne = 50,
    panel_b_titulo = "B · % COM APRENDIZAGEM ADEQUADA EM LP · 5º ANO · MESMO AGRUPAMENTO",
    panel_b_dados = panel_b,
    anotacao = "Os dois indicadores desenham a mesma curva"
  )
)

write_json(L4, file.path(DIR_AGG, "L4.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L4 ✓ | %d UFs | cobertura Q1=%.1f%% Q5=%.1f%% | SAEB Q1=%.1f%% Q5=%.1f%%",
                 nrow(uf_full), agg_q$cobertura_media[1], agg_q$cobertura_media[nrow(agg_q)],
                 agg_q$saeb_media[1], agg_q$saeb_media[nrow(agg_q)]))
