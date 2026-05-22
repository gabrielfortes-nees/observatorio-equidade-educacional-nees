## 16 — L7 (REESCRITA): reprovação como porta do abandono — quem é empurrado para a porta
## Dois achados encadeados:
##  (A) a porta: quem reprova abandona muito mais (de ~3% para ~25%);
##  (B) o custo da reprovação, uma vez que ela ocorre, é quase igual entre
##      brancos e pretos/pardos — MAS a reprovação não se distribui igual:
##      estudantes pretos/pardos estão mais concentrados nas reprovações.
## A desigualdade racial do abandono está em QUEM é empurrado para a porta.
## Base: SAEB 2023 9º EF — Q19 (reprovação) × Q20 (abandono) × Q04 (raça).
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_9ef.parquet")))
saeb <- saeb[in_publica == 1]
saeb <- saeb[tx_resp_q19 %in% c("A","B","C") &
             tx_resp_q20 %in% c("A","B","C") &
             tx_resp_q04 %in% c("A","B","C","D","E")]

saeb[, ja_abandonou := as.integer(tx_resp_q20 %in% c("B","C"))]
niveis <- c("Nunca reprovou","Reprovou 1 vez","Reprovou 2+ vezes")
saeb[, reprov := factor(fcase(
  tx_resp_q19 == "A", niveis[1],
  tx_resp_q19 == "B", niveis[2],
  tx_resp_q19 == "C", niveis[3]
), levels = niveis)]
saeb[, raca := fcase(
  tx_resp_q04 %in% c("A","D"), "branca",
  tx_resp_q04 %in% c("B","C"), "preta",
  tx_resp_q04 == "E",          "indigena"
)]
saeb <- saeb[raca %in% c("branca", "preta")]

## ---------- (A) A PORTA: % de abandono por nível de reprovação ----------
porta <- saeb[, .(pct_abandono = round(mean(ja_abandonou) * 100, 1), n = .N), by = reprov][order(reprov)]
porta_lst <- lapply(seq_len(nrow(porta)), function(i)
  list(reprovacao = as.character(porta$reprov[i]), pct_abandono = porta$pct_abandono[i], n = porta$n[i]))

## ---------- (B) DISTRIBUIÇÃO: como cada raça se reparte entre os níveis ----------
dist <- saeb[, .N, by = .(raca, reprov)]
dist[, pct := round(N / sum(N) * 100, 1), by = raca]
distrib <- lapply(c("branca", "preta"), function(rc) {
  v <- dist[raca == rc]
  list(
    raca = if (rc == "branca") "Brancos e amarelos" else "Pretos e pardos",
    nunca = v[reprov == niveis[1], pct],
    uma   = v[reprov == niveis[2], pct],
    duas  = v[reprov == niveis[3], pct]
  )
})

## % de cada raça que já reprovou ao menos uma vez
ja_reprov <- saeb[, .(pct = round(mean(reprov != "Nunca reprovou") * 100, 1)), by = raca]
reprov_branca <- ja_reprov[raca == "branca", pct]
reprov_preta  <- ja_reprov[raca == "preta",  pct]

L7 <- list(
  meta = list(
    leitura = "L7",
    titulo_curto = "A reprovação como porta do abandono",
    eyebrow = "Leitura 07 · SAEB 2023 · 9º EF · reprovação, abandono e raça",
    fonte = "SAEB 2023 — microdados aluno · 9º EF · escolas públicas · TX_RESP_Q19 × Q20 × Q04",
    n_total = nrow(saeb),
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    abandono_nunca = porta$pct_abandono[1],
    abandono_uma   = porta$pct_abandono[2],
    abandono_duas  = porta$pct_abandono[3],
    reprov_branca  = reprov_branca,
    reprov_preta   = reprov_preta,
    gap_reprov     = round(reprov_preta - reprov_branca, 1)
  ),
  viz = list(
    indicador = "% que declara já ter abandonado, por nível de reprovação · e distribuição da reprovação por raça",
    porta_titulo = "1 · ENTRE QUEM REPROVOU, QUANTOS DECLARAM JÁ TER ABANDONADO",
    porta = porta_lst,
    distribuicao_titulo = "2 · COMO A REPROVAÇÃO SE DISTRIBUI ENTRE BRANCOS E PRETOS/PARDOS",
    distribuicao = distrib,
    anotacao = gsub("\\.", ",", sprintf("Os estudantes pretos e pardos reprovam mais: %.1f%% contra %.1f%% dos brancos",
                       reprov_preta, reprov_branca))
  )
)

write_json(L7, file.path(DIR_AGG, "L7.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L7 ✓ | porta: %.1f%% → %.1f%% → %.1f%% | já reprovou: brancos %.1f%% vs pretos/pardos %.1f%%",
                 porta$pct_abandono[1], porta$pct_abandono[2], porta$pct_abandono[3],
                 reprov_branca, reprov_preta))
