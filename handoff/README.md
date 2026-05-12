# Pacote de handoff — Observatório de Equidade Educacional

## 🔗 URLs ao vivo (protótipo)

- **Entrada:** https://gabrielfortes-nees.github.io/observatorio-equidade-educacional-nees/
- **Travessias** (jornada storytelling): https://gabrielfortes-nees.github.io/observatorio-equidade-educacional-nees/prototipo/travessias.html
- **Painel** (9 leituras + mapa): https://gabrielfortes-nees.github.io/observatorio-equidade-educacional-nees/prototipo/insights3_dinamico.html

Hospedado em GitHub Pages, redeploy automático a cada `git push`.

## Pacote para o time

Este pacote é o que o time recebe para construir a versão de produção do Observatório. Ordem de leitura recomendada:

| # | Doc | Quem deve ler |
|---|---|---|
| 1 | [01_arquitetura.md](01_arquitetura.md) | **Todos** — visão geral em 3 fases, stack, hospedagem |
| 2 | [02_data_contract.md](02_data_contract.md) | **Front + Back** — schema dos JSONs (contrato) |
| 3 | [03_spec_funcional.md](03_spec_funcional.md) | **Front + Conteúdo** — cada leitura em detalhe |
| 4 | [04_governanca_dado.md](04_governanca_dado.md) | **Conteúdo + Validação** — fontes, evidência, limitações, LGPD |
| 5 | [05_backlog.md](05_backlog.md) | **Tech lead** — tickets por responsável, ordem de sprints |
| 6 | [06_como_rodar.md](06_como_rodar.md) | **Back + DevOps** — passo a passo de execução do pipeline |
| 7 | [07_nota_tecnica_contrafactuais.md](07_nota_tecnica_contrafactuais.md) | **Validação metodológica + Conteúdo** — uso de contrafactuais em L3, L6 e L9: tipologia, cálculos, mini-relatório |

## O que cada perfil precisa

### Front-end
- Lê: 01, 02, 03
- Recebe: o protótipo em `../prototipo/insights3_dinamico.html` como **referência visual viva**
- Recebe: JSONs de exemplo em `../pipeline/data/agregados/`
- Entrega: aplicação React + Vite (ver F1-F8 no backlog)

### Back-end / dados
- Lê: 01, 02, 04, 06
- Recebe: pipeline R completo em `../pipeline/R/`
- Recebe: dicionários INEP em `../pipeline/anexos/`
- Entrega: serviço que regenera JSONs agendado + endpoint que serve (ver B1-B6)

### Conteúdo / pesquisa
- Lê: 03, 04
- Recebe: copy curatorial atual no HTML, citações qualitativas, fontes
- Entrega: revisão metodológica + atualizações de copy (ver C1-C3)

### DevOps / infra
- Lê: 01, 06
- Entrega: deploy + domínio + CI/CD (ver I1-I4)

## Definição de "pronto"

- ✅ Todos os tickets **P0** do backlog fechados
- ✅ Validação automática de JSONs passa (B3)
- ✅ Pelo menos uma revisão metodológica feita por pesquisador sênior do NEES
- ✅ HTTPS funcionando no subdomínio definitivo
- ✅ Página "Sobre" e "Metodologia" no ar
- ✅ Um ciclo completo de atualização de dados testado manualmente

## Estado do protótipo entregue

| Componente | Status |
|---|---|
| 9 leituras com dados reais SAEB 2023 + Censo Escolar 2025 + Censo Superior 2024 + Bolsa Família abr/2025 + SIDRA Censo Demográfico 2022 | ✅ funcionando |
| Mapa navegável com geometria real do Brasil + 6 camadas + ranking sidebar | ✅ funcionando |
| Toggle contrafactual em L3, L6, L9 com legenda explicativa | ✅ funcionando |
| Texto narrativo com placeholders dinâmicos `{{narrativa.xxx}}` | ✅ funcionando |
| Pipeline R reprodutível (5 leitores + 9 geradores + mapa) | ✅ funcionando |
| Pendência: Taxas de Rendimento INEP para L8 (download manual) | ⏳ ver B4 |
| Pendência: PNAE FNDE (opcional, se quiser voltar contrafactual original L3) | ⏳ ver B5 |

## Avisos para o time

1. **Não reinvente as vizs.** O código D3 do protótipo é a referência. Migrar para React mantendo o D3 dentro de `useEffect` (template em [01_arquitetura.md](01_arquitetura.md)).

2. **Não inventem números.** Toda barra, toda porcentagem, todo título com dado tem que vir do JSON. Texto puramente curatorial (citações, posicionamentos teóricos) pode ficar hardcoded.

3. **Sub-representação é parte do achado.** Em L8, o número que aparece **subestima** o abandono real. Esse aviso metodológico tem que estar visível no card, não escondido no rodapé.

4. **Mude formato de JSON com cuidado.** Cada alteração no schema (`02_data_contract.md`) quebra o front. Versione, mantenha backward-compat por 1 release.

5. **A estética é parte da curadoria.** O layout storytelling com Lora + Work Sans + paleta laranja-marrom-creme é uma escolha editorial do NEES, não um detalhe livre. Mudanças passam por revisão.

## Contato

(Preencher antes de enviar)

- Pesquisador responsável: Gabriel Fortes
- Tech lead time front:
- Tech lead time back:
- Pesquisador sênior validação metodológica:
- Designer/curador:
