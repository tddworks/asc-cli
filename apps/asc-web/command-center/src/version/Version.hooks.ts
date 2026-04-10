import { useState, useEffect } from 'react';
import { Version } from './Version.ts';
import { fetchVersions } from './infrastructure/Version.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useVersions(appId: string) {
  const [versions, setVersions] = useState<Version[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchVersions(appId, mode)
      .then(setVersions)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [appId, mode]);

  return { versions, loading, error };
}
