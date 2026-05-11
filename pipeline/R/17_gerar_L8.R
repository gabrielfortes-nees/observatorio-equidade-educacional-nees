## 17 — L8 (REESCRITA): % de jovens do 3º EM que declararam ter abandonado ao menos uma vez
## (autodeclaração SAEB 3EM Q20, por raça)
## Limitação importante: quem abandonou de fato JÁ NÃO ESTÁ no SAEB — sub-representa.
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_3em.parquet")))
saeb <- saeb[in_publica == 1]
saeb <- saeb[tx_resp_q20 %in% c("A","B","C") & tx_resp_q04 %in% c("A","B","C","D","E")]

saeb[, ja_abandonou := as.integer(tx_resp_q20 %in% c("B","C"))]
saeb[, abandonou_2x := as.integer(tx_resp_q20 == "C")]
saeb[, raca := fcase(
  tx_resp_q04 == "A", "Brancos",
  tx_resp_q04 == "B", "Pretos",
  tx_resp_q04 == "C", "Pardos",
  tx_resp_q04 == "D", "Amarelos",
  tx_resp_q04 == "E", "Indígenas"
)]
saeb[, raca := factor(raca, levels = c("Brancos","Pardos","Pretos","Amarelos","Indígenas"))]

bars <- saeb[!is.na(raca),
             .(pct_abandono = round(mean(ja_abandonou) * 100, 1),
               pct_2x = round(mean(abandonou_2x) * 100, 1),
               n = .N),
             by = raca][order(raca)]

razao_pretos_brancos <- round(bars$pct_abandono[bars$raca=="Pretos"] /
                              bars$pct_abandono[bars$raca=="Brancos"], 2)
razao_indigenas_brancos <- round(bars$pct_abandono[bars$raca=="Indígenas"] /
                                 bars$pct_abandono[bars$raca=="Brancos"], 2)

L8 <- list(
  meta = list(
    leitura = "L8",
    titulo_curto = "Quem abandonou ao menos uma vez",
    eyebrow = "Leitura 08 · SAEB 2023 · 3º EM · TX_RESP_Q20 (autodeclaração) × raça/cor",
    fonte = "SAEB 2023 — 3º EM, questionário aluno · escolas públicas",
    n_total = nrow(saeb),
    aviso_metodologico = "Microdado aluno-a-aluno do Censo Escolar foi descontinuado pelo INEP em 2022. Esta leitura usa autodeclaração no SAEB do 3º EM — limitada porque quem efetivamente abandonou JÁ NÃO está respondendo o SAEB (sub-representação). A magnitude real é maior. Para a taxa oficial agregada, ver Taxas de Rendimento INEP.",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    pct_brancos = bars$pct_abandono[bars$raca == "Brancos"],
    pct_pardos = bars$pct_abandono[bars$raca == "Pardos"],
    pct_pretos = bars$pct_abandono[bars$raca == "Pretos"],
    pct_indigenas = bars$pct_abandono[bars$raca == "Indígenas"],
    razao_pretos_brancos = razao_pretos_brancos,
    razao_indigenas_brancos = razao_indigenas_brancos
  ),
  viz = list(
    indicador = "% do 3º EM que declarou ter abandonado pelo menos uma vez",
    bars = lapply(seq_len(nrow(bars)), function(i) {
      list(
        label = as.character(bars$raca[i]),
        value = bars$pct_abandono[i],
        valor_2x = bars$pct_2x[i],
        n = bars$n[i]
      )
    }),
    anotacao = sprintf("pretos: %.2f× brancos · indígenas: %.2f× brancos",
                       razao_pretos_brancos, razao_indigenas_brancos)
  )
)

write_json(L8, file.path(DIR_AGG, "L8.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L8 ✓ | pretos %.2f× brancos | indígenas %.2f×",
                 razao_pretos_brancos, razao_indigenas_brancos))
