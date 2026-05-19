# ============================================================================
# 15_medio_dados.R
# ----------------------------------------------------------------------------
# Calcula as médias ponderadas e a distribuição do SAEB 9º ano matemática
# que alimentam a peça "Médio: confissões de um número em conflito".
#
# Entrada: pipeline/data/raw/saeb_2023/TS_ALUNO_9EF.csv (~1.1 GB)
# Saída:   medio/src/lib/medio-data.json (commitado, leve)
#
# Variáveis-chave do microdado SAEB 2023 (confirmadas no dicionário oficial):
#   PROFICIENCIA_MT_SAEB  proficiência em matemática na escala SAEB
#   PESO_ALUNO_MT         peso amostral pra estimar população
#   IN_PUBLICA            0 = privada, 1 = pública
#   ID_REGIAO             1=N, 2=NE, 3=SE, 4=S, 5=CO
#   TX_RESP_Q04           cor/raça (A branca, B preta, C parda, D amarela, E indígena, F nd)
#   TX_RESP_Q08           escolaridade da mãe (A sem 5º; B até 5º; C EF completo; D EM completo; E superior; F não sei)
#   NU_TIPO_NIVEL_INSE    quintil de nível socioeconômico (1..8)
# ============================================================================

suppressPackageStartupMessages({
  library(data.table)
  library(jsonlite)
})

# ---- 1. Leitura seletiva ----------------------------------------------------
arquivo <- "pipeline/data/raw/saeb_2023/TS_ALUNO_9EF.csv"
cat("Lendo", arquivo, "...\n")

cols <- c("ID_REGIAO", "ID_UF", "IN_PUBLICA",
          "PROFICIENCIA_MT_SAEB", "PESO_ALUNO_MT",
          "TX_RESP_Q04", "TX_RESP_Q08",
          "NU_TIPO_NIVEL_INSE", "INSE_ALUNO")

dt <- fread(arquivo, select = cols, encoding = "Latin-1", showProgress = FALSE)

cat("Linhas brutas:", nrow(dt), "\n")

# ---- 2. Filtro: alunos com proficiência válida em matemática ----------------
dt <- dt[!is.na(PROFICIENCIA_MT_SAEB) & PROFICIENCIA_MT_SAEB > 0 & !is.na(PESO_ALUNO_MT)]
cat("Linhas após filtro de proficiência válida:", nrow(dt), "\n")

# Helper: média ponderada arredondada
wm <- function(x, w) {
  ok <- !is.na(x) & !is.na(w) & w > 0
  if (!any(ok)) return(NA_real_)
  weighted.mean(x[ok], w[ok])
}

# ---- 3. Nacional ------------------------------------------------------------
med_nacional <- wm(dt$PROFICIENCIA_MT_SAEB, dt$PESO_ALUNO_MT)
n_nacional   <- sum(dt$PESO_ALUNO_MT, na.rm = TRUE)
cat("Média nacional 9º EF mat:", round(med_nacional, 1),
    " | n ponderado:", round(n_nacional), "\n")

# ---- 4. Por rede ------------------------------------------------------------
por_rede <- dt[, .(media = wm(PROFICIENCIA_MT_SAEB, PESO_ALUNO_MT),
                   n_amostra = .N,
                   n_pop = round(sum(PESO_ALUNO_MT, na.rm = TRUE))),
               by = IN_PUBLICA]
cat("Por rede:\n"); print(por_rede)

med_privada <- por_rede[IN_PUBLICA == 0, media]
med_publica <- por_rede[IN_PUBLICA == 1, media]

# ---- 5. Por região × rede ---------------------------------------------------
nomes_regiao <- c("1" = "N", "2" = "NE", "3" = "SE", "4" = "S", "5" = "CO")

por_regiao_rede <- dt[, .(media = wm(PROFICIENCIA_MT_SAEB, PESO_ALUNO_MT),
                          n_amostra = .N,
                          n_pop = round(sum(PESO_ALUNO_MT, na.rm = TRUE))),
                      by = .(ID_REGIAO, IN_PUBLICA)]
por_regiao_rede[, regiao := nomes_regiao[as.character(ID_REGIAO)]]
por_regiao_rede[, rede := ifelse(IN_PUBLICA == 1, "publica", "privada")]
setkey(por_regiao_rede, ID_REGIAO, IN_PUBLICA)
cat("Por região × rede:\n"); print(por_regiao_rede)

# Norte público e Sudeste privado pra fala da peça
norte_publico   <- por_regiao_rede[ID_REGIAO == 1 & IN_PUBLICA == 1, media]
sudeste_privado <- por_regiao_rede[ID_REGIAO == 3 & IN_PUBLICA == 0, media]

# Por região agregada (todas as redes)
por_regiao <- dt[, .(media = wm(PROFICIENCIA_MT_SAEB, PESO_ALUNO_MT),
                     n_amostra = .N),
                 by = ID_REGIAO]
por_regiao[, regiao := nomes_regiao[as.character(ID_REGIAO)]]
setkey(por_regiao, ID_REGIAO)

# ---- 6. Interseccional: cor × rede × região × escolaridade da mãe -----------
# Privilegiado: branca (A) + privada (0) + Sul (4) + mãe superior (E)
# Marginalizado: preta (B) + pública (1) + Norte (1) + mãe sem 5º (A)
priv_extremo <- dt[TX_RESP_Q04 == "A" & IN_PUBLICA == 0 &
                   ID_REGIAO == 4 & TX_RESP_Q08 == "E",
                   .(media = wm(PROFICIENCIA_MT_SAEB, PESO_ALUNO_MT),
                     n_amostra = .N)]
marg_extremo <- dt[TX_RESP_Q04 == "B" & IN_PUBLICA == 1 &
                   ID_REGIAO == 1 & TX_RESP_Q08 == "A",
                   .(media = wm(PROFICIENCIA_MT_SAEB, PESO_ALUNO_MT),
                     n_amostra = .N)]
cat("Extremo privilegiado (branca/priv/Sul/mãe superior):", round(priv_extremo$media, 1),
    " | n=", priv_extremo$n_amostra, "\n")
cat("Extremo deprimido (preta/púb/Norte/mãe sem 5º):", round(marg_extremo$media, 1),
    " | n=", marg_extremo$n_amostra, "\n")

# ---- 7. Distribuição (quantis pra "nuvem") ---------------------------------
# 20 quantis = vinte pontos uniformes na distribuição ponderada
peso <- dt$PESO_ALUNO_MT
prof <- dt$PROFICIENCIA_MT_SAEB
ord <- order(prof)
cum <- cumsum(peso[ord]) / sum(peso)
probs <- seq(0.025, 0.975, length.out = 20)
nuvem <- sapply(probs, function(p) prof[ord][which(cum >= p)[1]])
cat("Nuvem (20 quantis):", paste(round(nuvem, 1), collapse = ", "), "\n")

# ---- 8. Saída ---------------------------------------------------------------
saida <- list(
  fonte = "INEP/SAEB 2023, microdados de aluno do 9º ano EF, matemática",
  variavel = "PROFICIENCIA_MT_SAEB (escala SAEB)",
  unidade = "pontos",
  n_alunos = nrow(dt),
  nacional = round(med_nacional, 1),
  rede = list(
    privada = round(med_privada, 1),
    publica = round(med_publica, 1),
    diferenca = round(med_privada - med_publica, 1)
  ),
  regiao = setNames(as.list(round(por_regiao$media, 1)), por_regiao$regiao),
  regiao_rede = lapply(split(por_regiao_rede, por_regiao_rede$ID_REGIAO), function(g) {
    list(
      regiao = g$regiao[1],
      privada = round(g[IN_PUBLICA == 0, media], 1),
      publica = round(g[IN_PUBLICA == 1, media], 1)
    )
  }),
  norte_publico = round(norte_publico, 1),
  sudeste_privado = round(sudeste_privado, 1),
  interseccional = list(
    privilegiado = list(
      cor = "branca", rede = "privada", regiao = "Sul", mae_escolaridade = "superior completo",
      media = round(priv_extremo$media, 1),
      n_amostra = priv_extremo$n_amostra
    ),
    deprimido = list(
      cor = "preta", rede = "publica", regiao = "Norte", mae_escolaridade = "sem 5º ano",
      media = round(marg_extremo$media, 1),
      n_amostra = marg_extremo$n_amostra
    ),
    diferenca = round(priv_extremo$media - marg_extremo$media, 1)
  ),
  nuvem_quantis = round(nuvem, 1),
  gerado_em = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
)

# Garante diretório de saída
dir_saida <- "medio/src/lib"
if (!dir.exists(dir_saida)) dir.create(dir_saida, recursive = TRUE)
arq_saida <- file.path(dir_saida, "medio-data.json")
write_json(saida, arq_saida, pretty = TRUE, auto_unbox = TRUE, digits = 1)
cat("\nJSON gravado em:", arq_saida, "\n")
