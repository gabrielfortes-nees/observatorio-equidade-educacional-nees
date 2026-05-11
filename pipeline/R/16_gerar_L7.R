## 16 — L7: reprovação (Q19) como porta do abandono (Q20) — SAEB 9º EF
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_9ef.parquet")))
saeb <- saeb[in_publica == 1]
saeb <- saeb[tx_resp_q19 %in% c("A","B","C") & tx_resp_q20 %in% c("A","B","C")]

## abandono ≥ 1 vez
saeb[, ja_abandonou := as.integer(tx_resp_q20 %in% c("B","C"))]
saeb[, reprov_cat := fcase(
  tx_resp_q19 == "A", "Nunca foi reprovado",
  tx_resp_q19 == "B", "Reprovou 1 vez",
  tx_resp_q19 == "C", "Reprovou 2+ vezes"
)]
saeb[, reprov_cat := factor(reprov_cat, levels = c("Nunca foi reprovado","Reprovou 1 vez","Reprovou 2+ vezes"))]

bars <- saeb[, .(pct_abandono = round(mean(ja_abandonou) * 100, 1),
                  n = .N),
              by = reprov_cat][order(reprov_cat)]

razao <- round(bars$pct_abandono[2] / bars$pct_abandono[1], 2)
razao_alta <- round(bars$pct_abandono[3] / bars$pct_abandono[1], 2)

L7 <- list(
  meta = list(
    leitura = "L7",
    titulo_curto = "Reprovação como porta do abandono",
    eyebrow = "Leitura 07 · SAEB 2023 · 9º ano · Q19 (reprovação) × Q20 (abandono)",
    fonte = "SAEB 2023 — TX_RESP_Q19 × TX_RESP_Q20 · escolas públicas · razão de chances por tabela de contingência",
    n_total = nrow(saeb),
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    razao_chance_1x = razao,
    razao_chance_2x = razao_alta,
    pct_abandono_nunca_reprov = bars$pct_abandono[1],
    pct_abandono_1x = bars$pct_abandono[2],
    pct_abandono_2x = bars$pct_abandono[3]
  ),
  viz = list(
    indicador = "% que declaram ter abandonado pelo menos uma vez",
    bars = lapply(seq_len(nrow(bars)), function(i) {
      list(
        label = as.character(bars$reprov_cat[i]),
        value = bars$pct_abandono[i],
        n = bars$n[i]
      )
    }),
    anotacao = sprintf("%.1f× chance", razao)
  )
)

write_json(L7, file.path(DIR_AGG, "L7.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L7 ✓ | razão 1× = %.2fx | razão 2+× = %.2fx", razao, razao_alta))
