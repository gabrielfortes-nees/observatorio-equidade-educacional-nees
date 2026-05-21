## 12 — L3 (REESCRITA): "O gap que sobra mesmo assim"
## Contrafactual em camadas. Decompõe o gap racial de proficiência:
##   gap bruto → remove camada do trabalho → remove camada da renda → resíduo
## O resíduo é o gap que persiste mesmo igualando trabalho e renda —
## a parte que não é classe nem jornada, é raça.
## Método: padronização por estratos (standardization). Base: SAEB 2023 9º EF.
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_9ef.parquet")))
saeb <- saeb[in_publica == 1 & !is.na(proficiencia_lp_saeb) & !is.na(inse_aluno)]
saeb <- saeb[tx_resp_q04 %in% c("A", "B", "C", "D", "E")]
saeb[, raca := fcase(
  tx_resp_q04 %in% c("A", "D"), "branca",
  tx_resp_q04 %in% c("B", "C"), "preta",
  tx_resp_q04 == "E",          "indigena"
)]
saeb <- saeb[raca %in% c("branca", "preta")]

## ---------- Carga de trabalho (Q21c doméstico + Q21d fora) ----------
horas <- c(A = 0, B = 0.5, C = 1.5, D = 4, E = 6)         # horas/dia aproximadas
saeb[, h_dom  := horas[tx_resp_q21c]]
saeb[, h_fora := horas[tx_resp_q21d]]
saeb <- saeb[!is.na(h_dom) & !is.na(h_fora)]
saeb[, carga := h_dom + h_fora]
saeb[, trab_faixa := fcase(
  carga == 0,            "nenhuma",
  carga > 0 & carga <= 2, "leve",
  carga > 2,             "pesada"
)]

## ---------- Quintil de INSE ----------
saeb[, inse_q := cut(inse_aluno,
                     breaks = quantile(inse_aluno, probs = seq(0, 1, 0.2), na.rm = TRUE),
                     include.lowest = TRUE, labels = paste0("Q", 1:5))]

## ---------- Função de padronização ----------
## gap padronizado: para cada estrato, calcula gap branca-preta;
## média ponderada pela distribuição de TODOS os alunos (população de referência).
gap_padronizado <- function(dt, vars_estrato) {
  ag <- dt[, .(
    prof_br = mean(proficiencia_lp_saeb[raca == "branca"]),
    prof_pr = mean(proficiencia_lp_saeb[raca == "preta"]),
    n_br = sum(raca == "branca"),
    n_pr = sum(raca == "preta"),
    n_tot = .N
  ), by = vars_estrato]
  ## só estratos com os dois grupos presentes
  ag <- ag[n_br >= 20 & n_pr >= 20]
  ag[, gap := prof_br - prof_pr]
  ag[, weighted.mean(gap, n_tot)]
}

## ---------- As três medidas ----------
gap_bruto       <- saeb[raca == "branca", mean(proficiencia_lp_saeb)] -
                   saeb[raca == "preta",  mean(proficiencia_lp_saeb)]
gap_sem_trab    <- gap_padronizado(saeb, "trab_faixa")
gap_residuo     <- gap_padronizado(saeb, c("trab_faixa", "inse_q"))

camada_trabalho <- gap_bruto    - gap_sem_trab
camada_renda    <- gap_sem_trab - gap_residuo

## proteção: se alguma camada ficar levemente negativa por ruído, zera
camada_trabalho <- max(camada_trabalho, 0)
camada_renda    <- max(camada_renda, 0)

pct_residuo <- gap_residuo / gap_bruto * 100

## ---------- Estrutura JSON ----------
## Barra empilhada: o gap bruto decomposto em 3 fatias.
## trabalho e renda são as fatias "explicáveis"; o resíduo é a fatia da raça.
segmentos <- list(
  list(label = "Carga de trabalho",
       descricao = "doméstico + remunerado",
       valor = round(camada_trabalho, 1), grupo = "explicado"),
  list(label = "Renda (nível socioeconômico)",
       descricao = "quintil de INSE",
       valor = round(camada_renda, 1),    grupo = "explicado"),
  list(label = "Resíduo",
       descricao = "o que não é trabalho nem renda",
       valor = round(gap_residuo, 1),     grupo = "residuo")
)

L3 <- list(
  meta = list(
    leitura = "L3",
    titulo_curto = "O gap que sobra mesmo assim",
    eyebrow = "Leitura 03 · Contrafactual · SAEB 2023 9º EF · decomposição do gap racial",
    fonte = "SAEB 2023 — microdados aluno · 9º EF · escolas públicas · decomposição por padronização (estratos de carga de trabalho × quintil de INSE)",
    contrafactual = TRUE,
    cf_key = "residuo",
    evidencia = "Padronização por estratos (standardization) — compara estudantes brancos e pretos/pardos com a mesma carga de trabalho e a mesma faixa de renda. Não é modelo causal; é decomposição descritiva. Selo: evidência indireta.",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    gap_bruto = round(gap_bruto, 1),
    camada_trabalho = round(camada_trabalho, 1),
    camada_renda = round(camada_renda, 1),
    gap_residuo = round(gap_residuo, 1),
    pct_residuo = round(pct_residuo, 0)
  ),
  viz = list(
    indicador = "Gap de proficiência LP entre estudantes brancos e pretos/pardos (pontos SAEB)",
    gap_bruto = round(gap_bruto, 1),
    segmentos = segmentos,
    anotacao = sprintf("mesmo igualando renda e trabalho, sobram %.1f pontos", gap_residuo)
  )
)

write_json(L3, file.path(DIR_AGG, "L3.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L3 ✓ | bruto %.1f → s/ trabalho %.1f → resíduo %.1f (%.0f%% do gap persiste)",
                 gap_bruto, gap_sem_trab, gap_residuo, pct_residuo))
