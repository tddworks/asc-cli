import { createContext, useContext } from 'react';

export type DataMode = 'rest' | 'mock';

const DataModeContext = createContext<DataMode>('rest');
export const DataModeProvider = DataModeContext.Provider;
export const useDataMode = () => useContext(DataModeContext);

class ApiError extends Error {
  constructor(public status: number, message: string) {
    super(message);
    this.name = 'ApiError';
  }
}

const BASE_URL = '';

export const apiClient = {
  async get<T>(path: string): Promise<T> {
    const res = await fetch(`${BASE_URL}${path}`);
    if (!res.ok) throw new ApiError(res.status, await res.text());
    return res.json();
  },

  async post<T>(path: string, body: unknown): Promise<T> {
    const res = await fetch(`${BASE_URL}${path}`, {
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
