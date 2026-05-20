// Pontinhos de progresso no rodapé da peça. Clicáveis pra pular pra um passo.
// Cada dot mostra o título do ato em tooltip (hover/focus) pra ajudar a orientar
// quem está pulando entre atos. Os atos são agrupados visualmente em 3 blocos
// (apresentação · cortes · distinção+pedido) com pequeno gap entre eles.

interface ProgressDotsProps {
  total: number;
  current: number;
  onGoTo: (idx: number) => void;
  titles?: string[];                  // título por ato, na ordem dos passos
  blockStartIndices?: number[];       // índices que iniciam novo bloco visual
}

export function ProgressDots({
  total,
  current,
  onGoTo,
  titles = [],
  blockStartIndices = [],
}: ProgressDotsProps) {
  return (
    <div className="progress-dots" role="tablist" aria-label="Progresso pela peça">
      {Array.from({ length: total }, (_, i) => {
        const title = titles[i] ?? '';
        const isBlockStart = blockStartIndices.includes(i);
        const aria = title
          ? `Ir para o ato ${i + 1} de ${total}: ${title}`
          : `Ir para o ato ${i + 1} de ${total}`;
        return (
          <button
            key={i}
            type="button"
            className={`dot${i === current ? ' active' : ''}${i < current ? ' past' : ''}${isBlockStart ? ' block-start' : ''}`}
            onClick={() => onGoTo(i)}
            role="tab"
            aria-selected={i === current}
            aria-label={aria}
            title={title ? `Ato ${i + 1}: ${title}` : `Ato ${i + 1}`}
          />
        );
      })}
    </div>
  );
}
