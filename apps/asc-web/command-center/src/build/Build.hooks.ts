import { useState, useEffect } from 'react';
import { Build } from './Build.ts';
import { fetchBuilds } from './infrastructure/Build.api.ts';
import { useDataMode } from '../shared/api-client.ts';

export function useBuilds(appId: string) {
  const [builds, setBuilds] = useState<Build[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchBuilds(appId, mode)
      .then(setBuilds)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [appId, mode]);

  return { builds, loading, error };
}
