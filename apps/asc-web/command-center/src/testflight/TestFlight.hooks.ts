import { useState, useEffect } from 'react';
import { BetaGroup } from './BetaGroup.ts';
import { fetchBetaGroups } from './infrastructure/TestFlight.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useTestFlight(appId: string) {
  const [betaGroups, setBetaGroups] = useState<BetaGroup[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchBetaGroups(appId, mode)
      .then(setBetaGroups)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [appId, mode]);

  return { betaGroups, loading, error };
}
