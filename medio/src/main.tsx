import { createRoot } from 'react-dom/client';
import './styles.css';
import { App } from './App';

const rootEl = document.getElementById('root');
if (!rootEl) throw new Error('Elemento #root não encontrado em index.html');

// StrictMode desligado intencionalmente: ele dispara o useEffect duas vezes em
// dev, o que cria animações GSAP concorrentes mesmo com killTweensOf, porque o
// segundo dispatch acontece sincronicamente após o primeiro, sem dar tempo
// pro tween renderizar a animação completa. O motor do canvas é imperativo e
// não se beneficia do StrictMode pra detectar bugs de React; logo, descartar.
createRoot(rootEl).render(<App />);
