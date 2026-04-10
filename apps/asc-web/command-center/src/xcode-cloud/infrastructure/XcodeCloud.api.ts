import { CiProduct } from '../CiProduct.ts';
import { CiWorkflow } from '../CiWorkflow.ts';
import { apiClient, type DataMode } from '../../shared/api-client.tsx';

export async function fetchProducts(mode: DataMode): Promise<CiProduct[]> {
  if (mode === 'mock') {
    const { mockProducts } = await import('./XcodeCloud.mock.ts');
    return mockProducts();
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>('/api/v1/ci-products');
  return json.data.map(CiProduct.fromJSON);
}

export async function fetchWorkflows(productId: string, mode: DataMode): Promise<CiWorkflow[]> {
  if (mode === 'mock') {
    const { mockWorkflows } = await import('./XcodeCloud.mock.ts');
    return mockWorkflows(productId);
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>(`/api/v1/ci-products/${productId}/workflows`);
  return json.data.map(CiWorkflow.fromJSON);
}
