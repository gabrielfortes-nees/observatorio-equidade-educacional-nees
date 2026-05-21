## 14 — L5 (REESCRITA): "A sala onde cabem cinco séries"
## A turma multisseriada como forma própria de trajetória escolar — não como
## defeito. Uma professora conduzindo várias séries ao mesmo tempo é a escola
## possível em territórios rurais, ribeirinhos, do campo. Concluir os estudos
## partindo dali é uma conquista de permanência que a média urbana não enfrenta.
## Base: Censo Escolar 2025 — Tabela_Turma + Tabela_Escola.
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

esc <- as.data.table(read_parquet(file.path(DIR_PROC, "censo_escolar_2025_escola.parquet")))
esc <- esc[tp_dependencia %in% c(1, 2, 3)]                   # rede pública

cat_step("lendo Tabela_Turma_2025.csv ...")
tur <- fread(file.path(DIR_RAW, "censo_escolar_2025/Tabela_Turma_2025.csv"),
             select = c("CO_ENTIDADE", "QT_TUR_FUND_AI_MULTIETAPA", "QT_TUR_FUND_AF_MULTI"),
             showProgress = FALSE)
setnames(tur, tolower(names(tur)))

d <- merge(esc[, .(co_entidade, sg_uf, tp_localizacao)], tur, by = "co_entidade")
d[, turmas_multi := qt_tur_fund_ai_multietapa + qt_tur_fund_af_multi]
d[, tem_multi := turmas_multi > 0]

norte <- c("RO","AC","AM","RR","PA","AP","TO")
nord  <- c("MA","PI","CE","RN","PB","PE","AL","SE","BA")
d[, regiao := fcase(
  sg_uf %in% norte, "Norte",
  sg_uf %in% nord,  "Nordeste",
  sg_uf %in% c("MG","ES","RJ","SP"), "Sudeste",
  sg_uf %in% c("PR","SC","RS"), "Sul",
  default = "Centro-Oeste"
)]
d[, rural := tp_localizacao == 2]

## ---------- % de escolas RURAIS com turma multisseriada, por região ----------
ordem_reg <- c("Norte", "Nordeste", "Centro-Oeste", "Sul", "Sudeste")
por_reg <- d[rural == TRUE, .(
  pct_multi = round(mean(tem_multi) * 100, 1),
  n_escolas_rurais = .N
), by = regiao]
por_reg <- por_reg[match(ordem_reg, regiao)]

bars <- lapply(seq_len(nrow(por_reg)), function(i) {
  list(
    label = por_reg$regiao[i],
    value = por_reg$pct_multi[i],
    n_escolas = por_reg$n_escolas_rurais[i]
  )
})

## ---------- números nacionais ----------
n_escolas_multi <- d[tem_multi == TRUE, .N]
n_turmas_multi  <- d[, sum(turmas_multi, na.rm = TRUE)]
pct_rural_norte <- d[regiao == "Norte" & rural == TRUE, round(mean(tem_multi) * 100, 1)]
pct_rural_nac   <- d[rural == TRUE, round(mean(tem_multi) * 100, 1)]

L5 <- list(
  meta = list(
    leitura = "L5",
    titulo_curto = "A sala onde cabem cinco séries",
    eyebrow = "Leitura 05 · Censo Escolar 2025 · turmas multisseriadas na escola rural",
    fonte = "Censo Escolar 2025 — QT_TUR_FUND_AI_MULTIETAPA + QT_TUR_FUND_AF_MULTI · rede pública · escolas de localização rural",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    n_escolas_multi = n_escolas_multi,
    n_turmas_multi = n_turmas_multi,
    pct_rural_norte = pct_rural_norte,
    pct_rural_nacional = pct_rural_nac
  ),
  viz = list(
    indicador = "% de escolas rurais da rede pública com ao menos uma turma multisseriada",
    bars = bars,
    anotacao = sprintf("no Norte, %.0f%% das escolas rurais", pct_rural_norte)
  )
)

write_json(L5, file.path(DIR_AGG, "L5.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L5 ✓ | %s escolas com turma multisseriada | rural Norte %.1f%%",
                 format(n_escolas_multi, big.mark = "."), pct_rural_norte))
