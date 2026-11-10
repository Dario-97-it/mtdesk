# MTDesk — Brand & Tema (fonte: marketingtools.digital)

Design system reale estratto dal sito. Usare questi token per il tema glassmorphism
del client MTDesk (Flutter) e per qualsiasi UI del progetto.

## Sfondi (dark base — glassmorphism)
| Token | HEX | Uso |
|---|---|---|
| bg-deep | `#0A0A14` | sfondo finestra |
| bg-surface | `#0F0F1E` | pannelli |
| bg-elevated | `#161628` | barre/elevati |
| bg-card | `#1A1A2E` | card / superfici glass |

## Gradiente brand (elemento firma)
```
--gradient-brand:      linear-gradient(135deg, #2ECC71 0%, #00BCD4 25%, #2196F3 50%, #9C27B0 75%, #FF9800 100%)
--gradient-brand-cool: linear-gradient(135deg, #2ECC71 0%, #00BCD4 50%, #2196F3 100%)
--gradient-brand-warm: linear-gradient(135deg, #FF9800 0%, #F44336 50%, #E91E63 100%)
```

## Accenti
`#00BCD4` ciano (primario tech) · `#2ECC71` verde · `#2196F3` blu ·
`#9C27B0` viola · `#FF9800` arancio · `#F44336` rosso · `#E91E63` rosa · `#FFEB3B` giallo

## Testo & effetti glass
- text-primary: `rgba(255,255,255,.95)`  · text-muted: `#A0A0B0`
- glow brand: `0 0 30px rgba(0,188,212,.15), 0 0 60px rgba(156,39,176,.08)`
- glass: superfici `#1A1A2E` con bordo `rgba(255,255,255,.10)` + `backdrop-filter: blur(12–20px)`
- radial glows di sfondo: verde/viola/blu al 5–8% agli angoli
- Font: **Inter** (fallback: system-ui, 'Segoe UI', Roboto)

## Ricetta glassmorphism (card)
```
background: rgba(26,26,46,.55);
border: 1px solid rgba(255,255,255,.10);
backdrop-filter: blur(16px);
border-radius: 16px;
box-shadow: 0 8px 32px rgba(0,0,0,.35), 0 0 30px rgba(0,188,212,.10);
```
