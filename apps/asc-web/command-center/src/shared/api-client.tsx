import { createContext, useContext, useState, useCallback, type ReactNode } from 'react';

export type DataMode = 'mock' | 'rest';

// --- Data-mode context ---

const DataModeContext = createContext<{
  mode: DataMode;
  toggleMode: () => void;
}>({ mode: 'mock', toggleMode: () => {} });

export function DataModeProviderComponent({ children }: { children: ReactNode }) {
  const [mode, setMode] = useState<DataMode>('mock');
  const toggleMode = useCallback(() => setMode(m => m === 'mock' ? 'rest' : 'mock'), []);
  return (
    <DataModeContext.Provider value={{ mode, toggleMode }}>
      {children}
    </DataModeContext.Provider>
  );
}

/** Returns the current data mode string ('mock' | 'rest') */
export const useDataMode = () => useContext(DataModeContext).mode;

/** Returns a function to toggle between mock and rest modes */
export const useToggleMode = () => useContext(DataModeContext).toggleMode;

// --- Command-log context ---

export type CommandLogEntry = { type: 'prompt' | 'output' | 'error'; text: string };

const CommandLogContext = createContext<{
  entries: CommandLogEntry[];
  addEntry: (entry: CommandLogEntry) => void;
}>({ entries: [], addEntry: () => {} });

export function CommandLogProvider({ children }: { children: ReactNode }) {
  const [entries, setEntries] = useState<CommandLogEntry[]>([
    { type: 'output', text: 'Ready. Run commands from the UI to see logs here.' },
  ]);
  const addEntry = useCallback((entry: CommandLogEntry) => {
    setEntries(prev => [...prev, entry]);
  }, []);
  return (
    <CommandLogContext.Provider value={{ entries, addEntry }}>
      {children}
    </CommandLogContext.Provider>
  );
}

export const useCommandLog = () => useContext(CommandLogContext);

// --- API client ---

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'ApiError';
  }
}

export const apiClient = {
  async get<T>(path: string): Promise<T> {
    const res = await fetch(path);
    if (!res.ok) throw new ApiError(res.status, await res.text());
    return res.json();
  },

  async post<T>(path: string, body: unknown): Promise<T> {
    const res = await fetch(path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    if (!res.ok) throw new ApiError(res.status, await res.text());
    return res.json();
  },

  async runCommand(command: string): Promise<{ stdout: string; stderr: string; exit_code: number }> {
    return this.post('/api/run', { command: `asc ${command}` });
  },
};
