// Pontinhos de progresso na rodapé da peça. Clicáveis pra pular pra um passo.

interface ProgressDotsProps {
  total: number;
  current: number;
  onGoTo: (idx: number) => void;
}

export function ProgressDots({ total, current, onGoTo }: ProgressDotsProps) {
  return (
    <div className="progress-dots" role="tablist" aria-label="Progresso pela peça">
      {Array.from({ length: total }, (_, i) => (
        <button
          key={i}
          type="button"
          className={`dot${i === current ? ' active' : ''}${i < current ? ' past' : ''}`}
          onClick={() => onGoTo(i)}
          role="tab"
          aria-selected={i === current}
          aria-label={`Ir para o ato ${i + 1} de ${total}`}
        />
      ))}
    </div>
  );
}
