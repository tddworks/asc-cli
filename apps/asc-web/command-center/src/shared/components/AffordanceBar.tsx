import type { Affordances } from '../types.ts';

interface Props {
  affordances: Affordances;
}

export function AffordanceBar({ affordances }: Props) {
  const entries = Object.entries(affordances);
  if (entries.length === 0) return null;

  return (
    <div className="affordance-bar">
      {entries.map(([label, command]) => (
        <button
          key={label}
          className="affordance-btn"
          title={command}
        >
          {formatLabel(label)}
        </button>
      ))}
    </div>
  );
}

function formatLabel(key: string): string {
  return key
    .replace(/([A-Z])/g, ' $1')
    .replace(/^./, (s) => s.toUpperCase())
    .trim();
}
