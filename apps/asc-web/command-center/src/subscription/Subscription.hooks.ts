import { useState, useEffect } from 'react';
import { SubscriptionGroup } from './SubscriptionGroup.ts';
import { fetchSubscriptionGroups } from './infrastructure/Subscription.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useSubscriptionGroups(appId: string) {
  const [groups, setGroups] = useState<SubscriptionGroup[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchSubscriptionGroups(appId, mode).then(setGroups).catch(setError).finally(() => setLoading(false));
  }, [appId, mode]);

  return { groups, loading, error };
}
