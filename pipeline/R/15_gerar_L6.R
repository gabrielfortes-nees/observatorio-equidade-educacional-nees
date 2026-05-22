## 15 — L6 (REESCRITA 2): "E se... não houvesse transporte escolar?"
## O transporte escolar público (sustentado pelo PNATE — Programa Nacional de
## Apoio ao Transporte do Escolar, do FNDE) como pré-condição material da
## permanência. Compara a dependência do transporte entre escolas urbanas e
## rurais, por região: no campo, a distância é o primeiro obstáculo.
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

## ---------- % de matrículas que dependem de transporte ----------
pct_dep <- function(sub) {
  if (nrow(sub) == 0 || sum(sub$qt_mat_bas, na.rm = TRUE) == 0) return(0)
  round(sum(sub$qt_transp_publico, na.rm = TRUE) /
        sum(sub$qt_mat_bas, na.rm = TRUE) * 100, 1)
}

## ---------- urbano x rural, por região ----------
ordem_reg <- c("Norte", "Nordeste", "Centro-Oeste", "Sul", "Sudeste")
bars <- lapply(ordem_reg, function(rg) {
  list(
    regiao = rg,
    rural  = pct_dep(d[regiao == rg & rural == TRUE]),
    urbana = pct_dep(d[regiao == rg & rural == FALSE])
  )
})

## ---------- números nacionais ----------
pct_rural  <- pct_dep(d[rural == TRUE])
pct_urbana <- pct_dep(d[rural == FALSE])
total_transp     <- d[, sum(qt_transp_publico, na.rm = TRUE)]
total_transp_rur <- d[rural == TRUE, sum(qt_transp_publico, na.rm = TRUE)]
razao_rural_urb  <- round(pct_rural / pct_urbana, 1)

L6 <- list(
  meta = list(
    leitura = "L6",
    titulo_curto = "O transporte que liga a criança à escola",
    eyebrow = "Leitura 06 · E se… · Censo Escolar 2025 · transporte escolar público",
    fonte = "Censo Escolar 2025 · QT_TRANSP_PUBLICO × matrículas da rede pública · análise de cenário · política: PNATE/FNDE",
    cenario = TRUE,
    cf_key = "transporte",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    total_transp_milhoes = round(total_transp / 1e6, 1),
    total_transp_rural_milhoes = round(total_transp_rur / 1e6, 1),
    pct_rural = pct_rural,
    pct_urbana = pct_urbana,
    razao_rural_urb = razao_rural_urb
  ),
  viz = list(
    indicador = "Matrículas da rede pública que dependem de transporte escolar público (%)",
    titulo_real = "Quanto cada rede depende do transporte escolar",
    titulo_off  = "E se não houvesse transporte — quem deixaria de chegar",
    bars = bars,
    anotacao = sprintf("No campo, a dependência do transporte é cerca de %s vezes maior que na cidade",
                       sub("\\.", ",", as.character(razao_rural_urb)))
  )
)

write_json(L6, file.path(DIR_AGG, "L6.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L6 ✓ | dependência do transporte: rural %.1f%% vs urbana %.1f%% (%.1fx) · %.1f mi estudantes",
                 pct_rural, pct_urbana, razao_rural_urb, total_transp / 1e6))
