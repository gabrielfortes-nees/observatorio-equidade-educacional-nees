## 10 — Gera L1.json
## Leitura 01: A média do SAEB esconde 13,5 pontos de gap racial.
## Cruzamento: sexo × raça × INSE (quintil) → % aprendizagem adequada LP 5º EF

source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

saeb <- read_parquet(file.path(DIR_PROC, "saeb_2023_5ef.parquet"))
setDT(saeb)

## ---------- Filtros ----------
saeb <- saeb[!is.na(proficiencia_lp_saeb) & !is.na(tx_resp_q01) &
             !is.na(tx_resp_q04) & !is.na(inse_aluno)]
saeb <- saeb[tx_resp_q01 %in% c("A", "B")]                      # masc / fem
saeb <- saeb[tx_resp_q04 %in% c("A", "B", "C", "D", "E")]        # exclui "não declara"
saeb <- saeb[in_publica == 1]                                    # escola pública

## ---------- Recodificação ----------
saeb[, sexo := fcase(tx_resp_q01 == "A", "masculino",
                     tx_resp_q01 == "B", "feminino")]

saeb[, raca := fcase(
  tx_resp_q04 %in% c("A", "D"), "branca_amarela",   # protótipo agrupa
  tx_resp_q04 %in% c("B", "C"), "preta_parda",
  tx_resp_q04 == "E",           "indigena"
)]

saeb[, inse_q := cut(inse_aluno,
                     breaks = quantile(inse_aluno, probs = seq(0, 1, 0.2), na.rm = TRUE),
                     include.lowest = TRUE,
                     labels = paste0("Q", 1:5))]

saeb[, adequado := as.integer(proficiencia_lp_saeb >= ADEQ_LP_5EF)]

## ---------- Estatísticas globais ----------
media_brasil <- saeb[, mean(adequado) * 100]
media_branca <- saeb[raca == "branca_amarela", mean(adequado) * 100]
media_preta  <- saeb[raca == "preta_parda",   mean(adequado) * 100]
gap_racial   <- media_branca - media_preta

## ---------- 8 grupos interseccionais ----------
combos <- CJ(
  sexo   = c("masculino", "feminino"),
  raca   = c("branca_amarela", "preta_parda"),
  inse_q = c("Q1", "Q5")
)

agg <- saeb[combos, on = c("sexo", "raca", "inse_q"),
            .(adequado_pct = round(mean(adequado, na.rm = TRUE) * 100, 1),
              n = .N),
            by = .EACHI]

label_grupo <- function(sexo, raca, inse_q) {
  s <- ifelse(sexo == "masculino", "Meninos", "Meninas")
  r <- ifelse(raca == "branca_amarela", "brancos", "pretos")
  ## concordância de gênero
  if (sexo == "feminino") r <- ifelse(raca == "branca_amarela", "brancas", "pretas")
  i <- ifelse(inse_q == "Q5", "INSE alto", "INSE baixo")
  sprintf("%s %s · %s", s, r, i)
}

agg[, label := mapply(label_grupo, sexo, raca, inse_q)]

## ordena igual ao protótipo: do topo (meninos brancos Q5) ao chão (meninas pretas Q1)
ordem <- c(
  "Meninos brancos · INSE alto", "Meninas brancas · INSE alto",
  "Meninos pretos · INSE alto",  "Meninas pretas · INSE alto",
  "Meninos brancos · INSE baixo", "Meninas brancas · INSE baixo",
  "Meninos pretos · INSE baixo", "Meninas pretas · INSE baixo"
)
agg <- agg[match(ordem, agg$label)]

gap_topo_chao <- agg$adequado_pct[1] - agg$adequado_pct[8]

## ---------- Estrutura JSON ----------
L1 <- list(
  meta = list(
    leitura = "L1",
    titulo_curto = "Média SAEB esconde gap racial",
    eyebrow = "Leitura 01 · SAEB 2023 · 5º ano · Língua Portuguesa",
    fonte = "SAEB 2023 — microdados aluno · Inep/MEC · cruzamentos por raça (Q04), sexo (Q01) e INSE quintilizado",
    etapa = "5º ano EF · Língua Portuguesa",
    n_total = nrow(saeb),
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    media_brasil = round(media_brasil, 1),
    media_branca_amarela = round(media_branca, 1),
    media_preta_parda = round(media_preta, 1),
    gap_racial_pp = round(gap_racial, 1)
  ),
  viz = list(
    indicador = "% aprendizagem adequada em LP (proficiência ≥ 200)",
    media_brasil = round(media_brasil, 1),
    grupos = lapply(seq_len(nrow(agg)), function(i) {
      list(
        label = agg$label[i],
        value = agg$adequado_pct[i],
        n = agg$n[i]
      )
    }),
    anotacao = sprintf("do topo ao chão: %.0f pontos", gap_topo_chao)
  )
)

write_json(L1, file.path(DIR_AGG, "L1.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L1.json ✓  | média BR: %.1f%%  | gap racial: %.1f pp  | gap topo-chão: %.1f pp",
                 media_brasil, gap_racial, gap_topo_chao))
