import { useState, useEffect } from 'react';
import { IrisApp } from './IrisApp.ts';
import { fetchIrisApps } from './infrastructure/Iris.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useIrisApps() {
  const [apps, setApps] = useState<IrisApp[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchIrisApps(mode).then(setApps).catch(setError).finally(() => setLoading(false));
  }, [mode]);

  return { apps, loading, error };
}
