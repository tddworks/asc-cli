import { useState, useEffect } from 'react';
import { Simulator } from './Simulator.ts';
import { fetchSimulators } from './infrastructure/Simulator.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useSimulators() {
  const [simulators, setSimulators] = useState<Simulator[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchSimulators(mode)
      .then(setSimulators)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [mode]);

  return { simulators, loading, error };
}
