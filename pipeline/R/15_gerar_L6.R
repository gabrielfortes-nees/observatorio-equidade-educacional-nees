## 15 — L6 (REESCRITA): "E se a escola não fosse também onde se come?"
## Contrafactual do PNAE (merenda escolar) como infraestrutura de PERMANÊNCIA.
## O PNAE é universal — 99% das escolas públicas. A viz mostra a ESCALA por
## região (matrículas atendidas) e o toggle "sem o programa" zera tudo:
## é literalmente o que o PNAE sustenta. O efeito sobre frequência vem da
## literatura (interrupções por pandemia e atrasos de repasse).
## Base: Censo Escolar 2025.
source("/Users/gabrielfortes/Documents/Claude/Projects/Observatorio_Equidade_Educacional/pipeline/R/00_setup.R")

esc <- as.data.table(read_parquet(file.path(DIR_PROC, "censo_escolar_2025_escola.parquet")))
mat <- as.data.table(read_parquet(file.path(DIR_PROC, "censo_escolar_2025_matricula.parquet")))

esc <- esc[tp_dependencia %in% c(1, 2, 3)]                   # rede pública
d <- merge(esc[, .(co_entidade, sg_uf, in_alimentacao)],
           mat[, .(co_entidade, qt_mat_bas)], by = "co_entidade")

norte <- c("RO","AC","AM","RR","PA","AP","TO")
nord  <- c("MA","PI","CE","RN","PB","PE","AL","SE","BA")
d[, regiao := fcase(
  sg_uf %in% norte, "Norte",
  sg_uf %in% nord,  "Nordeste",
  sg_uf %in% c("MG","ES","RJ","SP"), "Sudeste",
  sg_uf %in% c("PR","SC","RS"), "Sul",
  default = "Centro-Oeste"
)]

## matrículas atendidas pelo PNAE, por região
por_reg <- d[in_alimentacao == 1,
             .(mat_pnae = sum(qt_mat_bas, na.rm = TRUE)), by = regiao]
ordem_reg <- c("Sudeste", "Nordeste", "Sul", "Norte", "Centro-Oeste")
por_reg <- por_reg[match(ordem_reg, regiao)]

total_pnae   <- d[in_alimentacao == 1, sum(qt_mat_bas, na.rm = TRUE)]
total_publica <- d[, sum(qt_mat_bas, na.rm = TRUE)]
pct_cobertura <- total_pnae / total_publica * 100

bars <- lapply(seq_len(nrow(por_reg)), function(i) {
  list(
    label = por_reg$regiao[i],
    real  = round(por_reg$mat_pnae[i] / 1e6, 2),   # milhões de matrículas com merenda
    off   = 0,                                     # sem o PNAE: zero
    color_key = c("orange","orangeSoft","brown","counterfactual","orange")[i]
  )
})

L6 <- list(
  meta = list(
    leitura = "L6",
    titulo_curto = "A merenda como âncora de permanência",
    eyebrow = "Leitura 06 · Contrafactual · Programa Nacional de Alimentação Escolar (PNAE)",
    fonte = "Censo Escolar 2025 — IN_ALIMENTACAO × matrículas da rede pública · efeito sobre frequência ancorado na literatura sobre interrupções do PNAE",
    contrafactual = TRUE,
    cf_key = "pnae",
    evidencia = "A cobertura do PNAE é dado direto do Censo Escolar 2025. O efeito sobre frequência escolar vem da literatura (estudos sobre pandemia e atrasos de repasse) — selo: evidência forte para frequência/permanência, não para nota.",
    gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  ),
  narrativa = list(
    total_pnae_milhoes = round(total_pnae / 1e6, 1),
    pct_cobertura = round(pct_cobertura, 1),
    queda_frequencia_lo = 3,
    queda_frequencia_hi = 9
  ),
  viz = list(
    indicador = "Matrículas da rede pública atendidas pelo PNAE (milhões)",
    titulo_real = "Com o PNAE — a refeição garantida na escola",
    titulo_off  = "Sem o PNAE — a âncora que desaparece",
    bars = bars,
    callout = sprintf("O PNAE alcança %.1f milhões de estudantes — %.1f%% da rede pública. Em regiões de insegurança alimentar, é a refeição mais garantida do dia da criança. A literatura sobre interrupções do programa (pandemia, atrasos de repasse) associa a falta da merenda a quedas de 3 a 9 pontos percentuais na frequência escolar.",
                      total_pnae / 1e6, pct_cobertura)
  )
)

write_json(L6, file.path(DIR_AGG, "L6.json"), pretty = TRUE, auto_unbox = TRUE)
cat_step(sprintf("L6 ✓ | PNAE: %.1f mi matrículas (%.1f%% da rede pública)",
                 total_pnae / 1e6, pct_cobertura))
