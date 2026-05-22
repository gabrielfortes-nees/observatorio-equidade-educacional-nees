## 12 — L3 (REESCRITA 4): "Raça e classe não se somam, se cruzam"
## A interseção raça × classe em quatro posições, no 9º ano: estudantes brancos
## e pretos/pardos, no quintil mais rico e no mais pobre de INSE.
## A desvantagem racial não tem tamanho fixo — depende da classe. O cenário
## "E se..." mostra por quê: o degrau de classe é racializado. Subir de renda
## rende menos aprendizado para o estudante negro; se rendesse igual, a
## diferença racial no topo cairia pela metade.
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

## retorno da ascensão social: quanto se ganha ao subir do quintil mais pobre
## ao mais rico. É diferente por raça — o degrau de classe é racializado.
retorno_branco <- br$prof - bp$prof
retorno_preto  <- pr$prof - pp$prof

## cenário "E se...": e se subir de renda rendesse o mesmo, qualquer que seja
## a raça? O estudante preto e rico partiria do preto-pobre e ganharia o mesmo
## que o branco ganha ao subir de renda.
preto_rico_cf <- pp$prof + retorno_branco
gap_ricos_cf  <- br$prof - preto_rico_cf

grupo <- function(rotulo, preto, branco, n_preto, n_branco, preto_cf) list(
  rotulo   = rotulo,
  preto    = preto,
  branco   = branco,
  gap      = branco - preto,
  preto_cf = preto_cf,
  gap_cf   = branco - preto_cf,
  n_preto  = n_preto,
  n_branco = n_branco
)

L3 <- list(
  meta = list(
    leitura = "L3",
    titulo_curto = "Raça e classe não se somam, se cruzam",
    eyebrow = "Leitura 03 · E se… · SAEB 2023 · 9º EF · raça e classe",
    fonte = "SAEB 2023 · microdados aluno · 9º EF · escolas públicas · proficiência em LP por raça/cor (Q04) × quintil de INSE (extremos: Q1 e Q5) · cenário de retorno da ascensão social",
    cenario = TRUE,
    cf_key = "mobilidade",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    branco_rico  = br$prof,
    branco_pobre = bp$prof,
    preto_rico   = pr$prof,
    preto_pobre  = pp$prof,
    gap_ricos    = gap_ricos,
    gap_pobres   = gap_pobres,
    retorno_branco = retorno_branco,
    retorno_preto  = retorno_preto,
    preto_rico_cf  = preto_rico_cf,
    gap_ricos_cf   = gap_ricos_cf,
    n_preto_pobre_mil  = round(pp$n / 1000),
    n_branco_pobre_mil = round(bp$n / 1000)
  ),
  viz = list(
    indicador = "Proficiência média em LP no 9º ano (pontos SAEB)",
    corte_adequado = ADEQ_LP_9EF,
    grupos = list(
      grupo("Entre os estudantes mais ricos",  pr$prof, br$prof, pr$n, br$n, preto_rico_cf),
      grupo("Entre os estudantes mais pobres", pp$prof, bp$prof, pp$n, bp$n, pp$prof)
    ),
    anotacao    = sprintf("A diferença racial não é fixa: %d pontos entre os ricos, %d entre os pobres",
                          gap_ricos, gap_pobres),
    anotacao_cf = sprintf("Com retorno igual à ascensão social, a diferença racial fica em %d pontos nos dois grupos",
                          gap_ricos_cf)
  )
)

write_json(L3, file.path(DIR_AGG, "L3.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L3 ✓ | dif racial: ricos %d / pobres %d | retorno: branco +%d / preto +%d | cenário: preto-rico %d->%d",
                 gap_ricos, gap_pobres, retorno_branco, retorno_preto, pr$prof, preto_rico_cf))
