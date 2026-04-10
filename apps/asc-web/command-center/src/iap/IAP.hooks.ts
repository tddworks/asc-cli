import { useState, useEffect } from 'react';
import { InAppPurchase } from './InAppPurchase.ts';
import { fetchIAPs } from './infrastructure/IAP.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useInAppPurchases(appId: string) {
  const [iaps, setIaps] = useState<InAppPurchase[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchIAPs(appId, mode).then(setIaps).catch(setError).finally(() => setLoading(false));
  }, [appId, mode]);

  return { iaps, loading, error };
}
