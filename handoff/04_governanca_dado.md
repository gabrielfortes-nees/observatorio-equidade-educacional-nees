# Governança de dado, fontes e evidência

## Princípios

1. **Todo número visível precisa ter rastro até a fonte oficial.** Quem visita o site deve poder, em poucos cliques, achar o microdado original.
2. **Diferenciar dado calculado de estimativa da literatura.** Badges: "Evidência forte" (calculada) · "Evidência moderada" (literatura convergente) · "Evidência indireta" (extrapolação).
3. **Dado nunca é neutro.** Cada leitura traz aviso metodológico onde aplicável (especialmente L8, L3, L4, L6).
4. **Sub-representação é parte do achado.** Quando o número subestima a desigualdade (caso L8), isso é dito explicitamente, não escondido.

## Fontes oficiais

| Fonte | Órgão | Frequência | Usado em |
|---|---|---|---|
| SAEB 2023 microdados aluno | INEP/MEC | Bienal | L1, L2, L3, L5, L7, L8, Mapa |
| Censo Escolar 2025 microdados | INEP/MEC | Anual | L3, L4, L5 |
| Censo Educação Superior 2024 | INEP/MEC | Anual | L9 |
| Censo Demográfico 2022 — SIDRA tabela 9514 | IBGE | Decenal | L4 (denominador creche) |
| Folha Novo Bolsa Família abr/2025 | Portal da Transparência (CGU) | Mensal | L6 (callout) |
| Estimativas de evasão | Cedeplar/UFMG, IPEA TD 2447, Banco Mundial | Literatura | L6 (bars) |
| Composição racial federais 2012 | Censo Sup. INEP, ANDIFES | Histórica | L9 (contrafactual) |

## Política de atualização

| Componente | Quando atualizar |
|---|---|
| SAEB | Quando o INEP publicar novos microdados (geralmente novembro do ano seguinte ao teste) — atualmente 2023, próxima onda 2025 (publicação prevista 2026) |
| Censo Escolar | Anualmente, em torno de fevereiro |
| Censo Educação Superior | Anualmente, em torno de outubro |
| Bolsa Família | Mensal (mas a leitura L6 usa 1 mês representativo; trocar 1× ao ano) |
| Censo Demográfico | A cada 10 anos (próxima edição: 2032) |
| Conteúdo curatorial | Quando os pesquisadores do NEES atualizarem |

## Limitações conhecidas (por leitura)

### L1
- **Corte "adequado"** definido em ≥ 200 pontos SAEB (escala 0-500). O INEP usa cortes oficiais ligeiramente diferentes por área (geralmente 225 para LP 5º EF "adequado pleno"). Documentar essa escolha.
- **Agrupamento branca+amarela** segue o protótipo, mas perde nuance. Pode ser ajustado.
- **INSE quintilizado** pela amostra SAEB, não pelos quintis oficiais INEP — pode dar pequenas diferenças.

### L2
- **Q08/Q09** só vão até "Superior completo" (sem pós-graduação). O protótipo original sugeria 8 níveis — só existem 5 úteis no SAEB.

### L3
- **Códigos de município SAEB ≠ IBGE.** Por isso a agregação é por UF (27 unidades), não por município. Quintilização tem ruído proporcional.
- **Contrafactual** é uma simplificação ("se todas UFs estivessem no pior cenário, todas convergem para Q1") — não é estimativa causal experimental.

### L4
- Mesmo issue de chave SAEB↔IBGE (agregado por UF).
- **Cobertura de creche** é matrículas / pop 0-3 sem distinguir vagas em creche pública vs privada. Em UFs com forte rede privada, superestima cobertura pública.

### L5
- **Categorias Q21c/d** mapeadas para midpoints de horas — aproximação.
- **Q23 segurança** tem 9 itens com leituras heterogêneas; a média pode mascarar nuances específicas.
- **Banheiro PNE** binário ignora qualidade/funcionalidade.

### L6
- Folha BF de **1 mês** (abr/2025) — não pega sazonalidade. Trocar por média anual quando viável.
- Valores `real`/`off` das 4 barras vêm da literatura, não recalculados. Documentar.

### L7
- **Autodeclaração** — Q19/Q20 são memória do aluno, não registro administrativo.

### L8
- **Sub-representação grave:** quem abandonou de fato JÁ NÃO está no SAEB. A magnitude real do abandono é maior que o número mostrado.
- **Pendente:** quando Taxas de Rendimento INEP forem baixadas manualmente, complementar com taxa oficial agregada.

### L9
- Pré-cotas 2012 são valores de **um ano específico** — não tendência longa. A literatura sobre Lei de Cotas debate qual seria o contrafactual plausível (counterfactual trend); usamos a versão simples.

### Mapa
- **Geometria média** do GeoJSON usado (3,2 MB). Para produção, simplificar com mapshaper → ~500 KB.
- **Indicadores indígenas** com amostra pequena em UFs do Sudeste/Sul — quintilização tem ruído.

## LGPD / privacidade

- **Microdados pessoais** (BF tem CPF mascarado, NIS, nome) **ficam só em `data/raw/`** e **nunca são servidos pelo front**.
- **JSONs publicados** contém **apenas agregados** — médias, contagens, proporções por grandes grupos (UF, raça×sexo, quartil).
- **n mínimo** por célula: 100 alunos. Células abaixo viram `null` e aparecem como "—" no front. **Implementar em ronda 2** se algum grupo for de risco.
- **Indígenas** — atenção especial: amostras pequenas, evitar identificação por território + raça.

## Citação

Sugestão de formato de citação (ABNT):

> FORTES, Gabriel. **Observatório de Equidade Educacional: nove leituras dos dados brasileiros sobre desigualdade educacional** [recurso eletrônico]. Maceió: Universidade Federal de Alagoas (UFAL) · Núcleo de Estudos em Educação e Sociedade (NEES), 2026. Disponível em: https://gabrielfortes-nees.github.io/observatorio-equidade-educacional-nees/. Acesso em: dd/mm/aaaa.

Documentar a versão (data do último `gerado_em` nos JSONs) na página footer.

## Política de erros e correções

- **Bug de dado** (número errado): corrigir, regenerar JSON, registrar mudança em `CHANGELOG.md` com data e descrição.
- **Bug curatorial** (texto): corrigir HTML, registrar em CHANGELOG.
- **Mudança de fonte** (novo ano INEP): seguir o "como rodar", registrar em CHANGELOG.

## Equipe responsável

- **Autor e curadoria de conteúdo:** Dr. Gabriel Fortes (Universidade Federal de Alagoas) · gabriel.macedo@nees.ufal.br
- **Pipeline de dados:** [responsável back]
- **Apresentação:** [responsável front]
- **Validação metodológica:** [pesquisador sênior]

(Os papéis adicionais serão preenchidos com membros do time conforme integração.)
