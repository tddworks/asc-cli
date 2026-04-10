import { useState, useEffect } from 'react';
import { App } from './App.ts';
import { fetchApps, fetchApp } from './infrastructure/App.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useApps() {
  const [apps, setApps] = useState<App[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchApps(mode)
      .then(setApps)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [mode]);

  return { apps, loading, error };
}

export function useApp(appId: string) {
  const [app, setApp] = useState<App | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchApp(appId, mode)
      .then(setApp)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [appId, mode]);

  return { app, loading, error };
}
