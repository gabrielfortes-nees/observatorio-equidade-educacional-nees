# Brief metodológico — I-MAIHDA exploratório · SAEB 2023

> Documento de handoff para discussão e levantamento de literatura.
> Análise rodada em: NEES/UFAL · Observatório de Equidade Educacional.
> Referência metodológica: Evans, Leckie, Subramanian, Bell & Merlo (2024).

---

## 1. Contexto

Aplicação de **Intersectional MAIHDA (I-MAIHDA)** aos microdados aluno do SAEB 2023 (Brasil), em busca de mensurar:
(a) quanto da variabilidade na proficiência se concentra em posições interseccionais (raça × sexo × classe);
(b) se essa variabilidade tem natureza aditiva ou interaccional;
(c) como esses padrões variam por etapa escolar e disciplina.

Se publicado, este parece ser um dos primeiros (talvez o primeiro) estudo I-MAIHDA aplicado a desempenho escolar na educação básica brasileira — a confirmar em revisão bibliográfica.

---

## 2. População e dados

- **Fonte:** SAEB 2023, microdados aluno (TS_ALUNO_5EF.csv, TS_ALUNO_9EF.csv, TS_ALUNO_34EM.csv). INEP/MEC, dados públicos.
- **Universo:** estudantes avaliados em 5º EF, 9º EF e 3º EM, redes pública e privada.
- **Recorte analítico após exclusões:** estudantes com raça autodeclarada Branca, Parda ou Preta (Q04 = A, B, C); sexo Masculino ou Feminino (Q01 = A, B); INSE_aluno não faltante; rede definida (IN_PUBLICA).
- **Excluídos** (motivos): raça Amarela e Indígena (fronteira categorial complexa no Brasil, N pequeno para estimação de random effects estável); sexo "não declara"; respostas faltantes nas variáveis-chave.
- **N final por etapa:** 5º EF = 1.666.309 · 9º EF = 1.793.942 · 3º EM = 1.338.351.

---

## 3. Variáveis

| Tipo | Variável | Operacionalização |
|---|---|---|
| Outcome | Proficiência LP (contínua, escala SAEB 0-500) | `proficiencia_lp_saeb` |
| Outcome | Proficiência MT (contínua, escala SAEB 0-500) | `proficiencia_mt_saeb` |
| Estrato (raça) | Raça/cor autodeclarada | 3 categorias: Branca, Parda, Preta |
| Estrato (sexo) | Sexo | 2 categorias: Feminino, Masculino |
| Estrato (classe) | Tercil de INSE_aluno | 3 categorias: Baixo, Médio, Alto. Cortes pooled nas 3 etapas (cortes: ≤4,56 / 4,56–5,33 / >5,33) |
| Covariada fixa | Rede | Pública × Privada (binária) |

**Estratos interseccionais:** 3 × 2 × 3 = **18**. Sweet spot Merlo (entre 10-100).

**Decisão sobre região:** removida do modelo. Multicolinearidade com INSE (Norte/NE concentram INSE Baixo) e com rede (privadas concentram-se em SE/Sul) gerava ofuscamento dos efeitos focais. Sensibilidade indicada como apêndice (variação <1pp em VPC e PCV).

---

## 4. Desenho dos modelos

Para cada combinação **etapa × disciplina** (6 modelos):

- **M1A (nulo):** `lmer(prof ~ 1 + (1 | estrato), REML=TRUE)`
- **M1B (aditivo):** `lmer(prof ~ raca + sexo + inse_tercil + rede + (1 | estrato), REML=TRUE)`

Software: R 4.x · `lme4` · `broom.mixed`. Tempo de execução: ~70s total.

### Métricas

- **VPC (Variance Partition Coefficient):** σ²u / (σ²u + σ²e) do M1A. Quanto da variância está no nível de estrato interseccional.
- **PCV (Proportional Change in Variance):** (σ²u_M1A − σ²u_M1B) / σ²u_M1A. Quanto da variância entre estratos é explicada pelos efeitos principais aditivos.
- **DA (Discriminatory Accuracy):** AUC do predicted M1A (intercept + uj) contra outcome dicotomizado em "Adequado +" (corte oficial INEP).

### Limiares de interpretação (Bell, Holman & Jones 2019 · Merlo 2018)

- **VPC:** <1% trivial · 1-5% modesto · ≥5% substantivo.
- **PCV:** >80% predominantemente aditivo · 50-80% misto · <50% predominantemente interaccional.
- **AUC:** 0,5-0,6 trivial · 0,6-0,7 modesto · ≥0,7 substantivo.

---

## 5. Perguntas de pesquisa e hipóteses

| RQ | H0 | H1 (esperada) | Métrica |
|---|---|---|---|
| **RQ 1** Magnitude da desigualdade interseccional | VPC < 1% (trivial) | VPC ≥ 5% em ≥ 4 modelos | VPC do M1A |
| **RQ 2** Aditiva ou interaccional? | PCV ≥ 80% (aditiva) | PCV < 80% em ≥ 4 modelos (interaccional substantiva) | PCV |
| **RQ 3** Trajetória ao longo da educação básica | VPC estável | VPC cresce: 5EF < 9EF < 3EM | VPC por etapa |
| **RQ 4** Diferença entre disciplinas | VPC LP ≈ VPC MT | VPC MT > VPC LP em ≥ 2 etapas | VPC por disciplina |
| **RQ 5** Estratos extremos (exploratório) | — | "preta + feminino + INSE_Baixo" entre os mais desvantajados | uj com IC |
| **RQ 6** Discriminatory Accuracy | AUC ≤ 0,60 | AUC ≥ 0,70 em ≥ 4 modelos | AUC vs Adequado+ |

---

## 6. Resultados

| Modelo | n | VPC M1A | PCV | VPC M1B residual | % Adequado+ | AUC |
|---|---:|---:|---:|---:|---:|---:|
| 5º EF · LP | 1.666.309 | **8,42%** | 95,89% | 0,38% | 41,4% | 0,631 |
| 5º EF · MT | 1.666.309 | **8,80%** | 94,66% | 0,51% | 47,5% | 0,642 |
| 9º EF · LP | 1.793.942 | **8,09%** | 97,71% | 0,20% | 38,4% | 0,634 |
| 9º EF · MT | 1.793.942 | **5,86%** | 95,92% | 0,26% | 18,2% | 0,641 |
| 3º EM · LP | 1.338.351 | **5,95%** | 96,28% | 0,24% | 17,2% | 0,624 |
| 3º EM · MT | 1.338.351 | **4,63%** | 95,12% | 0,24% | **5,6%** | 0,671 |

**Observação destacável:** o % Adequado+ no 3º EM · MT despenca para **5,6%** (vs 47,5% no 5º EF · MT). Esse colapso ancora empiricamente o argumento sobre efeito de piso na MT e necropolítica curricular — vale destaque na Discussão.

### 6.1 Composição da coorte muda visivelmente entre etapas (Tabela 1)

| | 5º EF | 9º EF | 3º EM | Δ |
|---|---:|---:|---:|---:|
| % Branca | 32,6 | 33,9 | 37,5 | **+4,9 pp** |
| % Parda  | 53,9 | 51,2 | 47,1 | **−6,8 pp** |
| % Preta  | 13,6 | 15,0 | 15,4 | +1,8 pp |
| % Feminino | 49,8 | 50,1 | 53,4 | **+3,6 pp** |
| % INSE Baixo | 32,8 | 32,1 | 37,2 | +4,4 pp |

Pardos perdem 6,8 pp de representação até o 3º EM; femininas ganham 3,6 pp (hiato reverso de gênero clássico). Dado descritivo que sustenta a leitura de sobrevivência diferencial — ainda que a reponderação composicional (10.1) mostre que **a queda do VPC não é explicada por composição**, a composição em si muda significativamente.

### 6.2 Achado interseccional residual: Preta · Masc · Alto resiste à compensação por SES em LP no EM (Tabela 4)

O ranking dos estratos extremos revela um padrão chamativo que sobrevive ao colapso aditivo do PCV ~95%:

- **9º EF · LP:** Preta · Masculino · **Alto** = 240,9 → entre os 5 mais desvantajados, abaixo até de Parda · Masculino · Baixo (237,5)
- **3º EM · LP:** Preta · Masculino · **Alto** = 261,4 → mesma posição
- Em MT, esse efeito desaparece — Preta · Masc · Alto migra para o centro do ranking

**Leitura teórica:** alto status socioeconômico **não compensa** o entrelaçamento raça·masculinidade na proficiência em LP no EM. Isso é o resíduo de interseccionalidade que não é capturado por aditividade — exatamente o tipo de achado que a Figura 2 (scatter u_M1A vs u_M1B) torna visual: a maioria dos pontos colapsa para y≈0 (aditividade), mas alguns persistem fora. **Preta · Masc · Alto em LP é o resíduo mais consistente.** Vale uma frase de destaque na Discussion: *"o privilégio de classe não cancela a desvantagem racial-masculina em LP no EM — o resíduo do M1B mostra o limite empírico da leitura aditiva"*.

---

## 7. Veredito por hipótese

| H | Veredito | Direção |
|---|---|---|
| **H1** Magnitude | **CONFIRMADA (parcial)** — 5/6 acima de 5% | esperada |
| **H2** Interaccional | **REJEITADA** — PCV 94,7-97,7%, todos predominantemente aditivos | oposta |
| **H3** Trajetória | **REJEITADA** — VPC decresce ao longo das etapas | oposta |
| **H4** Disciplina | **REJEITADA** — VPC LP > VPC MT no 9EF e 3EM | oposta |
| **H5** Estratos extremos | **CONFIRMADA** — Preta/Feminino/Baixo no piso (MT), Preta/Masculino/Baixo no piso (LP), Branca/Feminino/Alto no topo. **Achado adicional:** Preta · Masc · Alto resiste à compensação por SES em LP no EM (ver 6.2) | esperada + |
| **H6** DA | **REJEITADA** — AUC entre 0,62-0,67, modesto | atenuada |

Quatro rejeições (H2, H3, H4, H6), duas confirmadas (H1, H5). Forte estrutura de discussão, com H5 expandida pelo achado adicional Preta · Masc · Alto.

---

## 8. Achados-síntese

> A interseccionalidade na educação básica brasileira (SAEB 2023) é **mensurável e substantiva** (VPC 5-9% do M1A), **predominantemente aditiva** (PCV ~95%), **decresce ao longo da trajetória escolar** (provavelmente por sobrevivência seletiva, não equalização), e é **mais marcada em LP que em MT** no Ensino Médio (efeito de piso na MT). A posição interseccional **discrimina modestamente** o desempenho individual (AUC 0,62-0,67).

### Caveats metodológicos centrais

1. **PCV alto não nega interseccionalidade — é um achado intercategorial.** O resultado indica que, no nível populacional do desempenho médio, os efeitos médios de raça, sexo e classe se combinam quase aditivamente *sob a métrica usada* (proficiência SAEB) e *na coorte observada* (estudantes que chegaram à etapa avaliada). A interseccionalidade como fenômeno qualitativo da experiência cotidiana — humilhações racializadas em sala, assédio sexual no trajeto, dupla jornada doméstica das meninas pobres, racismo na correção de redações, expectativa diferenciada do professor — pode estar plenamente operante e ainda assim aparecer somada no escore final. Em termos de McCall (2005), o que o MAIHDA captura é a abordagem **intercategorial** (mapeia desigualdades *entre* grupos pré-definidos). Ele não captura a complexidade **intracategorial** (heterogeneidade *dentro* de cada estrato) nem a **anticategorial** (desconstrução das próprias categorias). Por isso, dizer "a interseccionalidade brasileira é aditiva" seria um excesso — o que é aditivo é a manifestação dela em uma métrica específica, sob um modelo específico, num desfecho específico. Bowleg (2008) tem a formulação clássica deste paradoxo: *Black + Lesbian + Woman ≠ Black Lesbian Woman*.

2. **Queda de VPC ao longo das etapas: necropolítica escolar e os apagados.** A análise de controle 10.1 mostrou que **a reponderação composicional não explica a queda do VPC** — mesmo simulando a distribuição de estratos do 5EF, o VPC no 3EM permanece em ~5.9% (LP) e ~4.6% (MT). Isso reforça, não enfraquece, a leitura crítica: a queda **não** se deve a uma mera redistribuição entre estratos, mas plausivelmente a uma homogeneização intra-estrato — quem sobrevive de "Preta · Masc · Baixo" até o 3EM é diferente da média do estrato no 5EF. A coorte do 3EM é uma coorte filtrada. O abandono escolar é diferencialmente concentrado em estudantes pretos/pardos, INSE Baixo, Norte/NE; ele opera como **um dispositivo de seleção que produz a homogeneidade aparente da variância**. Lido na chave de Mbembe (necropolítica), Almeida (racismo estrutural) e Carvalho (educação como racialização institucional), o achado deve ser narrado assim: a escola brasileira não equaliza interseccionalidade — ela expulsa diferencialmente, e o que resta no 3EM é a sombra estatística desse processo. Acrescente-se a isso os **apagados pelo desenho**: estudantes Indígenas e Amarelos foram excluídos do modelo por exigência técnica (N pequeno, fronteira categorial complexa), mas essa exclusão é, ela mesma, dado interseccional — repete no modelo a invisibilização que opera na política educacional. **Ambos os apagamentos (pelo funil escolar e pelo desenho do estudo) merecem leitura interseccional explícita na Discussão.**

3. **VPC MT < VPC LP em etapas finais — efeito de piso e capital cultural.** Hipótese explicativa post-hoc: efeito de piso em MT (quase ninguém aprende matemática suficientemente bem, apagando a estrutura entre estratos), enquanto LP mantém diferenciação interseccional porque o português culto é, como Bourdieu argumentou e Patto reapropriou para o Brasil, um marcador de pertencimento que distingue por capital cultural racializado e classista. Precisa investigação adicional (quantile regression em LP/MT pode mostrar se a diferenciação interseccional se desloca para a cauda superior em MT, escondida pela compressão no piso).

4. **DA modesta (AUC ~0,65): anti-essencialismo e universalização.** A discriminatory accuracy entre 0,62 e 0,67 é, teoricamente, um achado bem-vindo. Significa que **conhecer a posição interseccional condiciona, mas não determina o desempenho individual**. Isso protege a análise contra leituras essencialistas ou deterministas — exatamente a crítica que QuantCrit (Gillborn et al. 2018) faz ao uso ingênuo de raça em modelos estatísticos. Ancora teoricamente em Brah (1996) — diáspora como posicionalidade, não essência; Hall (1996) — identidade como articulação, não fechamento; e Carneiro — recusa da monocultura focalista. **Politicamente, o argumento que se constrói é: focalização interseccional sem universalização da qualidade reproduz a desigualdade que diz combater.** Em chave de Fraser (1995, 2000), política educacional precisa articular redistribuição (piso universal: currículo, formação docente, infraestrutura, alimentação, transporte) **e** reconhecimento (das posições estruturais). A interseccionalidade aqui não opera como critério de focalização, mas como **lente de avaliação da qualidade do universal**: uma escola que funciona apenas para alguns estratos é, por definição, de baixa qualidade.

---

## 8.5 Moldura interpretativa: o que a partição de variância não vê

Os três caveats acima convergem para uma posição teórica que precisa ficar explícita na Discussão. O MAIHDA é uma ferramenta poderosa para responder uma pergunta específica: *quanto da variação em um desfecho está estruturada entre posições interseccionais e quanto é explicado por efeitos marginais aditivos*. Essa pergunta é legítima e a resposta empírica (VPC 5-9%, PCV ~95%) é informativa. Mas é uma pergunta intercategorial, populacional, sobre médias. Três coisas ficam fora de seu campo de visão:

**(i) O que está dentro do estrato (intracategorial).** Cada uma das 18 células do nosso modelo contém centenas de milhares de trajetórias singulares. A homogeneização do escore médio dentro de "Parda · Feminino · INSE Baixo" mascara variabilidade brutal de território, configuração familiar, qualidade da escola frequentada, sobrevivência psíquica. McCall chama isso de complexidade intracategorial; Crenshaw (1991) já formulava algo análogo ao mostrar que "mulheres negras" não é uma identidade homogênea mas uma posição estrutural com múltiplas mediações.

**(ii) O que a categoria oculta (anticategorial).** Raça/cor autodeclarada no SAEB (Q04) é uma medida com história — atravessada por embranquecimento, enegrecimento, classificação familiar versus autoclassificação, regionalização (Schwartzman; Telles; Osuji). Sexo binário recusa pessoas não-binárias e trans. Tercis de INSE são uma simplificação radical de classe. As fronteiras dessas categorias não são naturais — são produto histórico. A análise anticategorial pede que tratemos isso como dado, não como ruído.

**(iii) O que foi expelido antes da medição.** A coorte do SAEB é o que sobrou após anos de funil escolar. Quem está fora do dado — quem evadiu, quem foi expulso por reprovação repetida, quem foi excluído do modelo por categoria minoritária — não é silêncio analítico, é evidência de necropolítica. O paper precisa nomear esses ausentes como **ausências constitutivas**, não como amostra perdida.

A síntese normativa que sai daí: nossos achados não são "a interseccionalidade no Brasil é aditiva". São "sob a métrica do desempenho médio em prova padronizada, condicionando a uma coorte progressivamente filtrada pela própria desigualdade que se quer medir, os efeitos marginais de raça, sexo e classe se compõem majoritariamente por adição — e cada uma dessas qualificações é uma porta aberta para a interseccionalidade qualitativa continuar valendo."

---

## 8.6 Estratégias estatísticas complementares (intra e anti-categorial)

Para que o paper não fique refém da abordagem intercategorial, vale sinalizar (e, em momento oportuno, executar) complementos:

**Para o intracategorial:**
- **Latent Class / Profile Analysis (LCA/LPA)** sobre variáveis adicionais do SAEB-aluno (trajetória, território, configuração familiar, escolaridade dos pais separada por figura cuidadora, atraso idade-série) — revela subgrupos *dentro* do mesmo estrato.
- **Quantile regression** dos outcomes LP e MT por estrato — mostra se a desigualdade interseccional se manifesta diferente nas caudas (especialmente útil para o achado VPC MT < VPC LP no EM, dado o efeito de piso).
- **Finite mixture / heteroscedastic models** — coeficientes podem variar dentro de grupo; variância residual pode depender do estrato.
- **BLUPs com dispersão intra-estrato** — no caterpillar plot, reportar não só o ranking dos uj mas também a variância residual *dentro* de cada estrato.
- **Complemento qualitativo** (entrevistas com estudantes de estratos extremos, etnografia escolar, análise de trajetórias singulares) — em McCall, é parte legítima da estratégia intracategorial, não "outro estudo".

**Para o anticategorial:**
- **Sensitivity analysis com categorizações alternativas** — usar Q04 cruzado com pergunta sobre cor da pele (quando disponível em Censo Escolar/PNAD), comparar autoclassificação com classificação heteroatribuída, estimar variação do VPC sob diferentes operacionalizações de raça.
- **Medidas contínuas em vez de categóricas** quando possível — INSE contínuo (já feito como controle), escala de cor da pele, índice de exposição racial do bairro/escola.
- **Reflexividade sobre o instrumento** — Q04 do SAEB é uma pergunta de autodeclaração com sua própria política de produção, não um traço biológico. Tratar a instabilidade da medida como informação substantiva (literatura de embranquecimento/enegrecimento: Schwartzman, Telles, Daflon, Osuji).
- **Modelagem dos apagados** — cruzamento SAEB × Censo Escolar para estimar a coorte plena (incluindo evadidos, Indígenas, Amarelos) e modelar seletivamente quem é medido e quem não é (Heckman selection model como sensibilidade).

---

## 9. Frentes literárias a levantar

**A. MAIHDA — método e aplicações:**
- Evans, Leckie, Subramanian, Bell & Merlo (2024). A tutorial for conducting intersectional multilevel analysis of individual heterogeneity and discriminatory accuracy (MAIHDA). *SSM-Population Health*, 26, 101664.
- Merlo (2018). Multilevel analysis of individual heterogeneity and discriminatory accuracy (MAIHDA) within an intersectional framework. *SSM*.
- Bell, Holman & Jones (2019). Using shrinkage in multilevel models to understand intersectionality. *Methodology*.
- Evans, Williams, Onnela & Subramanian (2018). A multilevel approach to modeling health inequalities at the intersection of multiple social identities. *SSM*.

**B. Interseccionalidade — base teórica (não-quantitativa):**
- Crenshaw (1989). Demarginalizing the intersection of race and sex. *U Chicago Legal Forum*.
- Crenshaw (1991). Mapping the margins: intersectionality, identity politics, and violence against women of color. *Stanford Law Review*.
- Collins, P. H. (1990). *Black Feminist Thought: Knowledge, Consciousness, and the Politics of Empowerment*.
- Collins, P. H. (2015). Intersectionality's definitional dilemmas. *Annual Review of Sociology*.
- hooks, b. (1981). *Ain't I a Woman: Black Women and Feminism*.
- hooks, b. (1984). *Feminist Theory: From Margin to Center*.
- Lugones, M. (2007). Heterosexualism and the colonial/modern gender system. *Hypatia*.
- McCall, L. (2005). The complexity of intersectionality. *Signs*.
- Brah, A. (1996). *Cartographies of Diaspora: Contesting Identities*.
- Hall, S. (1996). Who needs identity? In *Questions of Cultural Identity*.

**B.1 Interseccionalidade no pensamento negro brasileiro:**
- Gonzalez, L. (1984). Racismo e sexismo na cultura brasileira. *Revista Ciências Sociais Hoje*.
- Carneiro, S. (2003). Enegrecer o feminismo: a situação da mulher negra na América Latina a partir de uma perspectiva de gênero. *Racismos contemporâneos*.
- Nascimento, B. (1985). O conceito de quilombo e a resistência cultural negra. *Afrodiáspora*.
- Akotirene, C. (2018). *O que é interseccionalidade?* (Coleção Feminismos Plurais).
- Ribeiro, D. (2017). *O que é lugar de fala?*

**C. Interseccionalidade quantitativa e QuantCrit:**
- Bowleg, L. (2008). When Black + Lesbian + Woman ≠ Black Lesbian Woman: the methodological challenges of qualitative and quantitative intersectionality research. *Sex Roles*.
- Bowleg, L. (2012). The problem with the phrase "Women and minorities": intersectionality. *AJPH*.
- Gillborn, Warmington & Demack (2018). QuantCrit: education, policy, "Big Data" and principles for a critical race theory of statistics. *Race Ethnicity and Education*.
- Tabron & Thomas (2023). Deeper than wordplay: a systematic review of critical quantitative approaches in education research. *Review of Educational Research*.
- Garcia, López & Vélez (2018). QuantCrit: rectifying quantitative methods through critical race theory. *Race Ethnicity and Education*.

**D. Raça, classe e construção das categorias no Brasil:**
- Hasenbalg (1979). *Discriminação e desigualdades raciais no Brasil*.
- Henriques (2001). Desigualdade racial no Brasil: evolução das condições de vida na década de 90. *IPEA*.
- Soares & Alves (2003). Desigualdades raciais no sistema brasileiro de educação básica. *Educação e Pesquisa*.
- Souza, J. (2003). *A construção social da subcidadania*.
- Telles, E. (2003). *Racismo à brasileira: uma nova perspectiva sociológica*.
- Schwartzman, L. F. (2007). Does money whiten? Intergenerational changes in racial classification in Brazil. *American Sociological Review*.
- Daflon, V. (2017). *Tão longe, tão perto: pretos e pardos e o enigma racial brasileiro*.
- Osuji, C. (2013). Confronting whitening in an era of black consciousness. *Ethnic and Racial Studies*.

**E. Necropolítica, racismo estrutural e escola:**
- Mbembe, A. (2003). Necropolitics. *Public Culture*.
- Almeida, S. (2018). *O que é racismo estrutural?*
- Carvalho, M. P. (2004). O fracasso escolar de meninos e meninas: articulações entre gênero e cor/raça. *Cadernos Pagu*.
- Patto, M. H. S. (1990). *A produção do fracasso escolar: histórias de submissão e rebeldia*.
- Anyon, J. (1981). Social class and school knowledge. *Curriculum Inquiry*.

**F. Sobrevivência escolar e seleção de coorte (para Caveat 2):**
- Riani, Silva & Soares (2012). Repetição e evasão escolar no Brasil. *Educação e Pesquisa*.
- Beltrão & Alves (2009). A reversão do hiato de gênero na educação brasileira. *Cadernos de Pesquisa*.
- Fine, M. (1991). *Framing dropouts: notes on the politics of an urban public high school*.
- Heckman, J. (1979). Sample selection bias as a specification error. *Econometrica*.

**G. Efeito de piso, capital cultural e disciplinas (para Caveat 3):**
- Soares & Andrade (2006). Nível socioeconômico, qualidade e equidade nas escolas brasileiras. *Ensaio*.
- Franco & Ortigão (2014). Desafios da matemática no Brasil. *Educação e Realidade*.
- Bourdieu, P. & Passeron, J.-C. (1970). *La reproduction*.

**H. Redistribuição, reconhecimento e política educacional (para Caveat 4):**
- Fraser, N. (1995). From redistribution to recognition? Dilemmas of justice in a "post-socialist" age. *New Left Review*.
- Fraser, N. (2000). Rethinking recognition. *New Left Review*.
- Fraser, N. & Honneth, A. (2003). *Redistribution or recognition? A political-philosophical exchange*.

**I. Métodos complementares ao MAIHDA (intra e anticategorial):**
- Collins, L. M. & Lanza, S. T. (2010). *Latent Class and Latent Transition Analysis*.
- Koenker, R. (2005). *Quantile Regression*.
- Else-Quest & Hyde (2016). Intersectionality in quantitative psychological research. *Psychology of Women Quarterly*.
- Scott, N. A. & Siltanen, J. (2017). Intersectionality and quantitative methods: assessing regression from a feminist perspective. *International Journal of Social Research Methodology*.

---

## 10. Análises de controle (executadas)

### 10.1 Sobrevivência de coorte (controle H3)

**Desenho:** reponderação post-stratification das amostras do 9EF e 3EM para refletir a composição de estratos do 5EF. Peso por estrato = `p_5EF(estrato) / p_etapa(estrato)`. Aplicado via `lmer(weights = w)`. Caveat: `lmer` trata weights como inverso de variância, não como pesos amostrais; estimativa pontual de VPC é informativa, IC requer abordagem survey-weighted.

**Composição muda visivelmente entre etapas:**

| Estrato | razão 3EM/5EF | leitura |
|---|---:|---|
| Parda · Feminino · Alto | 0.68 | mais sub-representado no 3EM |
| Parda · Masculino · Médio | 0.76 | perdeu participação relativa |
| Parda · Feminino · Médio | 0.77 | idem |
| Branca · Feminino · Baixo | 1.50 | cresceu relativamente |
| Preta · Feminino · Baixo | 1.40 | cresceu relativamente |
| Branca · Feminino · Médio | 1.24 | cresceu relativamente |

Faixa dos pesos: 9EF [0.71 — 1.28] · 3EM [0.67 — 1.47].

**VPC reponderado é praticamente idêntico ao bruto:**

| Modelo | VPC 5EF | VPC bruto | VPC reponderado |
|---|---:|---:|---:|
| LP — 9EF | 8.42 | 8.09 | 8.08 |
| LP — 3EM | 8.42 | 5.95 | **5.92** |
| MT — 9EF | 8.80 | 5.86 | 5.86 |
| MT — 3EM | 8.80 | 4.63 | **4.59** |

**Conclusão:** A queda do VPC entre etapas **não é explicada por sobrevivência seletiva composicional**. Mesmo simulando a distribuição de estratos do 5EF, o VPC no 3EM permanece em ~5.9% (LP) e ~4.6% (MT). H3 (decréscimo do VPC) sobrevive ao controle.

**Caveat interpretativo:** o peso corrige composição *entre* estratos, mas não auto-seleção *dentro* de cada estrato. Quem sobrevive de "Preta · Masc · Baixo" até o 3EM é plausivelmente mais resiliente/capaz que a média do estrato no 5EF. Esse é um controle composicional, não de tratamento. A redução real do VPC pode ser homogeneização-por-filtro nessa dimensão intra-estrato — não capturada por reponderação simples.

### 10.2 Robustez (quintis e região)

| Modelo | VPC tercil | PCV tercil | VPC quintil | PCV quintil | VPC +região | PCV +região |
|---|---:|---:|---:|---:|---:|---:|
| 5EF · LP | 8.42 | 95.89 | 8.75 | 95.42 | 8.42 | 96.18 |
| 5EF · MT | 8.80 | 94.66 | 9.19 | 94.19 | 8.80 | 94.99 |
| 9EF · LP | 8.09 | 97.71 | 8.24 | 97.76 | 8.09 | 97.74 |
| 9EF · MT | 5.86 | 95.92 | 5.98 | 96.08 | 5.86 | 96.10 |
| 3EM · LP | 5.95 | 96.28 | 5.99 | 96.31 | 5.95 | 96.34 |
| 3EM · MT | 4.63 | 95.12 | 4.61 | 94.92 | 4.63 | 95.50 |

**Conclusões:**
- **Quintis (30 estratos):** VPC sobe marginalmente (+0.1 a +0.4pp), PCV essencialmente inalterado. Aditividade é robusta à granularidade do componente classe.
- **Região como covariada:** VPC inalterado (região vai para parte fixa, não afeta variância de nível 2), PCV sobe 0.2–0.4pp (região absorve fração trivial da variância entre estratos). Decisão de excluir região do modelo principal é defensável — efeito marginal.

### 10.3 Sensitivity de raça — operacionalização anti-categorial (McCall)

Rodada como resposta à crítica anticategorial da Seção 8.6. Três esquemas comparados:
- **W/Br/Bl:** Branca / Parda / Preta (esquema do paper, 18 estratos)
- **W/Non-W:** Branca / Não-Branca (binarização racializadora, 12 estratos)
- **W/Black-incl-Brown:** Branca / Negra (Parda+Preta) (operacionalização do movimento negro, 12 estratos)

| Modelo | VPC W/Br/Bl | PCV W/Br/Bl | VPC W/Non-W | PCV W/Non-W | VPC W/Black-incl-Br | PCV W/Black-incl-Br |
|---|---:|---:|---:|---:|---:|---:|
| 5º EF · LP | 8,42 | 95,89 | 6,83 | 96,95 | 6,83 | 96,95 |
| 5º EF · MT | 8,80 | 94,66 | 7,47 | 95,76 | 7,47 | 95,76 |
| 9º EF · LP | 8,09 | 97,71 | 7,33 | 98,67 | 7,33 | 98,67 |
| 9º EF · MT | 5,86 | 95,92 | 5,25 | 96,80 | 5,25 | 96,80 |
| 3º EM · LP | 5,95 | 96,28 | 5,66 | 97,78 | 5,66 | 97,78 |
| 3º EM · MT | 4,63 | 95,12 | 4,38 | 97,26 | 4,38 | 97,26 |

**Conclusões:**
- **Direção e magnitude se mantêm** em todas as 6 combinações etapa × disciplina. Achado interseccional é robusto à operacionalização da raça.
- **VPC binarizado ≈ VPC movneg:** o que mudou foi a granularidade (3 → 2 níveis), não a operacionalização. A categoria "Parda" carrega ~0,3 pp de variância adicional entre estratos — pardos e pretos são experiências racializadas distintas que **somam variância** (não cancelam). Validação empírica da posição do movimento negro de não colapsar parda + preta = negra sem perder informação.
- **Argumento empírico anti-essencialista:** o achado interseccional não depende de uma operacionalização específica de raça. Qualquer dos três esquemas encontraria interseccionalidade substantiva (VPC ≥ 4,4 em todos). A categoria não é constitutiva do achado — a hierarquia racializada é.

---

## 11. Tabelas e figuras do paper (geradas, bilíngues)

### 11.1 Pacote em português (NEES/OEE) — `academico/maihda_saeb2023/paper/tabelas/` e `paper/figuras/`

**Tabelas (CSV):**
| Arquivo | Conteúdo | Localização no paper |
|---|---|---|
| T1_caracterizacao_amostra.csv | N, % raça, sexo, INSE, rede, médias por etapa | Métodos · Amostra |
| T2_resultados_M1A_M1B.csv | σ²u, σ²e, VPC, PCV, % Adequado+, AUC dos 6 modelos | Resultados · tabela principal |
| T3_coeficientes_M1B.csv | β, EP, IC95%, t, sig dos efeitos fixos | Resultados · efeitos principais |
| T4_estratos_extremos.csv | Top-5 desv. + Top-5 priv. com uj, IC, sig | Resultados · RQ5 |
| TS_sens_esquemas_raca.csv | VPC/PCV com 3 esquemas de raça | Suplementar · anti-categorial |
| TS0_inventario_exclusoes.csv | Exclusões por motivo (Amarela, Indígena, NA…) | Suplementar · transparência |

**Figuras (PNG 300dpi + PDF vetorial):**
| Arquivo | Conteúdo |
|---|---|
| F1_caterpillar.png/pdf | BLUPs ordenados com IC95%, 6 painéis, cor por raça, shape por sexo |
| F2_scatter_u1A_u1B.png/pdf | Paradoxo da aditividade (M1A vs M1B), pontos colapsam para y≈0 com resíduos visíveis |
| F3_trajetoria_vpc.png/pdf | Queda do VPC ao longo das etapas, bruto e reponderado |
| F4_heatmap.png/pdf | Proficiência média por raça × INSE × sexo, facetado por etapa/disciplina |
| F5_roc.png/pdf | Curvas ROC do M1A vs Adequado+ com AUC anotado |

### 11.2 Pacote em inglês (Race Ethnicity and Education) — `academico/maihda_saeb2023/paper/tables/` e `paper/figures/`

Versão paralela com terminologia de literatura anglo sobre raça no Brasil:
- **White / Brown / Black** para Branca / Parda / Preta (Telles 2004, Bailey 2009)
- **Reading / Math** para LP / MT (convenção PISA/OECD)
- **5th / 9th / 12th grade** para 5º EF / 9º EF / 3º EM
- **SES tertile** para INSE
- **Public / Private** para rede

Captions em inglês explicam decisões de tradução (e.g. "Brown refers to Parda self-identification (mixed-race) in the Brazilian census tradition (Telles 2004)"). Nomes dos arquivos espelham a versão PT.

---

## 12. Decisão de submissão

**Revista-alvo:** *Race Ethnicity and Education* (Taylor & Francis, UK; ed. David Gillborn).

**Justificativa:**
- É a casa do QuantCrit. Gillborn co-editou as referências centrais da Seção 9.C.
- Aderência temática máxima: raça em educação é o objeto.
- Aceita métodos quantitativos sofisticados quando ancorados em leitura crítica — exatamente o perfil deste paper.
- Tração crescente no Brasil. Trabalhos brasileiros já publicados lá.
- Aceitação realista (~25-30%) com paper bem estruturado.

**Plano B (mesmo retrabalho mínimo):** *Education Policy Analysis Archives (EPAA)* — A1, open access, tradição crítica latinoamericana forte, bilíngue.

**Versão simultânea em português (com nota de tradução):** *Ensaio: Avaliação e Políticas Públicas em Educação* (A1, casa específica do SAEB) ou *Educação & Pesquisa* (A1 generalista USP). Verificar política exata de cada uma sobre versão traduzida em segundo idioma.

**Formato de submissão RE&E:** Harvard referencing, ~7.000 palavras, figuras como PDF vetorial (já geradas).

---

## 13. Próximos passos (atualizados)

**Feitos:**
- ✅ Análises de controle (sobrevivência reponderada · 10.1; robustez quintis/região · 10.2; sensitivity de raça · 10.3)
- ✅ Caterpillar plots dos 6 modelos (F1)
- ✅ Listagem dos estratos com uj significativos (T4)
- ✅ Tabelas e figuras paper-ready em PT e EN
- ✅ Decisão de revista-alvo (Race Ethnicity and Education)

**A fazer:**
1. **Revisão de literatura intencionada para uso de escrita** — leitura focal das frentes B, B.1, C, D, E e H (seção 9). Foco: (i) interseccionalidade brasileira (Gonzalez, Carneiro, Akotirene); (ii) McCall e a tríade intercategorial / intracategorial / anticategorial como moldura metodológica; (iii) Bowleg (2008) sobre o paradoxo aditividade × interseccionalidade qualitativa; (iv) necropolítica escolar e seleção de coorte (Mbembe, Almeida, Carvalho, Patto + Riani); (v) Fraser sobre redistribuição + reconhecimento como horizonte normativo.
2. **Considerar análises complementares opcionais da Seção 8.6:** quantile regression em LP/MT como sensibilidade do efeito de piso (especialmente relevante para Caveat 3 e para o achado Preta · Masc · Alto em LP/EM); coorte sintética com Censo Escolar + PNADC para modelar os apagados (Seção 8.5.iii).
3. **Drafting do abstract + estrutura IMRaD**, com Discussão organizada em torno dos quatro caveats expandidos e da síntese normativa anti-essencialista / universalista. Pitch para RE&E.
4. **Cover letter** mencionando o framing QuantCrit + lente brasileira + ineditismo do MAIHDA na educação básica BR. Gillborn responde bem a posicionamento crítico explícito.

1. **Revisão de literatura intencionada para uso de escrita** — leitura focal das frentes B, B.1, C, D, E e H (seção 9) com vistas a construir o aparato teórico-crítico da Introdução e da Discussão. Foco: (i) interseccionalidade brasileira (Gonzalez, Carneiro, Akotirene); (ii) McCall e a tríade intercategorial / intracategorial / anticategorial como moldura metodológica; (iii) Bowleg (2008) sobre o paradoxo aditividade × interseccionalidade qualitativa; (iv) necropolítica escolar e seleção de coorte (Mbembe, Almeida, Carvalho, Patto + Riani); (v) Fraser sobre redistribuição + reconhecimento como horizonte normativo.
2. Caterpillar plots dos 6 modelos (BLUPs com IC 95%).
3. Listagem dos estratos com uj significativos (RQ 5).
4. Discutir caveat de sobrevivência intra-estrato na Discussão (não capturável só por reponderação composicional) — integrar com leitura necropolítica dos apagados (Caveat 2 + Seção 8.5).
5. Considerar análises complementares da Seção 8.6 (quantile regression em LP/MT como sensibilidade do efeito de piso; sensitivity à categorização de raça).
6. Drafting do abstract + estrutura IMRaD, com Discussão organizada em torno dos quatro caveats expandidos e da síntese normativa anti-essencialista / universalista.

---

## 14. Arquivos da análise

### Scripts (pipeline/R/exploracoes/)

| Script | Função |
|---|---|
| `04_maihda_v1.R` | 6 modelos I-MAIHDA (M1A + M1B), AUC, BLUPs |
| `05_maihda_controles.R` | Sobrevivência reponderada + robustez quintis/região (10.1 e 10.2) |
| `06_tabelas_paper.R` | Tabelas T1-T4 + TS_sens + TS0 (PT) |
| `07_figuras_paper.R` | Figuras F1-F5 (PT) |
| `08_figures_paper_en.R` | Figuras F1-F5 (EN — Race Ethnicity and Education) |
| `09_tables_paper_en.R` | Tabelas T1-T4 + TS_sens + TS0 (EN) |

### Resultados intermediários (pipeline/data/processed/)

| Arquivo | Conteúdo |
|---|---|
| `maihda_v1_resultados.rds` | Lista R com 6 modelos completos (coefs tidy + ranking de BLUPs) |
| `maihda_v1_resumo.csv` | Sumário VPC/PCV/VPC_M1B dos 6 modelos |
| `maihda_v1_auc.csv` | AUC + % Adequado+ dos 6 modelos |
| `maihda_v1_composicao_etapas.csv` | Composição de estratos por etapa (% e razões 3EM/5EF) |
| `maihda_v1_sobrevivencia.csv` | VPC bruto vs reponderado (Controle 10.1) |
| `maihda_v1_robustez.csv` | VPC/PCV nas 3 especificações (Controle 10.2) |

### Saídas paper-ready

```
academico/maihda_saeb2023/paper/
├── tabelas/         ← T1-T4 + TS_sens + TS0 em português (CSV)
├── figuras/         ← F1-F5 em português (PNG 300dpi + PDF vetorial)
├── tables/          ← T1-T4 + TS_sens + TS0 em inglês (CSV) — para RE&E
├── figures/         ← F1-F5 em inglês (PNG 300dpi + PDF vetorial) — para RE&E
├── submission_REE/  ← pacote completo de submissão (manuscritos + figs + tabs)
└── MAIHDA_Brazil_submission_REE.zip   ← zip pronto para anexar em email
```

### Manuscritos

```
academico/maihda_saeb2023/manuscript/
├── 17_paper_REE_FINAL_anonymous.docx       ← versão final (blind review)
├── 17_paper_REE_FINAL_with_authors.docx    ← versão final (com autoria)
└── (versões anteriores v1-v4 preservadas para histórico)
```

### Microdados

`pipeline/data/processed/saeb_2023_{5ef,9ef,3em}.parquet` (35 colunas selecionadas do TS_ALUNO).
