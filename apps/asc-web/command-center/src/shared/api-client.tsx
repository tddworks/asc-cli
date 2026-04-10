import { createContext, useContext, useState, useCallback, useEffect, type ReactNode } from 'react';

export type DataMode = 'mock' | 'rest';

// --- Data-mode context ---

const DataModeContext = createContext<{
  mode: DataMode;
  toggleMode: () => void;
}>({ mode: 'mock', toggleMode: () => {} });

export function DataModeProviderComponent({ children }: { children: ReactNode }) {
  const [mode, setMode] = useState<DataMode>('mock');
  const toggleMode = useCallback(() => setMode(m => m === 'mock' ? 'rest' : 'mock'), []);

  // Auto-detect backend on mount — probe /api/v1
  useEffect(() => {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 2000);

    fetch('/api/v1', { signal: controller.signal })
      .then(resp => {
        if (resp.ok) setMode('rest');
      })
      .catch(() => {
        // Backend not running — stay in mock mode
      })
      .finally(() => clearTimeout(timeout));
  }, []);

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

/** Convert REST _links to flat affordances on every item in a response */
function normalizeLinks(data: unknown): unknown {
  if (Array.isArray(data)) return data.map(normalizeLinks);
  if (data && typeof data === 'object') {
    const obj = data as Record<string, unknown>;
    // Convert _links → affordances
    if (obj._links && !obj.affordances) {
      const links = obj._links as Record<string, { href: string }>;
      const affordances: Record<string, string> = {};
      for (const [key, val] of Object.entries(links)) {
        affordances[key] = typeof val === 'string' ? val : val.href;
      }
      obj.affordances = affordances;
    }
    // Recurse into nested data
    if (obj.data) obj.data = normalizeLinks(obj.data);
    return obj;
  }
  return data;
}

export const apiClient = {
  async get<T>(path: string): Promise<T> {
    const res = await fetch(path);
    if (!res.ok) throw new ApiError(res.status, await res.text());
    const json = await res.json();
    return normalizeLinks(json) as T;
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
