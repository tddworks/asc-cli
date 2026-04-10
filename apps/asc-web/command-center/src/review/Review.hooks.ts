import { useState, useEffect } from 'react';
import { Review } from './Review.ts';
import { fetchReviews } from './infrastructure/Review.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useReviews(appId: string) {
  const [reviews, setReviews] = useState<Review[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchReviews(appId, mode)
      .then(setReviews)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [appId, mode]);

  return { reviews, loading, error };
}
