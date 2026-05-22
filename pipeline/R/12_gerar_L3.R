## 12 — L3 (REESCRITA 3): "Raça e classe não se somam, se cruzam"
## A interseção raça × classe em quatro posições, no 9º ano: estudantes brancos
## e pretos/pardos, no quintil mais rico e no mais pobre de INSE.
## A desvantagem racial não tem tamanho fixo — depende da classe. Isso refuta
## tanto o "é tudo classe" quanto o modelo aditivo (raça + classe como parcelas
## separáveis, que era o problema da versão anterior desta leitura).
## Base: SAEB 2023 9º EF, escolas públicas.
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_9ef.parquet")))
saeb <- saeb[in_publica == 1 & !is.na(proficiencia_lp_saeb) & !is.na(inse_aluno)]
saeb[, raca := fcase(
  tx_resp_q04 %in% c("A", "D"), "branca",
  tx_resp_q04 %in% c("B", "C"), "preta"
)]
saeb <- saeb[raca %in% c("branca", "preta")]

## quintis de INSE; a interseção é lida nos extremos: Q1 (mais pobre) e Q5 (mais rico)
saeb[, inse_q := cut(inse_aluno,
                     breaks = quantile(inse_aluno, probs = seq(0, 1, 0.2), na.rm = TRUE),
                     include.lowest = TRUE, labels = paste0("Q", 1:5))]
d <- saeb[inse_q %in% c("Q1", "Q5")]
d[, classe := fifelse(inse_q == "Q5", "rico", "pobre")]

ag <- d[, .(prof = mean(proficiencia_lp_saeb), n = .N), by = .(raca, classe)]
cel <- function(rc, cl) list(
  prof = round(ag[raca == rc & classe == cl, prof]),
  n    = ag[raca == rc & classe == cl, n]
)
br <- cel("branca", "rico");  bp <- cel("branca", "pobre")
pr <- cel("preta",  "rico");  pp <- cel("preta",  "pobre")

gap_ricos  <- br$prof - pr$prof     # diferença racial entre os mais ricos
gap_pobres <- bp$prof - pp$prof     # diferença racial entre os mais pobres

L3 <- list(
  meta = list(
    leitura = "L3",
    titulo_curto = "Raça e classe não se somam, se cruzam",
    eyebrow = "Leitura 03 · SAEB 2023 · 9º EF · raça e classe",
    fonte = "SAEB 2023 · microdados aluno · 9º EF · escolas públicas · proficiência em LP por raça/cor (Q04) × quintil de INSE (extremos: Q1 e Q5)",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    branco_rico  = br$prof,
    branco_pobre = bp$prof,
    preto_rico   = pr$prof,
    preto_pobre  = pp$prof,
    gap_ricos    = gap_ricos,
    gap_pobres   = gap_pobres,
    n_preto_pobre_mil  = round(pp$n / 1000),
    n_branco_pobre_mil = round(bp$n / 1000)
  ),
  viz = list(
    indicador = "Proficiência média em LP no 9º ano (pontos SAEB)",
    corte_adequado = ADEQ_LP_9EF,
    grupos = list(
      list(rotulo = "Entre os estudantes mais ricos",
           preto = pr$prof, branco = br$prof, gap = gap_ricos,
           n_preto = pr$n, n_branco = br$n),
      list(rotulo = "Entre os estudantes mais pobres",
           preto = pp$prof, branco = bp$prof, gap = gap_pobres,
           n_preto = pp$n, n_branco = bp$n)
    ),
    anotacao = sprintf("A diferença racial não é fixa: %d pontos entre os ricos, %d entre os pobres",
                       gap_ricos, gap_pobres)
  )
)

write_json(L3, file.path(DIR_AGG, "L3.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L3 ✓ | branco-rico %d · preto-rico %d · branco-pobre %d · preto-pobre %d | dif racial: ricos %d / pobres %d",
                 br$prof, pr$prof, bp$prof, pp$prof, gap_ricos, gap_pobres))
