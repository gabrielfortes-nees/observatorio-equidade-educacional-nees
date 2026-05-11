## 14 — L5: tempo doméstico + trabalho fora + infra + clima
## Ordem fixa em todos os quadrantes: ♂brancos → ♀brancas → ♂pretos/pardos → ♀pretas/pardas
## (do mais privilegiado ao mais marginalizado — contraste claro)
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

saeb <- as.data.table(read_parquet(file.path(DIR_PROC, "saeb_2023_9ef.parquet")))
esc  <- as.data.table(read_parquet(file.path(DIR_PROC, "censo_escolar_2025_escola.parquet")))

saeb <- saeb[in_publica == 1 &
             tx_resp_q01 %in% c("A","B") &
             tx_resp_q04 %in% c("A","B","C","D","E")]

## grupo: ♂brancos/amarelos, ♀brancas/amarelas, ♂pretos/pardos, ♀pretas/pardas
saeb[, grupo := fcase(
  tx_resp_q01 == "A" & tx_resp_q04 %in% c("A","D"), "Meninos brancos",
  tx_resp_q01 == "B" & tx_resp_q04 %in% c("A","D"), "Meninas brancas",
  tx_resp_q01 == "A" & tx_resp_q04 %in% c("B","C"), "Meninos pretos/pardos",
  tx_resp_q01 == "B" & tx_resp_q04 %in% c("B","C"), "Meninas pretas/pardas"
)]
saeb <- saeb[!is.na(grupo)]

ordem_fixa <- c("Meninos brancos", "Meninas brancas",
                "Meninos pretos/pardos", "Meninas pretas/pardas")

## ---------- Q21c: horas semanais de trabalho doméstico ----------
## SAEB 9EF Q21c — A: nada, B: <1h, C: 1-2h, D: 3-5h, E: 5+
horas_q21c <- c(A = 0, B = 0.5, C = 1.5, D = 4, E = 6)
saeb[, q21c_h_dia := horas_q21c[tx_resp_q21c]]
q1 <- saeb[!is.na(q21c_h_dia), .(media = round(mean(q21c_h_dia) * 7, 1)), by = grupo]
q1 <- q1[match(ordem_fixa, grupo)]

## ---------- Q21d: horas trabalho fora de casa (semanal) ----------
horas_q21d <- c(A = 0, B = 0.5, C = 1.5, D = 4, E = 6)
saeb[, q21d_h_dia := horas_q21d[tx_resp_q21d]]
q2 <- saeb[!is.na(q21d_h_dia), .(media = round(mean(q21d_h_dia) * 7, 1)), by = grupo]
q2 <- q2[match(ordem_fixa, grupo)]

## ---------- Q23: sensação de pertencimento/segurança (escala 1-4, média 9 itens) ----------
q23_to_num <- function(x) c(A=4, B=3, C=2, D=1)[x]
saeb[, paste0("q23", letters[1:9], "_n") := lapply(.SD, q23_to_num),
     .SDcols = paste0("tx_resp_q23", letters[1:9])]
saeb[, seguranca := rowMeans(.SD, na.rm = TRUE),
     .SDcols = paste0("q23", letters[1:9], "_n")]
q4 <- saeb[!is.na(seguranca), .(media = round(mean(seguranca, na.rm = TRUE), 2)), by = grupo]
q4 <- q4[match(ordem_fixa, grupo)]

## ---------- Infra: % escolas sem banheiro PNE por localização ----------
loc_lbl <- c("1" = "Urbana", "2" = "Rural")
esc[, loc := loc_lbl[as.character(tp_localizacao)]]
q3 <- esc[!is.na(loc) & !is.na(in_banheiro_pne),
          .(sem_pne_pct = round(mean(in_banheiro_pne == 0) * 100, 1),
            n_escolas = .N),
          by = loc][order(-sem_pne_pct)]

## --------- monta JSON ---------
L5 <- list(
  meta = list(
    leitura = "L5",
    titulo_curto = "Permanência é quatro coisas ao mesmo tempo",
    eyebrow = "Leitura 05 · SAEB 2023 9º EF (Q21c, Q21d, Q23a-i) + Censo Escolar 2025 (infra × localização)",
    fonte = "SAEB 2023 — uso do tempo e clima escolar · Censo Escolar 2025 — IN_BANHEIRO_PNE × TP_LOCALIZACAO",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    horas_meninos_brancos = q1$media[1],
    horas_meninas_brancas = q1$media[2],
    horas_meninos_pretos  = q1$media[3],
    horas_meninas_pretas  = q1$media[4],
    diff_meninas_pretas_meninos_brancos = round(q1$media[4] - q1$media[1], 1),
    seg_meninos_brancos = q4$media[1],
    seg_meninas_pretas  = q4$media[4],
    sem_pne_rural   = q3$sem_pne_pct[grep("Rural",   q3$loc)],
    sem_pne_urbana  = q3$sem_pne_pct[grep("Urbana", q3$loc)]
  ),
  viz = list(
    q1_titulo = "1. HORAS SEMANAIS DE TRABALHO DOMÉSTICO",
    q1_dados  = lapply(seq_len(nrow(q1)), function(i) list(label = q1$grupo[i], v = q1$media[i])),
    q2_titulo = "2. HORAS SEMANAIS DE TRABALHO FORA DE CASA",
    q2_dados  = lapply(seq_len(nrow(q2)), function(i) list(label = q2$grupo[i], v = q2$media[i])),
    q3_titulo = "3. % ESCOLAS SEM BANHEIRO PNE — POR LOCALIZAÇÃO",
    q3_dados  = lapply(seq_len(nrow(q3)), function(i) list(label = q3$loc[i], v = q3$sem_pne_pct[i])),
    q4_titulo = "4. SENTIMENTO DE SEGURANÇA NA ESCOLA (esc. 1–4)",
    q4_dados  = lapply(seq_len(nrow(q4)), function(i) list(label = q4$grupo[i], v = q4$media[i]))
  )
)

write_json(L5, file.path(DIR_AGG, "L5.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L5 ✓ | trabalho dom. ♂B=%.1fh → ♀PP=%.1fh | segurança ♂B=%.2f → ♀PP=%.2f",
                 q1$media[1], q1$media[4], q4$media[1], q4$media[4]))
