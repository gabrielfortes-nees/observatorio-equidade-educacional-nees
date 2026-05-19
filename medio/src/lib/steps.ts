// Os 13 passos do roteiro. Cada passo descreve:
//   - bars: barras a mostrar no canvas, com posição (x), largura (w), nota (score),
//           rótulo opcional, cor, opacidade, e se mostra/oculta o valor da nota.
//   - medios: Médios a posicionar (cada um ligado a uma barra via barId, OU em
//             coordenadas livres via freeX/freeY).
//   - speech: HTML da fala do passo (com spans .mark/.orange/.brown pros destaques
//             coloridos e .aside pro pensamento marginal).
//   - removeMedios: IDs de Médios de passos anteriores que somem agora.
//   - overlay: ID de uma "camada extra" (textos sobre o canvas) específica do passo.
//   - alt: texto descritivo do passo, lido por leitores de tela e usado como
//          "ato N de 13" no cabeçalho.
//
// Cores das barras seguem a paleta do Observatório:
//   #D35400 (orange-deep) = recortes "elevados" (privada, Sul, etc.)
//   #5A3825 (brown)       = recortes "deprimidos" (pública, Norte, etc.)
//   #5A4A3F (ink-soft)    = Médio nacional, neutro
//   #A82E2E (mark)        = destaque crítico (extremos da injustiça)
//   #9A8B7E (ink-faint)   = barras de "fundo" (a nuvem ao redor)
//
// Posicionamento livre do Médio nos passos 9-13: o personagem fica no canto
// esquerdo do canvas, em cima da baseline (freeX=60, freeY=460), funcionando
// como narrador. Isso evita sobreposição com a nuvem de barras (que ocupa
// x=80..720) e com os overlays de texto (que ficam centralizados).

import type { PoseName } from './poses';

export interface BarDef {
  id: string;
  x: number;
  w: number;
  score: number;
  label?: string;
  color?: string;
  opacity?: number;
  showScore?: boolean;
}

export interface MedioPlacement {
  id: string;
  barId?: string;        // posiciona em cima de uma barra
  freeX?: number;        // OU em coordenadas livres
  freeY?: number;
  scale: number;
  pose: PoseName;
  opacity?: number;
  offsetX?: number;
  offsetY?: number;
}

export type OverlayName = 'dispersion' | 'two-types' | 'final';

export interface Step {
  bars: BarDef[];
  medios: MedioPlacement[];
  speech: string;
  removeMedios?: string[];
  overlay?: OverlayName;
  alt: string;
}

// Paleta abreviada usada nas barras
const C = {
  orange: '#D35400',   // privada, alto
  brown: '#5A3825',    // pública, deprimido
  inkSoft: '#5A4A3F',  // Médio nacional, neutro
  mark: '#A82E2E',     // destaque crítico
  inkFaint: '#9A8B7E', // fundo / nuvem
  brownSoft: '#8B5A3C',
  orangeSoft: '#F5B271',
  brownDeep: '#3D2418',
} as const;

// Gradiente de 10 níveis usado no passo 8 (cor, renda, escolaridade)
const GRAD_10 = [
  C.brownDeep,
  C.brown,
  '#704632',
  C.brownSoft,
  '#9A7A5C',
  '#B89072',
  '#D89A4F',
  C.orange,
  C.orange,
  C.mark,
];

// Helper pra gerar a "nuvem" de 20 barras (passos 9-13).
// Retorna pares (id, x, w, score) em forma compacta; cores e opacidades variam por passo.
function buildCloud20(): { id: string; x: number; w: number; score: number }[] {
  const n = 20;
  const startX = 80;
  const totalW = 640;
  const gap = totalW / n;
  const barW = gap - 4;
  const out: { id: string; x: number; w: number; score: number }[] = [];
  for (let i = 0; i < n; i++) {
    const t = i / (n - 1);
    const base = 210 + t * 88;
    const noise = Math.sin(i * 1.7) * 4;
    out.push({ id: `d${i}`, x: startX + i * gap, w: barW, score: base + noise });
  }
  return out;
}

// Posição padrão do Médio "narrador" nos passos 9-13: canto esquerdo, em cima
// da baseline, fora da nuvem de barras (que começa em x=80).
const NARRATOR_X = 60;
const NARRATOR_Y = 460;

export const STEPS: Step[] = [
  // 1 — apresentação
  {
    bars: [{ id: 'main', x: 360, w: 80, score: 248, label: 'nota nacional · 9º ano · matemática', color: C.inkSoft }],
    medios: [{ id: 'M', barId: 'main', scale: 1.3, pose: 'proud' }],
    speech: `<p>Sou <span class="mark">Médio</span>. Nascido diretamente do SAEB, 9º ano, matemática: <span class="mark">248</span>.</p>
             <span class="aside">Vocês me usam toda semana, nem me notam, mas eu tô lá.</span>`,
    alt: 'Médio se apresenta como a média nacional de 248 pontos do SAEB, 9º ano, matemática. Uma única barra cinza no centro com o personagem em pose orgulhosa.',
  },

  // 2 — como sou calculado
  {
    bars: [{ id: 'main', x: 360, w: 80, score: 248, label: '248 · média de 2,4 milhões', color: C.inkSoft }],
    medios: [{ id: 'M', barId: 'main', scale: 1.3, pose: 'curious' }],
    speech: `<p>Meu pai juntou <span class="orange">2,4 milhões</span> de notas e minha mãe foi lá e dividiu certinho. Aí nasci eu.</p>
             <p>Tipo assim: uma parte de mim é 200, uma parte é 248, uma parte é 296. No fim das contas, eu fico com <span class="mark">248</span>.</p>
             <span class="aside">...O do meio sou eu. Acho. Os outros dois também são. Será?</span>`,
    alt: 'Médio explica que é a média de 2,4 milhões de notas, dividindo o total pelo número de alunos. Mesma barra única, em pose curiosa.',
  },

  // 3 — inquietação
  {
    bars: [{ id: 'main', x: 360, w: 80, score: 248, label: '...', color: C.inkSoft }],
    medios: [{ id: 'M', barId: 'main', scale: 1.3, pose: 'surprised' }],
    speech: `<p>Ihhhhh...</p>
             <p>Se o do 200 e o do 296 também são eu...</p>
             <p><span class="mark">O que sou eu, exatamente?</span></p>`,
    alt: 'Médio se questiona: se os alunos com 200 e com 296 também são "ele", o que ele realmente representa? Mesma barra, expressão de surpresa.',
  },

  // 4 — rede de ensino
  {
    bars: [
      { id: 'priv', x: 260, w: 75, score: 285, label: 'rede privada', color: C.orange },
      { id: 'pub', x: 465, w: 75, score: 241, label: 'rede pública', color: C.brown },
    ],
    medios: [
      // M (persistente, fantasma) fica na baseline no gap entre priv e pub,
      // pra preservar a continuidade visual sem sobrepor o Médio novo da pub.
      { id: 'M', freeX: 400, freeY: 460, scale: 0.7, pose: 'troubled', opacity: 0.3 },
      { id: 'A', barId: 'priv', scale: 1.1, pose: 'neutral' },
      { id: 'B', barId: 'pub', scale: 1.1, pose: 'neutral' },
    ],
    speech: `<p>Olha só. Separa por rede:</p>
             <p>Privada, <span class="orange">285</span>. Pública, <span class="brown">241</span>.</p>
             <p><span class="mark">Quarenta e quatro pontos</span> — em escala SAEB, mais ou menos o que se aprende em um ano e meio de aula.</p>
             <span class="aside">...Acho que essa diferença não é justa.</span>`,
    alt: 'O Médio se divide em dois: rede privada com 285 pontos (barra laranja) e rede pública com 241 pontos (barra marrom). A diferença de 44 pontos equivale a cerca de um ano e meio de aprendizagem.',
  },

  // 5 — volta
  {
    bars: [{ id: 'main', x: 360, w: 80, score: 248, label: '248 · de volta à média', color: C.inkSoft }],
    medios: [{ id: 'M', barId: 'main', scale: 1.3, pose: 'thinking' }],
    removeMedios: ['A', 'B'],
    speech: `<p>E quando junta de novo, eu volto pra <span class="mark">248</span>.</p>
             <p>Como se nada tivesse acontecido. <span class="mark">Será que dá pra tomar decisão assim?</span></p>
             <span class="aside">Estranho, né? A conta tá certa. Mas alguma coisa some no caminho.</span>`,
    alt: 'As duas barras se juntam novamente em uma única barra de 248 pontos. Médio em pose pensativa, questionando se decisões podem ser tomadas baseadas só na média.',
  },

  // 6 — região (foco no gestor)
  {
    bars: [
      { id: 'r-n', x: 130, w: 55, score: 228, label: 'N', color: C.brown },
      { id: 'r-ne', x: 215, w: 55, score: 235, label: 'NE', color: C.brownSoft },
      { id: 'r-se', x: 345, w: 55, score: 254, label: 'SE', color: C.orange },
      { id: 'r-s', x: 430, w: 55, score: 252, label: 'S', color: C.orange },
      { id: 'r-co', x: 540, w: 55, score: 246, label: 'CO', color: C.inkSoft },
    ],
    medios: [
      // M (persistente, fantasma) na baseline no gap maior entre NE e SE
      // (x=307), sem sobrepor o Médio novo da SE.
      { id: 'M', freeX: 307, freeY: 460, scale: 0.6, pose: 'troubled', opacity: 0.3 },
      { id: 'A', barId: 'r-n', scale: 0.9, pose: 'troubled' },
      { id: 'B', barId: 'r-ne', scale: 0.9, pose: 'neutral' },
      { id: 'C', barId: 'r-se', scale: 0.9, pose: 'neutral' },
      { id: 'D', barId: 'r-s', scale: 0.9, pose: 'neutral' },
      { id: 'E', barId: 'r-co', scale: 0.9, pose: 'neutral' },
    ],
    speech: `<p>Agora por região. Norte público: <span class="brown">228</span>. Sudeste privado: <span class="orange">254</span>.</p>
             <p>Vinte e seis pontos. Mas o gestor do Norte e o gestor do Sudeste não estão jogando com as mesmas cartas.</p>
             <span class="aside">Isso aqui não é geografia. É orçamento, é história, é o que tem disponível.</span>`,
    alt: 'Cinco barras representam as regiões brasileiras: Norte (228), Nordeste (235), Sudeste (254), Sul (252) e Centro-Oeste (246). A diferença de 26 pontos entre os extremos reflete condições estruturais, não apenas geografia.',
  },

  // 7 — volta de novo
  {
    bars: [{ id: 'main', x: 360, w: 80, score: 248, label: '248 · outra vez', color: C.inkSoft }],
    medios: [{ id: 'M', barId: 'main', scale: 1.3, pose: 'troubled' }],
    removeMedios: ['A', 'B', 'C', 'D', 'E'],
    speech: `<p>De novo <span class="mark">248</span>. De novo certo.</p>
             <p><span class="mark">Quantas vezes eu já fui calculado hoje e ninguém viu isso por baixo?</span></p>`,
    alt: 'A média volta a 248. Médio com expressão incomodada, percebendo que cada vez que é calculado sem desagregação, esconde as diferenças estruturais por baixo.',
  },

  // 8 — cor, renda, escolaridade (virada moral)
  (() => {
    const scores = [219, 226, 233, 240, 247, 252, 260, 270, 282, 295];
    const n = 10;
    const startX = 90;
    const totalW = 620;
    const gap = totalW / n;
    const barW = 48;

    const bars: BarDef[] = [];
    const medios: MedioPlacement[] = [];
    for (let i = 0; i < n; i++) {
      bars.push({ id: `g${i}`, x: startX + i * gap, w: barW, score: scores[i], color: GRAD_10[i] });
      medios.push({
        id: `s${i}`,
        barId: `g${i}`,
        scale: 0.55,
        pose: i < 2 ? 'troubled' : i > 7 ? 'proud' : 'neutral',
      });
    }
    medios.unshift({ id: 'M', barId: 'g4', scale: 0.55, pose: 'troubled', opacity: 0.2 });

    return {
      bars,
      medios,
      speech: `<p>Tá. Vou mais fundo.</p>
               <p>Branco, privado, Sul, mãe com superior: <span class="orange">295</span>.</p>
               <p>Preto, público, Norte, mãe sem fundamental: <span class="brown">219</span>.</p>
               <p><span class="mark">Setenta e seis pontos.</span> Três anos de escolaridade entre dois meninos de catorze.</p>
               <span class="aside">Espera. ...Será que a injustiça sou eu?</span>`,
      alt: 'Dez barras em gradiente, cruzando raça, rede, região e escolaridade da mãe. Do menino preto, público, Norte, mãe sem fundamental (219) ao branco, privado, Sul, mãe com superior (295): 76 pontos de diferença, equivalente a três anos de escolaridade entre dois adolescentes de 14 anos.',
    } satisfies Step;
  })(),

  // 9 — formulação da dispersão
  (() => {
    const cloud = buildCloud20();
    const bars: BarDef[] = cloud.map((b, i) => {
      const t = i / 19;
      const palette = [C.brown, C.brownSoft, C.inkFaint, '#A88B6E', C.orange, C.mark];
      const idx = Math.min(palette.length - 1, Math.floor(t * palette.length));
      return { ...b, color: palette[idx], opacity: 0.55, showScore: false };
    });
    const medios: MedioPlacement[] = cloud.map((b) => ({
      id: `dt${b.id}`,
      barId: b.id,
      scale: 0.4,
      pose: 'tiny',
    }));
    medios.unshift({ id: 'M', freeX: NARRATOR_X, freeY: NARRATOR_Y, scale: 0.9, pose: 'thinking', opacity: 0.9 });

    return {
      bars,
      medios,
      removeMedios: ['s0', 's1', 's2', 's3', 's4', 's5', 's6', 's7', 's8', 's9'],
      overlay: 'dispersion',
      speech: `<p>Calma. Não, espera. Deixa eu pensar.</p>
               <p>Toda média tem uma <span class="orange">nuvem em volta</span>. Estatísticos chamam de <span class="mark">dispersão</span>.</p>
               <p>Essa nuvem sempre vai existir. Pessoas são diferentes mesmo.</p>
               <p>Mas tem <span class="mark">dois tipos de diferença</span> misturadas dentro dela. E eu nunca tinha separado uma da outra.</p>`,
      alt: 'Vinte barras em gradiente formam uma nuvem em torno da média: a dispersão. Médio sai da nuvem e vai pro canto esquerdo, em pose pensativa, percebendo que a dispersão contém dois tipos diferentes de diferença.',
    } satisfies Step;
  })(),

  // 10 — distinção (Soares)
  (() => {
    const cloud = buildCloud20();
    const bars: BarDef[] = cloud.map((b, i) => {
      const isStructural = i < 4 || i > 15;
      const color = isStructural ? (i < 4 ? C.brown : C.mark) : C.inkFaint;
      return { ...b, color, opacity: isStructural ? 0.85 : 0.4, showScore: false };
    });
    const medios: MedioPlacement[] = cloud.map((b) => ({
      id: `dt${b.id}`,
      barId: b.id,
      scale: 0.4,
      pose: 'tiny',
    }));
    medios.unshift({ id: 'M', freeX: NARRATOR_X, freeY: NARRATOR_Y, scale: 0.9, pose: 'thinking', opacity: 0.9 });

    return {
      bars,
      medios,
      overlay: 'two-types',
      speech: `<p>Uma parte da nuvem é <span class="orange">gente sendo gente</span>. Aprende rápido, aprende devagar, gosta mais, gosta menos.</p>
               <p>A outra parte é o que aconteceu <span class="mark">antes da prova começar</span>. Livro em casa. Biblioteca aberta. Professora que ficou. Internet que funcionou.</p>
               <span class="aside">Estatisticamente, é tudo dispersão. Politicamente, são coisas muito diferentes. ...Eu não sou o problema. Eu viro problema quando o que tô resumindo já vinha quebrado de antes.</span>`,
      alt: 'A nuvem ganha rótulos: extremos da esquerda em marrom (estrutural, deprimido) e da direita em vermelho-marca (estrutural, privilegiado), centro em cinza (variação individual esperada). A distinção entre o que é dispersão estatística e o que é injustiça anterior à prova.',
    } satisfies Step;
  })(),

  // 11 — Médio percebe (Collins, sem nomear)
  (() => {
    const cloud = buildCloud20();
    const palette = [C.brown, C.brownSoft, C.inkFaint, '#A88B6E', C.orange, C.mark];
    const bars: BarDef[] = cloud.map((b, i) => {
      const t = i / 19;
      const idx = Math.min(palette.length - 1, Math.floor(t * palette.length));
      return { ...b, color: palette[idx], opacity: 0.6, showScore: false };
    });
    const medios: MedioPlacement[] = cloud.map((b) => ({
      id: `dt${b.id}`,
      barId: b.id,
      scale: 0.4,
      pose: 'tiny',
    }));
    medios.unshift({ id: 'M', freeX: NARRATOR_X, freeY: NARRATOR_Y, scale: 0.9, pose: 'realizing', opacity: 0.95 });

    return {
      bars,
      medios,
      speech: `<p>Olha o que eu faço quando me usam <span class="mark">sozinho</span>:</p>
               <p>Pego desigualdade que veio de fora — bairro, renda, história, cor da pele — e devolvo <span class="orange">como se fosse diferença de desempenho</span>.</p>
               <p><span class="mark">Como se estivesse nas crianças.</span></p>
               <span class="aside">Eu não invento a desigualdade. Mas eu disfarço de onde ela vem.</span>`,
      alt: 'Médio em pose de quem percebeu, no canto esquerdo da cena: usado sozinho, ele transforma desigualdade externa (bairro, renda, raça, história) em diferença interna, como se a injustiça estivesse nas crianças.',
    } satisfies Step;
  })(),

  // 12 — reconciliação (visibilização)
  (() => {
    const cloud = buildCloud20();
    const bars: BarDef[] = cloud.map((b, i) => {
      const isExtreme = i < 2 || i > 17;
      return {
        ...b,
        color: isExtreme ? C.mark : C.inkFaint,
        opacity: isExtreme ? 0.9 : 0.3,
        showScore: false,
      };
    });
    const medios: MedioPlacement[] = cloud.map((b, i) => {
      const isExtreme = i < 2 || i > 17;
      return {
        id: `dt${b.id}`,
        barId: b.id,
        scale: isExtreme ? 0.55 : 0.4,
        pose: 'tiny',
        opacity: isExtreme ? 1 : 0.4,
      };
    });
    medios.unshift({ id: 'M', freeX: NARRATOR_X, freeY: NARRATOR_Y, scale: 0.9, pose: 'calm', opacity: 0.95 });

    return {
      bars,
      medios,
      speech: `<p>Olha, eu sirvo. Monitorar a rede ao longo do tempo, comparar país com país, ver pra onde a coisa anda.</p>
               <p>E olha uma coisa que eu faço bem: quando me calculam <span class="orange">separado pra grupos que normalmente somem nos números grandes</span> — meninas negras do Norte, indígenas, quilombolas — aí eu mostro o que estava escondido.</p>
               <p><span class="mark">A média de quem é esquecido é onde a desigualdade aparece com nome.</span></p>
               <span class="aside">Política educacional precisa de mim — e do que tá em volta de mim, ao mesmo tempo.</span>`,
      alt: 'Os extremos da nuvem (populações esquecidas) ficam destacados em vermelho-marca, o meio fica esmaecido. Médio em pose calma no canto esquerdo, propondo seu próprio uso ético: a média calculada para grupos historicamente invisibilizados torna visível a desigualdade.',
    } satisfies Step;
  })(),

  // 13 — pedido final
  (() => {
    const cloud = buildCloud20();
    const n = cloud.length;
    const bars: BarDef[] = cloud.map((b, i) => {
      const isExtreme = i === 0 || i === n - 1;
      return {
        ...b,
        color: isExtreme ? (i === 0 ? C.brown : C.mark) : C.inkFaint,
        opacity: isExtreme ? 0.95 : 0.2,
        showScore: !!isExtreme,
      };
    });
    const medios: MedioPlacement[] = cloud.map((b, i) => {
      const isExtreme = i === 0 || i === n - 1;
      return {
        id: `dt${b.id}`,
        barId: b.id,
        scale: isExtreme ? 0.8 : 0.35,
        pose: isExtreme ? 'neutral' : 'tiny',
        opacity: isExtreme ? 1 : 0.25,
      };
    });
    medios.unshift({ id: 'M', freeX: NARRATOR_X, freeY: NARRATOR_Y, scale: 0.85, pose: 'calm', opacity: 0.9 });

    return {
      bars,
      medios,
      overlay: 'final',
      speech: `<p>Quando olharem pra mim, perguntem também:</p>
               <p>— o que tá dentro da minha <span class="orange">dispersão</span>?</p>
               <p>— quanto é diferença, e quanto é <span class="mark">injustiça que vinha de antes</span>?</p>
               <p>— quem o sistema preparou pra estar no topo, e quem o sistema preparou pra estar embaixo?</p>
               <span class="aside">Essa distinção é com vocês. Eu sou só a conta. Mas a conta também é política.</span>`,
      alt: 'Os dois extremos da dispersão ficam em destaque: a barra mais baixa em marrom e a mais alta em vermelho-marca. Entre elas, a diferença em pontos. Médio termina no canto esquerdo, em pose calma, pedindo que cada uso da média venha acompanhado de perguntas estruturais.',
    } satisfies Step;
  })(),
];

export const TOTAL_STEPS = STEPS.length;
