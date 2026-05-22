## 17 — L8 (REESCRITA 2): "O funil tem cor"
## Composição racial do SAEB em 3 pontos da educação básica: 5º EF, 9º EF e 3º EM.
## A fatia de estudantes pretos/pardos encolhe ao longo do percurso — quem chega
## ao fim do EM é proporcionalmente mais branco do que quem estava no 5º ano.
## Não é rastreamento individual: é uma comparação pedagógica entre a composição
## do fundamental e a do médio, para refletir sobre quem o sistema retém.
## Base: SAEB 2023 · escolas públicas.
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

ler_comp <- function(arq, etapa_label) {
  dt <- as.data.table(read_parquet(file.path(DIR_PROC, arq)))
  dt <- dt[in_publica == 1 & tx_resp_q04 %in% c("A", "B", "C", "D", "E")]
  dt[, raca := fcase(
    tx_resp_q04 %in% c("A", "D"), "branca",
    tx_resp_q04 %in% c("B", "C"), "preta",
    tx_resp_q04 == "E",          "indigena"
  )]
  n <- nrow(dt)
  list(
    etapa     = etapa_label,
    n         = n,
    n_preta   = dt[raca == "preta", .N],
    branca    = round(dt[raca == "branca",   .N] / n * 100, 1),
    preta     = round(dt[raca == "preta",    .N] / n * 100, 1),
    indigena  = round(dt[raca == "indigena", .N] / n * 100, 1)
  )
}

e5 <- ler_comp("saeb_2023_5ef.parquet", "5º ano EF")
e9 <- ler_comp("saeb_2023_9ef.parquet", "9º ano EF")
e3 <- ler_comp("saeb_2023_3em.parquet", "3º ano EM")

etapas <- list(e5, e9, e3)

queda_preta <- round(e5$preta - e3$preta, 1)

## Tradução do percentual em número de estudantes: quantos estudantes pretos e
## pardos a mais haveria, entre os avaliados do 3º ano, se a proporção do 5º ano
## tivesse se mantido. Arredondado ao milhar (é uma aproximação para reflexão).
dif_absoluta <- round((e5$preta - e3$preta) / 100 * e3$n, -3)

L8 <- list(
  meta = list(
    leitura = "L8",
    titulo_curto = "O funil tem cor",
    eyebrow = "Leitura 08 · SAEB 2023 · composição racial em 3 pontos da educação básica",
    fonte = "SAEB 2023 · microdados aluno · escolas públicas · 5º EF, 9º EF e 3º EM · cor/raça autodeclarada (TX_RESP_Q04)",
    aviso_metodologico = "Comparação pedagógica para refletir sobre a proporção de estudantes pretos e pardos no ensino fundamental e no médio. Cada etapa é uma geração diferente avaliada em 2023; não são os mesmos estudantes acompanhados ao longo do tempo.",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    preta_5ef = e5$preta,
    preta_9ef = e9$preta,
    preta_3em = e3$preta,
    branca_5ef = e5$branca,
    branca_3em = e3$branca,
    queda_preta_pp = queda_preta,
    dif_absoluta = dif_absoluta,
    dif_absoluta_mil = round(dif_absoluta / 1000),
    n_5ef = e5$n,
    n_3em = e3$n
  ),
  viz = list(
    indicador = "Composição racial dos estudantes em cada ponto da trajetória (%)",
    foco = "Pretos e pardos",
    etapas = lapply(etapas, function(e) {
      list(
        etapa = e$etapa,
        n = e$n,
        segmentos = list(
          list(grupo = "Brancos e amarelos",   valor = e$branca,   cor = "alto"),
          list(grupo = "Pretos e pardos",      valor = e$preta,    cor = "baixo"),
          list(grupo = "Indígenas",            valor = e$indigena, cor = "mark")
        )
      )
    }),
    anotacao = gsub("\\.", ",", sprintf("Do 5º ano ao 3º ano do EM, a fatia preta e parda encolhe %.1f pontos", queda_preta))
  )
)

write_json(L8, file.path(DIR_AGG, "L8.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L8 ✓ | pretos/pardos: 5EF %.1f%% -> 9EF %.1f%% -> 3EM %.1f%% (queda %.1f pp ~ %s estudantes)",
                 e5$preta, e9$preta, e3$preta, queda_preta,
                 format(dif_absoluta, big.mark = ".", scientific = FALSE)))
