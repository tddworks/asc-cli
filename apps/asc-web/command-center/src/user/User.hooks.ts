import { useState, useEffect } from 'react';
import { User } from './User.ts';
import { fetchUsers } from './infrastructure/User.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useUsers() {
  const [users, setUsers] = useState<User[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchUsers(mode).then(setUsers).catch(setError).finally(() => setLoading(false));
  }, [mode]);

  return { users, loading, error };
}
