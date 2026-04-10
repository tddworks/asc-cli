import { useState, useEffect } from 'react';
import { Certificate } from './Certificate.ts';
import { BundleID } from './BundleID.ts';
import { Profile } from './Profile.ts';
import { Device } from './Device.ts';
import { fetchCertificates, fetchBundleIds, fetchProfiles, fetchDevices } from './infrastructure/CodeSigning.api.ts';
import { useDataMode } from '../shared/api-client.tsx';

export function useCertificates() {
  const [certificates, setCertificates] = useState<Certificate[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchCertificates(mode)
      .then(setCertificates)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [mode]);

  return { certificates, loading, error };
}

export function useBundleIds() {
  const [bundleIds, setBundleIds] = useState<BundleID[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchBundleIds(mode)
      .then(setBundleIds)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [mode]);

  return { bundleIds, loading, error };
}

export function useProfiles() {
  const [profiles, setProfiles] = useState<Profile[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchProfiles(mode)
      .then(setProfiles)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [mode]);

  return { profiles, loading, error };
}

export function useDevices() {
  const [devices, setDevices] = useState<Device[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<Error | null>(null);
  const mode = useDataMode();

  useEffect(() => {
    setLoading(true);
    fetchDevices(mode)
      .then(setDevices)
      .catch(setError)
      .finally(() => setLoading(false));
  }, [mode]);

  return { devices, loading, error };
}
