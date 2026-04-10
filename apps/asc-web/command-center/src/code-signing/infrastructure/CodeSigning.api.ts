import { Certificate } from '../Certificate.ts';
import { BundleID } from '../BundleID.ts';
import { Profile } from '../Profile.ts';
import { Device } from '../Device.ts';
import { apiClient, type DataMode } from '../../shared/api-client.tsx';

export async function fetchCertificates(mode: DataMode): Promise<Certificate[]> {
  if (mode === 'mock') {
    const { mockCertificates } = await import('./CodeSigning.mock.ts');
    return mockCertificates();
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>('/api/v1/certificates');
  return json.data.map(Certificate.fromJSON);
}

export async function fetchBundleIds(mode: DataMode): Promise<BundleID[]> {
  if (mode === 'mock') {
    const { mockBundleIds } = await import('./CodeSigning.mock.ts');
    return mockBundleIds();
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>('/api/v1/bundle-ids');
  return json.data.map(BundleID.fromJSON);
}

export async function fetchProfiles(mode: DataMode): Promise<Profile[]> {
  if (mode === 'mock') {
    const { mockProfiles } = await import('./CodeSigning.mock.ts');
    return mockProfiles();
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>('/api/v1/profiles');
  return json.data.map(Profile.fromJSON);
}

export async function fetchDevices(mode: DataMode): Promise<Device[]> {
  if (mode === 'mock') {
    const { mockDevices } = await import('./CodeSigning.mock.ts');
    return mockDevices();
  }
  const json = await apiClient.get<{ data: Record<string, unknown>[] }>('/api/v1/devices');
  return json.data.map(Device.fromJSON);
}
