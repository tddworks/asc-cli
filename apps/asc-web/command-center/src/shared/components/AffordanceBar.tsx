import type { Affordances } from '../types.ts';
import { apiClient, useCommandLog, useDataMode } from '../api-client.tsx';

export function AffordanceBar({ affordances }: { affordances: Affordances }) {
  const entries = Object.entries(affordances);
  const { addEntry } = useCommandLog();
  const mode = useDataMode();

  if (entries.length === 0) return null;

  const handleClick = async (_label: string, command: string) => {
    if (mode === 'mock') {
      addEntry({ type: 'prompt', text: `$ ${command}` });
      addEntry({ type: 'output', text: `[mock] Would execute: ${command}` });
      return;
    }

    // In REST mode, execute the command
    addEntry({ type: 'prompt', text: `$ ${command}` });
    try {
      const result = await apiClient.runCommand(command.replace(/^asc /, ''));
      if (result.stdout) addEntry({ type: 'output', text: result.stdout });
      if (result.stderr) addEntry({ type: 'error', text: result.stderr });
    } catch (err) {
      addEntry({ type: 'error', text: String(err) });
    }
  };

  return (
    <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap' }}>
      {entries.map(([label, command]) => (
        <button
          key={label}
          className="btn btn-secondary btn-sm"
          title={command}
          onClick={() => handleClick(label, command)}
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
