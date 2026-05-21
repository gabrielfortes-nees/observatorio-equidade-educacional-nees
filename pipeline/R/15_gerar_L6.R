## 15 — L6 (REESCRITA): "E se... não houvesse transporte escolar?"
## O transporte escolar público como pré-condição material da permanência —
## sobretudo na escola rural, onde a distância é o primeiro obstáculo.
## Base: Censo Escolar 2025 — QT_TRANSP_PUBLICO × matrículas da rede pública.
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

esc <- as.data.table(read_parquet(file.path(DIR_PROC, "censo_escolar_2025_escola.parquet")))
esc <- esc[tp_dependencia %in% c(1, 2, 3)]                   # rede pública

cat_step("lendo Tabela_Matricula_2025.csv (transporte) ...")
mat <- fread(file.path(DIR_RAW, "censo_escolar_2025/Tabela_Matricula_2025.csv"),
             select = c("CO_ENTIDADE", "QT_MAT_BAS", "QT_TRANSP_PUBLICO"),
             showProgress = FALSE)
setnames(mat, tolower(names(mat)))

d <- merge(esc[, .(co_entidade, sg_uf, tp_localizacao)], mat, by = "co_entidade")

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

## ---------- % de matrículas que dependem de transporte, rural vs urbana ----------
pct_dep <- function(sub) round(sum(sub$qt_transp_publico, na.rm=TRUE) /
                                sum(sub$qt_mat_bas, na.rm=TRUE) * 100, 1)
pct_rural   <- pct_dep(d[rural == TRUE])
pct_urbana  <- pct_dep(d[rural == FALSE])

## ---------- nº de estudantes que usam transporte, por região (escolas rurais) ----------
ordem_reg <- c("Norte", "Nordeste", "Centro-Oeste", "Sul", "Sudeste")
por_reg <- d[rural == TRUE, .(
  transp = sum(qt_transp_publico, na.rm = TRUE),
  mat    = sum(qt_mat_bas, na.rm = TRUE)
), by = regiao]
por_reg[, pct := round(transp / mat * 100, 1)]
por_reg <- por_reg[match(ordem_reg, regiao)]

total_transp     <- d[, sum(qt_transp_publico, na.rm = TRUE)]
total_transp_rur <- d[rural == TRUE, sum(qt_transp_publico, na.rm = TRUE)]

bars <- lapply(seq_len(nrow(por_reg)), function(i) {
  list(
    label = por_reg$regiao[i],
    real  = round(por_reg$transp[i] / 1e3, 1),   # milhares de estudantes
    off   = 0,
    pct   = por_reg$pct[i],
    color_key = c("counterfactual","brown","orangeSoft","orange","orange")[i]
  )
})

L6 <- list(
  meta = list(
    leitura = "L6",
    titulo_curto = "O transporte que liga a criança à escola",
    eyebrow = "Leitura 06 · E se… · Censo Escolar 2025 · transporte escolar público",
    fonte = "Censo Escolar 2025 — QT_TRANSP_PUBLICO × matrículas da rede pública · análise de cenário",
    cenario = TRUE,
    cf_key = "transporte",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    total_transp_milhoes = round(total_transp / 1e6, 1),
    total_transp_rural_milhoes = round(total_transp_rur / 1e6, 1),
    pct_rural = pct_rural,
    pct_urbana = pct_urbana
  ),
  viz = list(
    indicador = "Estudantes de escolas rurais que dependem de transporte escolar público (milhares)",
    titulo_real = "Estudantes que chegam à escola pelo transporte público",
    titulo_off  = "E se não houvesse transporte — quem deixaria de chegar",
    bars = bars,
    anotacao = sprintf("nas escolas rurais, %.0f%% das matrículas dependem do transporte", pct_rural)
  )
)

write_json(L6, file.path(DIR_AGG, "L6.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L6 ✓ | transporte: %.1f mi estudantes (%.1f mi rurais) · rural %.0f%% vs urbana %.0f%%",
                 total_transp/1e6, total_transp_rur/1e6, pct_rural, pct_urbana))
