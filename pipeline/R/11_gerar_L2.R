## 11 — L2 (REESCRITA): "Dentro da mesma escola"
## Gap racial de proficiência entre colegas da MESMA escola.
## Mostra que o gap não é só "escolas diferentes" — sobrevive intra-escola.
## Base: SAEB 2023 · 5º EF · LP · escolas públicas
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

`%||%` <- function(a, b) if (length(a) == 0 || is.null(a) || is.na(a)) b else a

saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_5ef.parquet")))
saeb <- saeb[in_publica == 1 & !is.na(proficiencia_lp_saeb)]
saeb <- saeb[tx_resp_q04 %in% c("A", "B", "C", "D", "E")]
saeb[, raca := fcase(
  tx_resp_q04 %in% c("A", "D"), "branca",
  tx_resp_q04 %in% c("B", "C"), "preta",
  tx_resp_q04 == "E",          "indigena"
)]
saeb <- saeb[raca %in% c("branca", "preta")]

## ---------- Gap bruto nacional ----------
prof_br <- saeb[raca == "branca", mean(proficiencia_lp_saeb)]
prof_pr <- saeb[raca == "preta",  mean(proficiencia_lp_saeb)]
gap_bruto <- prof_br - prof_pr

## ---------- Gap dentro de cada escola ----------
por_escola <- saeb[, .(
  prof_branca = mean(proficiencia_lp_saeb[raca == "branca"]),
  prof_preta  = mean(proficiencia_lp_saeb[raca == "preta"]),
  n_branca = sum(raca == "branca"),
  n_preta  = sum(raca == "preta")
), by = id_escola]

## só escolas com massa crítica dos dois grupos (gap intra estável)
MIN_GRP <- 10
escolas_mistas <- por_escola[n_branca >= MIN_GRP & n_preta >= MIN_GRP]
escolas_mistas[, gap_intra := prof_branca - prof_preta]
escolas_mistas[, peso := n_branca + n_preta]

gap_intra_medio <- escolas_mistas[, weighted.mean(gap_intra, peso)]
pct_gap_branco  <- escolas_mistas[, mean(gap_intra > 0) * 100]
n_escolas       <- nrow(escolas_mistas)

## quanto do gap bruto "sobrevive" dentro da mesma escola
pct_sobrevive <- gap_intra_medio / gap_bruto * 100

## ---------- Histograma da distribuição dos gaps intra-escola ----------
breaks <- seq(-40, 60, by = 10)
n_bins <- length(breaks) - 1
escolas_mistas[, bin_idx := findInterval(pmin(pmax(gap_intra, breaks[1]), breaks[n_bins+1] - 0.001),
                                          breaks, rightmost.closed = TRUE)]
contagem <- escolas_mistas[, .N, by = bin_idx]
histograma <- lapply(seq_len(n_bins), function(i) {
  centro <- (breaks[i] + breaks[i + 1]) / 2
  n_i <- contagem[bin_idx == i, N]
  list(
    centro = centro,
    inicio = breaks[i],
    fim    = breaks[i + 1],
    n      = if (length(n_i) == 0) 0L else as.integer(n_i),
    lado   = if (centro > 0) "branco" else "preto"
  )
})

L2 <- list(
  meta = list(
    leitura = "L2",
    titulo_curto = "A diferença racial dentro da mesma escola",
    eyebrow = "Leitura 02 · SAEB 2023 · 5º EF · proficiência LP por escola",
    fonte = sprintf("SAEB 2023 · microdados aluno · escolas públicas · %s escolas com ao menos %d estudantes brancos e %d pretos/pardos",
                    format(n_escolas, big.mark = "."), MIN_GRP, MIN_GRP),
    n_escolas = n_escolas,
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    gap_bruto = round(gap_bruto, 1),
    gap_intra_medio = round(gap_intra_medio, 1),
    pct_sobrevive = round(pct_sobrevive, 0),
    pct_escolas_gap_branco = round(pct_gap_branco, 1),
    n_escolas = n_escolas
  ),
  viz = list(
    indicador = "Distribuição da diferença de proficiência em LP (brancos − pretos/pardos) dentro de cada escola",
    gap_bruto = round(gap_bruto, 1),
    gap_intra_medio = round(gap_intra_medio, 1),
    histograma = histograma,
    anotacao = sprintf("Em %.0f%% das escolas analisadas, a média dos estudantes brancos fica acima da dos pretos e pardos", pct_gap_branco)
  )
)

write_json(L2, file.path(DIR_AGG, "L2.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L2 ✓ | gap bruto %.1f | gap intra-escola %.1f (%.0f%% sobrevive) | %.1f%% escolas pró-branco",
                 gap_bruto, gap_intra_medio, pct_sobrevive, pct_gap_branco))
