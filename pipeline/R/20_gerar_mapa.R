## 20 — Mapa navegável: SAEB 5º EF % aprendizagem adequada × UF × recorte (raça + sexo)
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_5ef.parquet")))
saeb <- saeb[in_publica == 1 & !is.na(proficiencia_lp_saeb)]
saeb <- saeb[tx_resp_q01 %in% c("A","B") & tx_resp_q04 %in% c("A","B","C","D","E")]

saeb[, sexo := fcase(tx_resp_q01 == "A", "masculino", tx_resp_q01 == "B", "feminino")]
saeb[, raca := fcase(tx_resp_q04 %in% c("A","D"), "brancos",
                     tx_resp_q04 %in% c("B","C"), "pretos_pardos",
                     tx_resp_q04 == "E", "indigenas")]
saeb[, adequado := as.integer(proficiencia_lp_saeb >= ADEQ_LP_5EF)]

## sigla UF
uf_sigla <- c("11"="RO","12"="AC","13"="AM","14"="RR","15"="PA","16"="AP","17"="TO",
              "21"="MA","22"="PI","23"="CE","24"="RN","25"="PB","26"="PE","27"="AL","28"="SE","29"="BA",
              "31"="MG","32"="ES","33"="RJ","35"="SP",
              "41"="PR","42"="SC","43"="RS",
              "50"="MS","51"="MT","52"="GO","53"="DF")
saeb[, uf := uf_sigla[as.character(id_uf)]]

agregar <- function(filtros = NULL) {
  dt <- if (is.null(filtros)) saeb else saeb[eval(filtros)]
  out <- dt[, .(pct = round(mean(adequado) * 100, 1), n = .N), by = uf][order(uf)]
  out[!is.na(uf)]
}

camadas <- list(
  geral             = agregar(NULL),
  meninos_brancos   = agregar(quote(sexo == "masculino" & raca == "brancos")),
  meninas_brancas   = agregar(quote(sexo == "feminino"  & raca == "brancos")),
  meninos_pretos    = agregar(quote(sexo == "masculino" & raca == "pretos_pardos")),
  meninas_pretas    = agregar(quote(sexo == "feminino"  & raca == "pretos_pardos")),
  indigenas         = agregar(quote(raca == "indigenas"))
)

## ranking top 6 e bottom 6 da camada "meninas pretas" (recorte default do protótipo)
mp <- camadas$meninas_pretas
ranking <- list(
  top    = head(mp[order(-pct)], 6),
  bottom = tail(mp[order(-pct)], 6)
)

## Converter named vector R → objeto JSON {UF: valor} (não array)
as_named_obj <- function(dt) {
  o <- as.list(setNames(dt$pct, dt$uf))
  o[!is.na(names(o)) & names(o) != ""]
}
as_named_obj_n <- function(dt) {
  o <- as.list(setNames(dt$n, dt$uf))
  o[!is.na(names(o)) & names(o) != ""]
}

MAPA <- list(
  meta = list(
    indicador = "% aprendizagem adequada em LP — 5º EF (corte oficial INEP, prof. ≥ 225)",
    fonte = "SAEB 2023 microdados aluno · escolas públicas · 27 UFs",
    n_total = nrow(saeb),
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
    camadas_disponiveis = names(camadas)
  ),
  camadas = lapply(camadas, as_named_obj),
  n_alunos = lapply(camadas, as_named_obj_n),
  ranking_meninas_pretas = list(
    top    = lapply(seq_len(nrow(ranking$top)),
                    function(i) list(uf = ranking$top$uf[i],   pct = ranking$top$pct[i])),
    bottom = lapply(seq_len(nrow(ranking$bottom)),
                    function(i) list(uf = ranking$bottom$uf[i], pct = ranking$bottom$pct[i]))
  )
)

write_json(MAPA, file.path(DIR_AGG, "mapa.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("MAPA ✓ | %d UFs × %d camadas", length(camadas$geral$uf), length(camadas)))
