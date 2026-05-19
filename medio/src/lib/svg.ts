// Helpers de SVG e math para o canvas da peça Médio.
// Coordenadas: o canvas tem viewBox 800×540. A "baseline" é onde as barras se assentam.
// Notas SAEB vão de SCORE_MIN a SCORE_MAX e são convertidas em Y por scoreToY.

export const SVG_NS = 'http://www.w3.org/2000/svg';

export const CANVAS_W = 800;
export const CANVAS_H = 540;
export const BASELINE = 460;
export const TOP_PAD = 60;
// Escala alargada pra acomodar os extremos reais do SAEB 2023 9º ano matemática
// (P2.5 ≈ 156, P97.5 ≈ 363). O range usado é mais largo que esses extremos pra
// dar margem visual.
export const SCORE_MIN = 140;
export const SCORE_MAX = 380;

export function scoreToY(score: number): number {
  const range = SCORE_MAX - SCORE_MIN;
  const norm = Math.max(0, Math.min(1, (score - SCORE_MIN) / range));
  return BASELINE - norm * (BASELINE - TOP_PAD);
}

export function make<K extends keyof SVGElementTagNameMap>(
  tag: K,
  attrs: Record<string, string | number>,
): SVGElementTagNameMap[K] {
  const el = document.createElementNS(SVG_NS, tag) as SVGElementTagNameMap[K];
  for (const k in attrs) el.setAttribute(k, String(attrs[k]));
  return el;
}

// Random determinístico (mesmo seed = mesmo valor). Usado pra dar uma "tremida"
// nas barras sem perder reprodutibilidade.
export function rand(seed: number): number {
  const x = Math.sin(seed * 12.9898) * 43758.5453;
  return x - Math.floor(x);
}

// Caminho de barra "rabiscada": quatro cantos com pequenas oscilações nas bordas
// pra parecer desenho à mão, mas a base permanece encostada na baseline.
export function roughBarPath(x: number, y: number, w: number, h: number, seedBase = 0): string {
  const wobble = 1.2;
  const r = (s: number) => (rand(seedBase + s) - 0.5) * wobble;
  const x1 = x + r(1);
  const y1 = y + r(2);
  const x2 = x + w + r(3);
  const y2 = y + r(4);
  const x3 = x + w + r(5);
  const y3 = y + h - 0.3;
  const x4 = x + r(7);
  const y4 = y + h - 0.3;
  return `M ${x1} ${y1} L ${x2} ${y2} L ${x3} ${y3} L ${x4} ${y4} Z`;
}

export const deg2rad = (d: number) => (d * Math.PI) / 180;
