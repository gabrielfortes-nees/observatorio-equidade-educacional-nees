// Renderer imperativo do Médio xkcd para uso dentro do motor GSAP do canvas.
// Cria/atualiza elementos SVG diretamente em um <g> que é passado por referência.
// Espelha exatamente o componente React `MedioXkcd.tsx`, mas em estilo imperativo
// porque é mais eficiente quando o GSAP precisa re-renderizar em cada frame da
// transição entre poses.

import type { Pose, FaceMood } from './poses';
import { deg2rad } from './poses';
import { make, SVG_NS } from './svg';

const XKCD = {
  headRadius: 13,
  spine: 32,
  upperArm: 17,
  forearm: 16,
  thigh: 22,
  shin: 22,
} as const;

interface RenderOptions {
  strokeColor?: string;
  strokeWidth?: number;
  paperColor?: string;
}

export function renderMedioXkcdInto(
  group: SVGGElement,
  pose: Pose,
  scale: number = 1,
  opts: RenderOptions = {},
): void {
  const strokeColor = opts.strokeColor ?? '#2a1f18';
  const paperColor = opts.paperColor ?? '#fcf8f0';
  const STROKE_W = (opts.strokeWidth ?? 2.2) * scale;

  // limpa o grupo (será re-renderizado do zero a cada tick)
  group.innerHTML = '';

  const s = pose;
  const X = XKCD;

  const hipX = s.hipShift * scale;
  const hipY = s.bodyY * scale;

  const spineAng = deg2rad(s.spineLean);
  const neckX = hipX - Math.sin(spineAng) * X.spine * scale;
  const neckY = hipY - Math.cos(spineAng) * X.spine * scale;

  const headAng = deg2rad(s.spineLean + s.headTilt);
  const headOffset = (2 + X.headRadius) * scale;
  const headX = neckX - Math.sin(headAng) * headOffset;
  const headY = neckY - Math.cos(headAng) * headOffset;

  // Braços ancorados no pescoço (estilo xkcd)
  const lUpAng = deg2rad(s.spineLean + 180 + s.leftShoulder);
  const lElbX = neckX - Math.sin(lUpAng) * X.upperArm * scale;
  const lElbY = neckY - Math.cos(lUpAng) * X.upperArm * scale;
  const lFoAng = lUpAng + deg2rad(s.leftElbow);
  const lHaX = lElbX - Math.sin(lFoAng) * X.forearm * scale;
  const lHaY = lElbY - Math.cos(lFoAng) * X.forearm * scale;

  const rUpAng = deg2rad(s.spineLean + 180 + s.rightShoulder);
  const rElbX = neckX - Math.sin(rUpAng) * X.upperArm * scale;
  const rElbY = neckY - Math.cos(rUpAng) * X.upperArm * scale;
  const rFoAng = rUpAng + deg2rad(s.rightElbow);
  const rHaX = rElbX - Math.sin(rFoAng) * X.forearm * scale;
  const rHaY = rElbY - Math.cos(rFoAng) * X.forearm * scale;

  // Pernas ancoradas no ponto único do quadril (sem linha de quadril)
  const lThighAng = deg2rad(s.leftHip);
  const lKneeX = hipX + Math.sin(lThighAng) * X.thigh * scale;
  const lKneeY = hipY + Math.cos(lThighAng) * X.thigh * scale;
  const lShinAng = lThighAng + deg2rad(s.leftKnee);
  const lFootX = lKneeX + Math.sin(lShinAng) * X.shin * scale;
  const lFootY = lKneeY + Math.cos(lShinAng) * X.shin * scale;

  const rThighAng = deg2rad(s.rightHip);
  const rKneeX = hipX + Math.sin(rThighAng) * X.thigh * scale;
  const rKneeY = hipY + Math.cos(rThighAng) * X.thigh * scale;
  const rShinAng = rThighAng + deg2rad(s.rightKnee);
  const rFootX = rKneeX + Math.sin(rShinAng) * X.shin * scale;
  const rFootY = rKneeY + Math.cos(rShinAng) * X.shin * scale;

  // sombra discreta
  group.appendChild(
    make('ellipse', {
      cx: (lFootX + rFootX) / 2,
      cy: Math.max(lFootY, rFootY) + 4 * scale,
      rx: 12 * scale,
      ry: 2 * scale,
      fill: 'rgba(42,31,24,0.12)',
    }),
  );

  const line = (x1: number, y1: number, x2: number, y2: number) => {
    group.appendChild(
      make('line', {
        x1,
        y1,
        x2,
        y2,
        stroke: strokeColor,
        'stroke-width': STROKE_W,
        'stroke-linecap': 'round',
      }),
    );
  };

  // pernas
  line(hipX, hipY, lKneeX, lKneeY);
  line(lKneeX, lKneeY, lFootX, lFootY);
  line(hipX, hipY, rKneeX, rKneeY);
  line(rKneeX, rKneeY, rFootX, rFootY);

  // coluna
  line(hipX, hipY, neckX, neckY);

  // braços
  line(neckX, neckY, lElbX, lElbY);
  line(lElbX, lElbY, lHaX, lHaY);
  line(neckX, neckY, rElbX, rElbY);
  line(rElbX, rElbY, rHaX, rHaY);

  // cabeça
  group.appendChild(
    make('circle', {
      cx: headX,
      cy: headY,
      r: X.headRadius * scale,
      fill: paperColor,
      stroke: strokeColor,
      'stroke-width': STROKE_W,
    }),
  );

  drawFaceInto(group, headX, headY, s.spineLean + s.headTilt, s.face, strokeColor, scale);
}

function drawFaceInto(
  group: SVGGElement,
  cx: number,
  cy: number,
  angleDeg: number,
  mood: FaceMood,
  color: string,
  scale: number,
): void {
  const a = deg2rad(angleDeg);
  const pt = (lx: number, ly: number) => ({
    x: cx + (lx * Math.cos(a) - ly * Math.sin(a)) * scale,
    y: cy + (lx * Math.sin(a) + ly * Math.cos(a)) * scale,
  });
  const eyeR = 1.4 * scale;

  const append = (tag: keyof SVGElementTagNameMap, attrs: Record<string, string | number>) => {
    const el = document.createElementNS(SVG_NS, tag) as SVGElement;
    for (const k in attrs) el.setAttribute(k, String(attrs[k]));
    group.appendChild(el);
  };

  const lEye = pt(-4, -2);
  const rEye = pt(4, -2);

  switch (mood) {
    case 'neutral':
    case 'tiny': {
      append('circle', { cx: lEye.x, cy: lEye.y, r: eyeR, fill: color });
      append('circle', { cx: rEye.x, cy: rEye.y, r: eyeR, fill: color });
      if (mood !== 'tiny') {
        const m1 = pt(-2.5, 4);
        const m2 = pt(2.5, 4);
        append('line', {
          x1: m1.x,
          y1: m1.y,
          x2: m2.x,
          y2: m2.y,
          stroke: color,
          'stroke-width': 1.4 * scale,
          'stroke-linecap': 'round',
        });
      }
      break;
    }
    case 'happy':
    case 'calm': {
      append('circle', { cx: lEye.x, cy: lEye.y, r: eyeR, fill: color });
      append('circle', { cx: rEye.x, cy: rEye.y, r: eyeR, fill: color });
      const p1 = pt(-3, 3);
      const pC = pt(0, 6);
      const p2 = pt(3, 3);
      append('path', {
        d: `M ${p1.x} ${p1.y} Q ${pC.x} ${pC.y} ${p2.x} ${p2.y}`,
        stroke: color,
        'stroke-width': 1.5 * scale,
        fill: 'none',
        'stroke-linecap': 'round',
      });
      break;
    }
    case 'curious': {
      const eb1 = pt(-6, -6);
      const eb2 = pt(-2, -7);
      append('line', {
        x1: eb1.x,
        y1: eb1.y,
        x2: eb2.x,
        y2: eb2.y,
        stroke: color,
        'stroke-width': 1.2 * scale,
        'stroke-linecap': 'round',
      });
      append('circle', { cx: lEye.x, cy: lEye.y, r: eyeR, fill: color });
      append('circle', { cx: rEye.x, cy: rEye.y, r: eyeR, fill: color });
      const m1 = pt(-2.5, 4);
      const m2 = pt(2.5, 4);
      append('line', {
        x1: m1.x,
        y1: m1.y,
        x2: m2.x,
        y2: m2.y,
        stroke: color,
        'stroke-width': 1.4 * scale,
        'stroke-linecap': 'round',
      });
      break;
    }
    case 'surprised': {
      append('circle', { cx: lEye.x, cy: lEye.y, r: eyeR * 1.5, fill: color });
      append('circle', { cx: rEye.x, cy: rEye.y, r: eyeR * 1.5, fill: color });
      const m = pt(0, 4);
      append('circle', {
        cx: m.x,
        cy: m.y,
        r: 1.8 * scale,
        fill: 'none',
        stroke: color,
        'stroke-width': 1.3 * scale,
      });
      break;
    }
    case 'thinking': {
      const lEyeT = pt(-4, -3);
      const rEyeT = pt(4, -3);
      append('circle', { cx: lEyeT.x, cy: lEyeT.y, r: eyeR, fill: color });
      append('circle', { cx: rEyeT.x, cy: rEyeT.y, r: eyeR, fill: color });
      const mp1 = pt(-3, 4);
      const mq1 = pt(-1, 2);
      const mq2 = pt(1, 6);
      const mp2 = pt(3, 4);
      const mid = { x: (mp1.x + mp2.x) / 2, y: (mp1.y + mp2.y) / 2 };
      append('path', {
        d: `M ${mp1.x} ${mp1.y} Q ${mq1.x} ${mq1.y} ${mid.x} ${mid.y} Q ${mq2.x} ${mq2.y} ${mp2.x} ${mp2.y}`,
        stroke: color,
        'stroke-width': 1.4 * scale,
        fill: 'none',
        'stroke-linecap': 'round',
      });
      break;
    }
    case 'troubled': {
      const eb1L = pt(-6, -6);
      const eb2L = pt(-2, -5);
      const eb1R = pt(2, -5);
      const eb2R = pt(6, -6);
      append('line', {
        x1: eb1L.x,
        y1: eb1L.y,
        x2: eb2L.x,
        y2: eb2L.y,
        stroke: color,
        'stroke-width': 1.3 * scale,
        'stroke-linecap': 'round',
      });
      append('line', {
        x1: eb1R.x,
        y1: eb1R.y,
        x2: eb2R.x,
        y2: eb2R.y,
        stroke: color,
        'stroke-width': 1.3 * scale,
        'stroke-linecap': 'round',
      });
      append('circle', { cx: lEye.x, cy: lEye.y, r: eyeR, fill: color });
      append('circle', { cx: rEye.x, cy: rEye.y, r: eyeR, fill: color });
      const p1 = pt(-3, 5);
      const pC = pt(0, 3);
      const p2 = pt(3, 5);
      append('path', {
        d: `M ${p1.x} ${p1.y} Q ${pC.x} ${pC.y} ${p2.x} ${p2.y}`,
        stroke: color,
        'stroke-width': 1.5 * scale,
        fill: 'none',
        'stroke-linecap': 'round',
      });
      break;
    }
    case 'realizing': {
      const eb1L = pt(-6, -7);
      const eb2L = pt(-2, -7);
      const eb1R = pt(2, -7);
      const eb2R = pt(6, -7);
      append('line', {
        x1: eb1L.x,
        y1: eb1L.y,
        x2: eb2L.x,
        y2: eb2L.y,
        stroke: color,
        'stroke-width': 1.3 * scale,
        'stroke-linecap': 'round',
      });
      append('line', {
        x1: eb1R.x,
        y1: eb1R.y,
        x2: eb2R.x,
        y2: eb2R.y,
        stroke: color,
        'stroke-width': 1.3 * scale,
        'stroke-linecap': 'round',
      });
      append('circle', { cx: lEye.x, cy: lEye.y, r: eyeR, fill: color });
      append('circle', { cx: rEye.x, cy: rEye.y, r: eyeR, fill: color });
      const p1 = pt(-3.5, 3);
      const pC = pt(0, 7);
      const p2 = pt(3.5, 3);
      append('path', {
        d: `M ${p1.x} ${p1.y} Q ${pC.x} ${pC.y} ${p2.x} ${p2.y}`,
        stroke: color,
        'stroke-width': 1.6 * scale,
        fill: 'none',
        'stroke-linecap': 'round',
      });
      break;
    }
  }
}
