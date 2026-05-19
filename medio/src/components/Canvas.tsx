// Canvas do Médio: o coração visual da peça.
//
// Estratégia técnica (combinada no plano):
//   - React monta a estrutura do <svg> e seus 4 layers (barras, médios, rótulos,
//     overlay) e expõe cada um por uma ref.
//   - O motor GSAP roda dentro de um useEffect disparado quando o passo muda.
//     Ele mutaciona o SVG diretamente (createElementNS, setAttribute, gsap.to)
//     mantendo a identidade dos Médios e barras entre passos via dois objetos
//     persistentes em refs: mediosRef (Map<id, instância>) e barsRef (Set<id>).
//   - Médios são desenhados pelo renderer imperativo (lib/medioXkcdImperative.ts)
//     a cada frame da transição de pose, porque é muito mais eficiente que
//     re-renderizar JSX React em 60fps com muitos personagens na nuvem (passos
//     9 a 13 têm 20+ Médios em cena ao mesmo tempo).

import { useEffect, useRef } from 'react';
import gsap from 'gsap';
import { STEPS, type Step } from '../lib/steps';
import { CANVAS_W, CANVAS_H, BASELINE, SVG_NS, make, roughBarPath, scoreToY } from '../lib/svg';
import { renderMedioXkcdInto } from '../lib/medioXkcdImperative';
import { POSES, type Pose } from '../lib/poses';
import { spawnParticles, barRect, type Rect } from '../lib/particles';

const INK = '#2a1f18';
const INK_SOFT = '#5a4a3f';

interface MedioInstance {
  state: Pose;
  group: SVGGElement;
  scale: number;
  pendingFaceTimer?: number;
}

interface CanvasProps {
  stepIndex: number;
  reducedMotion: boolean;
}

export function Canvas({ stepIndex, reducedMotion }: CanvasProps) {
  const barsLayerRef = useRef<SVGGElement>(null);
  const particlesLayerRef = useRef<SVGGElement>(null);
  const mediosLayerRef = useRef<SVGGElement>(null);
  const labelsLayerRef = useRef<SVGGElement>(null);
  const overlayLayerRef = useRef<SVGGElement>(null);

  // Persistência de identidade entre passos
  const mediosRef = useRef<Map<string, MedioInstance>>(new Map());
  const barsRef = useRef<Set<string>>(new Set());

  // Snapshot do passo anterior, pra calcular diff de barras e disparar partículas
  // só quando houver mudança significativa.
  const prevStepRef = useRef<Step | null>(null);

  useEffect(() => {
    const step = STEPS[stepIndex];
    if (!step) return;
    const barsLayer = barsLayerRef.current;
    const particlesLayer = particlesLayerRef.current;
    const mediosLayer = mediosLayerRef.current;
    const labelsLayer = labelsLayerRef.current;
    const overlayLayer = overlayLayerRef.current;
    if (!barsLayer || !particlesLayer || !mediosLayer || !labelsLayer || !overlayLayer) return;

    const SHORT = reducedMotion ? 0.01 : 0.3;
    const MED = reducedMotion ? 0.01 : 0.6;
    const LONG = reducedMotion ? 0.01 : 0.9;

    const prevStep = prevStepRef.current;
    prevStepRef.current = step;

    // ===== PARTÍCULAS (efeito "Médio se desfaz") =====
    // Disparam quando o passo introduz barras NOVAS (id que não existia antes).
    // As partículas voam dos elementos REMOVIDOS (ou do Médio atual, se nada foi
    // removido) pras posições das barras novas, dando o efeito de "matéria do
    // Médio formando as barras". É a meta-narrativa visual da peça.
    if (prevStep) {
      const prevBarIds = new Set(prevStep.bars.map((b) => b.id));
      const newBars = step.bars.filter((b) => !prevBarIds.has(b.id));
      const removedBars = prevStep.bars.filter((b) => !step.bars.some((nb) => nb.id === b.id));

      if (newBars.length > 0) {
        const targets: Rect[] = newBars.map((b) =>
          barRect(b.x, b.w, scoreToY(b.score), BASELINE, b.color ?? INK),
        );

        // Define as FONTES: barras removidas (se houver) ou retângulo aproximado
        // ao redor do Médio "M" persistente (que é a memória do número original).
        let sources: Rect[];
        if (removedBars.length > 0) {
          sources = removedBars.map((b) =>
            barRect(b.x, b.w, scoreToY(b.score), BASELINE, b.color ?? INK),
          );
        } else {
          const mInst = mediosRef.current.get('M');
          const mGroup = mInst?.group;
          const transform = mGroup?.getAttribute('transform') ?? '';
          const match = /matrix\(1,0,0,1,([-\d.]+),([-\d.]+)\)|translate\(([-\d.]+),\s*([-\d.]+)\)/.exec(transform);
          const tx = match ? parseFloat(match[1] || match[3]) : 400;
          const ty = match ? parseFloat(match[2] || match[4]) : 250;
          // Fonte: pequeno retângulo ao redor do Médio
          sources = [{ x: tx - 25, y: ty - 30, w: 50, h: 80, color: INK_SOFT }];
        }

        spawnParticles(particlesLayer, sources, targets, {
          count: Math.min(280, 30 + newBars.length * 20),
          duration: 0.9,
          reducedMotion,
        });
      }
    }

    // ===== BARRAS =====
    const wantedBarIds = new Set(step.bars.map((b) => b.id));
    [...barsRef.current].forEach((id) => {
      if (!wantedBarIds.has(id)) {
        const el = document.getElementById(`bar-${id}`);
        if (el) {
          gsap.to(el, {
            opacity: 0,
            duration: SHORT,
            onComplete: () => el.remove(),
          });
        }
        barsRef.current.delete(id);
      }
    });

    step.bars.forEach((b) => {
      const y = scoreToY(b.score);
      const h = BASELINE - y;
      const color = b.color ?? INK;
      const opacity = b.opacity ?? 0.78;
      placeBar(barsLayer, b.id, b.x, y, b.w, h, color, opacity, reducedMotion);
      barsRef.current.add(b.id);
    });

    // ===== RÓTULOS =====
    // Cria síncrono e anima só a opacidade pra fade-in. Não usar onComplete pra
    // criar os elementos: o cleanup do efeito mataria o tween e os labels
    // nunca apareciam (a opacidade resetava antes do onComplete disparar).
    gsap.killTweensOf(labelsLayer);
    labelsLayer.innerHTML = '';
    step.bars.forEach((b) => {
      if (!b.label && b.showScore === false) return;
      const cx = b.x + b.w / 2;
      if (b.label) {
        const lbl = make('text', {
          x: cx,
          y: BASELINE + 24,
          'text-anchor': 'middle',
          'font-family': 'Work Sans, sans-serif',
          'font-size': 12,
          'font-weight': 600,
          'letter-spacing': '0.06em',
          fill: INK_SOFT,
        });
        lbl.textContent = b.label;
        labelsLayer.appendChild(lbl);
      }
      if (b.showScore !== false) {
        const y = scoreToY(b.score);
        // Score vai DENTRO da barra, perto do topo, em cor papel — não colide
        // com a perna do Médio que pisa no topo da barra.
        const scoreEl = make('text', {
          x: cx,
          y: y + 16,
          'text-anchor': 'middle',
          'font-family': 'Work Sans, sans-serif',
          'font-size': 12,
          'font-weight': 700,
          'letter-spacing': '0.04em',
          fill: '#FCF8F0',
        });
        scoreEl.textContent = String(Math.round(b.score));
        labelsLayer.appendChild(scoreEl);
      }
    });
    if (!reducedMotion) {
      gsap.fromTo(labelsLayer, { opacity: 0 }, { opacity: 1, duration: 0.3 });
    } else {
      (labelsLayer as unknown as HTMLElement).style.opacity = '1';
    }

    // ===== MÉDIOS =====
    const wantedMedioIds = new Set(step.medios.map((m) => m.id));
    [...mediosRef.current.keys()].forEach((id) => {
      if (!wantedMedioIds.has(id)) removeMedio(id);
    });
    if (step.removeMedios) {
      step.removeMedios.forEach((id) => removeMedio(id));
    }

    step.medios.forEach((m) => {
      let x: number, y: number;
      if (m.freeX !== undefined && m.freeY !== undefined) {
        x = m.freeX;
        y = m.freeY;
      } else {
        const bar = step.bars.find((b) => b.id === m.barId);
        if (!bar) return;
        const barTop = scoreToY(bar.score);
        x = bar.x + bar.w / 2 + (m.offsetX ?? 0);
        y = barTop + (m.offsetY ?? 0);
      }
      placeMedio(mediosLayer, m.id, x, y, m.scale, m.pose, m.opacity ?? 1, reducedMotion);
    });

    // ===== OVERLAY =====
    // Mesmo padrão dos labels: criar síncrono, animar só opacidade.
    gsap.killTweensOf(overlayLayer);
    overlayLayer.innerHTML = '';
    drawOverlay(overlayLayer, step);
    if (!reducedMotion) {
      gsap.fromTo(overlayLayer, { opacity: 0 }, { opacity: 1, duration: 0.4 });
    } else {
      (overlayLayer as unknown as HTMLElement).style.opacity = '1';
    }

    // Cleanup: quando o passo muda (ou o HMR re-roda o efeito), mata todas as
    // animações pendentes nos layers e elementos pra que o próximo run comece
    // limpo. Sem isso, tweens concorrentes se acumulam.
    return () => {
      gsap.killTweensOf(labelsLayer);
      gsap.killTweensOf(overlayLayer);
      barsRef.current.forEach((id) => {
        const el = document.getElementById(`bar-${id}`);
        if (el) gsap.killTweensOf(el);
      });
      mediosRef.current.forEach((inst) => {
        gsap.killTweensOf(inst.group);
        gsap.killTweensOf(inst.state);
        if (inst.pendingFaceTimer) {
          clearTimeout(inst.pendingFaceTimer);
          inst.pendingFaceTimer = undefined;
        }
      });
      // Mata tweens de partículas vivas e remove os elementos
      [...particlesLayer.children].forEach((c) => {
        gsap.killTweensOf(c);
        c.remove();
      });
    };

    function removeMedio(id: string) {
      const inst = mediosRef.current.get(id);
      if (!inst) return;
      if (inst.pendingFaceTimer) clearTimeout(inst.pendingFaceTimer);
      gsap.to(inst.group, {
        opacity: 0,
        duration: reducedMotion ? 0.01 : 0.45,
        onComplete: () => {
          inst.group.remove();
          mediosRef.current.delete(id);
        },
      });
    }

    function placeMedio(
      layer: SVGGElement,
      id: string,
      x: number,
      y: number,
      scale: number,
      poseName: keyof typeof POSES,
      opacity: number,
      reducedMotion: boolean,
    ) {
      let inst = mediosRef.current.get(id);
      const isNew = !inst;
      if (!inst) {
        const g = document.createElementNS(SVG_NS, 'g') as SVGGElement;
        g.setAttribute('id', `medio-${id}`);
        g.style.opacity = '0';
        layer.appendChild(g);
        inst = { state: { ...POSES.neutral }, group: g, scale };
        mediosRef.current.set(id, inst);
      }
      const captured = inst;
      const target = POSES[poseName];

      // O "pé" do Médio é a base (y do quadril + thigh + shin). Aqui posicionamos
      // o quadril no ponto desejado, então y do grupo = y - alturaDePerna.
      const footOffsetY = (22 + 21) * scale;
      const tx = x;
      const ty = y - footOffsetY;

      // Idempotência: mata tweens anteriores antes de criar novos.
      gsap.killTweensOf(captured.group);
      gsap.killTweensOf(captured.state);

      // Posição: se acabou de ser criado, aparece já no destino (sem voar do
      // canto). Se já existia (continuidade entre passos), desliza pro novo lugar.
      if (isNew || reducedMotion) {
        gsap.set(captured.group, { x: tx, y: ty });
      } else {
        gsap.to(captured.group, {
          x: tx,
          y: ty,
          duration: LONG,
          ease: 'power2.inOut',
        });
      }
      gsap.to(captured.group, { opacity, duration: MED });

      // Anima os ângulos numéricos (sem `face`, que é string).
      const { face: _ignoredFace, ...numericTarget } = target;
      void _ignoredFace;
      gsap.to(captured.state, {
        duration: LONG,
        ease: 'power2.inOut',
        ...numericTarget,
        onUpdate: () => {
          renderMedioXkcdInto(captured.group, captured.state, scale, { strokeColor: INK });
        },
      });

      // A expressão facial troca no meio da transição.
      if (captured.state.face !== target.face) {
        if (captured.pendingFaceTimer) clearTimeout(captured.pendingFaceTimer);
        captured.pendingFaceTimer = window.setTimeout(
          () => {
            captured.state.face = target.face;
          },
          reducedMotion ? 0 : 300,
        );
      }

      captured.scale = scale;
    }
  }, [stepIndex, reducedMotion]);

  // Cleanup: ao desmontar, mata todas as animações pendentes.
  useEffect(() => {
    const mediosMap = mediosRef.current;
    return () => {
      mediosMap.forEach((inst) => {
        if (inst.pendingFaceTimer) clearTimeout(inst.pendingFaceTimer);
        gsap.killTweensOf(inst.group);
        gsap.killTweensOf(inst.state);
      });
    };
  }, []);

  return (
    <svg
      className="canvas"
      viewBox={`0 0 ${CANVAS_W} ${CANVAS_H}`}
      xmlns="http://www.w3.org/2000/svg"
      role="img"
      aria-label={STEPS[stepIndex]?.alt ?? 'Visualização do Médio'}
    >
      <g ref={barsLayerRef} />
      <g ref={particlesLayerRef} />
      <g ref={mediosLayerRef} />
      <g ref={labelsLayerRef} />
      <g ref={overlayLayerRef} />
      <path
        d="M 30 460 Q 200 459 400 461 T 770 460"
        stroke={INK}
        strokeWidth={1.5}
        fill="none"
        strokeLinecap="round"
        opacity={0.5}
      />
    </svg>
  );
}

// ===== Funções auxiliares =====

function placeBar(
  layer: SVGGElement,
  id: string,
  x: number,
  y: number,
  w: number,
  h: number,
  color: string,
  opacity: number,
  reducedMotion: boolean,
) {
  const seedSource = parseInt(id.replace(/\D/g, '') || '1') || 1;
  const seedBase = seedSource * 7;
  const targetD = roughBarPath(x, y, w, h, seedBase);

  let p = document.getElementById(`bar-${id}`) as SVGPathElement | null;
  const isNew = !p;
  if (!p) {
    // Cria já no tamanho final, invisível. Fade-in faz o trabalho de aparecer.
    p = make('path', {
      id: `bar-${id}`,
      d: targetD,
      fill: color,
    });
    p.style.opacity = '0';
    p.dataset.seedBase = String(seedBase);
    layer.appendChild(p);
  }

  // Idempotência contra StrictMode duplo-mount.
  gsap.killTweensOf(p);

  if (reducedMotion) {
    p.setAttribute('d', targetD);
    p.setAttribute('fill', color);
    p.style.opacity = String(opacity);
    return;
  }

  if (isNew) {
    // Só anima opacidade pra aparecer.
    gsap.to(p, { opacity, duration: 0.6, ease: 'power2.out' });
  } else {
    // Bar existente: tween d (forma) + fill + opacity num único tween.
    gsap.to(p, {
      duration: 0.75,
      attr: { d: targetD, fill: color },
      opacity,
      ease: 'power2.inOut',
    });
  }
}

function drawOverlay(layer: SVGGElement, step: Step) {
  if (step.overlay === 'dispersion') {
    const t = make('text', {
      x: 400,
      y: 120,
      'text-anchor': 'middle',
      'font-family': 'Lora, serif',
      'font-size': 17,
      'font-style': 'italic',
      fill: INK_SOFT,
    });
    t.textContent = '↓ a nuvem em volta de mim ↓';
    layer.appendChild(t);
  }

  if (step.overlay === 'two-types') {
    // Textos do overlay ficam bem no topo do canvas, acima da barra mais alta
    // do passo (que pode chegar a y=93). y=22 (eyebrow) + y=42 (subtitle).
    const addLabel = (x: number, top: string, bottom: string, topColor: string) => {
      const t1 = make('text', {
        x,
        y: 22,
        'text-anchor': 'middle',
        'font-family': 'Work Sans, sans-serif',
        'font-size': 12,
        'font-weight': 700,
        'letter-spacing': '0.15em',
        fill: topColor,
      });
      t1.textContent = top;
      layer.appendChild(t1);
      const t2 = make('text', {
        x,
        y: 42,
        'text-anchor': 'middle',
        'font-family': 'Lora, serif',
        'font-size': 13,
        'font-style': 'italic',
        fill: INK_SOFT,
      });
      t2.textContent = bottom;
      layer.appendChild(t2);
    };
    addLabel(200, 'ESTRUTURAL', 'injustiça anterior à prova', '#5A3825');
    addLabel(400, 'INDIVIDUAL', 'diferença esperada', INK_SOFT);
    addLabel(600, 'ESTRUTURAL', 'injustiça anterior à prova', '#A82E2E');
  }

  if (step.overlay === 'final') {
    const firstBar = step.bars[0];
    const lastBar = step.bars[step.bars.length - 1];
    const firstX = firstBar.x + firstBar.w / 2;
    const lastX = lastBar.x + lastBar.w / 2;
    const diff = Math.round(lastBar.score - firstBar.score);
    const diffText = make('text', {
      x: 400,
      y: BASELINE + 58,
      'text-anchor': 'middle',
      'font-family': 'Lora, serif',
      'font-size': 15,
      'font-style': 'italic',
      fill: INK_SOFT,
    });
    diffText.textContent = `${diff} pontos · mesma média nacional · vidas distintas`;
    layer.appendChild(diffText);
    const lineEl = make('line', {
      x1: firstX + 20,
      y1: BASELINE + 44,
      x2: lastX - 20,
      y2: BASELINE + 44,
      stroke: INK_SOFT,
      'stroke-width': 1,
      'stroke-dasharray': '4,4',
    });
    layer.appendChild(lineEl);
  }
}
