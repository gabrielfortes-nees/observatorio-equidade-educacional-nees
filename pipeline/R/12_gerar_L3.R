## 12 — L3 (REESCRITA 2): "Quanto da diferença a classe explica?"
## Decompõe, por padronização em estratos, duas diferenças de proficiência em LP
## no 9º ano: a racial (brancos − pretos/pardos) e a de gênero (meninas − meninos).
## Em cada caso, mede quanto a carga de trabalho e a renda explicam e quanto
## resta sem explicação (o resíduo).
## A decomposição de gênero entra como espelho do método: mostra que o resíduo
## racial não é um artefato estatístico do procedimento.
## Base: SAEB 2023 9º EF.
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_9ef.parquet")))
saeb <- saeb[in_publica == 1 & !is.na(proficiencia_lp_saeb) & !is.na(inse_aluno)]

## ---------- grupos ----------
saeb[, raca := fcase(
  tx_resp_q04 %in% c("A", "D"), "branca",
  tx_resp_q04 %in% c("B", "C"), "preta"
)]
saeb[, sexo := fcase(
  tx_resp_q01 == "A", "masculino",
  tx_resp_q01 == "B", "feminino"
)]

## ---------- carga de trabalho (Q21c doméstico + Q21d fora) ----------
horas <- c(A = 0, B = 0.5, C = 1.5, D = 4, E = 6)         # horas/dia aproximadas
saeb[, h_dom  := horas[tx_resp_q21c]]
saeb[, h_fora := horas[tx_resp_q21d]]
saeb <- saeb[!is.na(h_dom) & !is.na(h_fora)]
saeb[, carga := h_dom + h_fora]
saeb[, trab_faixa := fcase(
  carga == 0,             "nenhuma",
  carga > 0 & carga <= 2, "leve",
  carga > 2,              "pesada"
)]

## ---------- quintil de INSE ----------
saeb[, inse_q := cut(inse_aluno,
                     breaks = quantile(inse_aluno, probs = seq(0, 1, 0.2), na.rm = TRUE),
                     include.lowest = TRUE, labels = paste0("Q", 1:5))]

## ---------- padronização por estratos ----------
## Para cada estrato, calcula a diferença entre os dois grupos e tira a média
## ponderada pela distribuição de TODOS os estudantes (população de referência).
## Só usa estratos com pelo menos 20 estudantes de cada grupo.
dif_padronizada <- function(d, vars_estrato, a, b) {
  ag <- d[, .(
    prof_a = mean(proficiencia_lp_saeb[g == a]),
    prof_b = mean(proficiencia_lp_saeb[g == b]),
    n_a = sum(g == a),
    n_b = sum(g == b),
    n_tot = .N
  ), by = vars_estrato]
  ag <- ag[n_a >= 20 & n_b >= 20]
  ag[, dif := prof_a - prof_b]
  ag[, weighted.mean(dif, n_tot)]
}

## decompõe a diferença a - b em: bruta -> sem trabalho -> resíduo
decompor <- function(dt, gcol, a, b) {
  d <- copy(dt[!is.na(get(gcol))])
  d[, g := get(gcol)]
  d <- d[g %in% c(a, b)]
  bruta    <- mean(d[g == a, proficiencia_lp_saeb]) - mean(d[g == b, proficiencia_lp_saeb])
  sem_trab <- dif_padronizada(d, "trab_faixa", a, b)
  residuo  <- dif_padronizada(d, c("trab_faixa", "inse_q"), a, b)
  ## "explicado pela classe" = o quanto a diferença encolhe ao igualar trabalho e renda.
  ## Para a barra, explicado + residuo_viz = bruta (sem segmentos negativos).
  explicado   <- max(bruta - residuo, 0)
  residuo_viz <- bruta - explicado
  list(
    bruta       = round(bruta, 1),
    trabalho    = round(bruta - sem_trab, 1),
    renda       = round(sem_trab - residuo, 1),
    residuo     = round(residuo, 1),
    explicado   = round(explicado, 1),
    residuo_viz = round(residuo_viz, 1),
    pct_residuo = round(residuo_viz / bruta * 100)
  )
}

dec_raca <- decompor(saeb, "raca", "branca", "preta")
dec_sexo <- decompor(saeb, "sexo", "feminino", "masculino")

mk_decomp <- function(dec, rotulo, sub) list(
  rotulo      = rotulo,
  sub         = sub,
  bruto       = dec$bruta,
  explicado   = dec$explicado,
  residuo     = dec$residuo_viz,
  pct_residuo = dec$pct_residuo
)

L3 <- list(
  meta = list(
    leitura = "L3",
    titulo_curto = "Quanto da diferença a classe explica",
    eyebrow = "Leitura 03 · E se… · SAEB 2023 9º EF · decomposição da diferença",
    fonte = "SAEB 2023 9º EF · escolas públicas · decomposição por padronização (estratos de carga de trabalho × quintil de INSE)",
    cenario = TRUE,
    cf_key = "residuo",
    evidencia = "Padronização por estratos: compara estudantes com a mesma carga de trabalho e a mesma faixa de renda. Não é modelo causal; é decomposição descritiva. Selo: evidência indireta.",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    raca_bruto       = dec_raca$bruta,
    raca_trabalho    = dec_raca$trabalho,
    raca_renda       = dec_raca$renda,
    raca_explicado   = dec_raca$explicado,
    raca_residuo     = dec_raca$residuo,
    raca_pct_residuo = round(dec_raca$residuo / dec_raca$bruta * 100),
    sexo_bruto       = dec_sexo$bruta,
    sexo_residuo     = dec_sexo$residuo,
    sexo_pct_residuo = round(dec_sexo$residuo / dec_sexo$bruta * 100)
  ),
  viz = list(
    indicador = "Diferença de proficiência em LP no 9º ano (pontos SAEB) e quanto dela a classe explica",
    decomposicoes = list(
      mk_decomp(dec_raca, "Diferença racial", "brancos − pretos e pardos"),
      mk_decomp(dec_sexo, "Diferença de gênero", "meninas − meninos")
    ),
    anotacao = sprintf("Igualadas a renda e a carga de trabalho, %d%% da diferença racial ainda permanece",
                       round(dec_raca$residuo / dec_raca$bruta * 100))
  )
)

write_json(L3, file.path(DIR_AGG, "L3.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L3 ✓ | raça: bruta %.1f -> resíduo %.1f (%.0f%%) | gênero: bruta %.1f -> resíduo %.1f (%.0f%%)",
                 dec_raca$bruta, dec_raca$residuo, dec_raca$residuo / dec_raca$bruta * 100,
                 dec_sexo$bruta, dec_sexo$residuo, dec_sexo$residuo / dec_sexo$bruta * 100))
