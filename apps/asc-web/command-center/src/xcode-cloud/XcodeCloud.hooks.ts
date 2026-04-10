import { useState, useEffect } from 'react';
import { CiProduct } from './CiProduct.ts';
import { CiWorkflow } from './CiWorkflow.ts';
import { fetchProducts, fetchWorkflows } from './infrastructure/XcodeCloud.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useProducts() {
  const [products, setProducts] = useState<CiProduct[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchProducts(mode)
      .then(setProducts)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [mode]);

  return { products, loading, error };
}

export function useWorkflows(productId: string) {
  const [workflows, setWorkflows] = useState<CiWorkflow[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    if (!productId) return;
    setLoading(true);
    fetchWorkflows(productId, mode)
      .then(setWorkflows)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [productId, mode]);

  return { workflows, loading, error };
}
