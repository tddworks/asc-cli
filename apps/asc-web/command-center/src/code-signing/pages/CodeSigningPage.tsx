import { useState } from 'react';
import { useCertificates, useBundleIds, useProfiles, useDevices } from '../CodeSigning.hooks.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

type Tab = 'bundles' | 'certificates' | 'devices' | 'profiles';

export default function CodeSigningPage() {
  const [tab, setTab] = useState<Tab>('certificates');

  return (
    <div>
      <h2>Code Signing</h2>
      <div className="detail-tabs">
        <button className={`filter-btn ${tab === 'bundles' ? 'active' : ''}`} onClick={() => setTab('bundles')}>
          Bundle IDs
        </button>
        <button className={`filter-btn ${tab === 'certificates' ? 'active' : ''}`} onClick={() => setTab('certificates')}>
          Certificates
        </button>
        <button className={`filter-btn ${tab === 'devices' ? 'active' : ''}`} onClick={() => setTab('devices')}>
          Devices
        </button>
        <button className={`filter-btn ${tab === 'profiles' ? 'active' : ''}`} onClick={() => setTab('profiles')}>
          Profiles
        </button>
      </div>
      {tab === 'bundles' && <BundleIdsTab />}
      {tab === 'certificates' && <CertificatesTab />}
      {tab === 'devices' && <DevicesTab />}
      {tab === 'profiles' && <ProfilesTab />}
    </div>
  );
}

function BundleIdsTab() {
  const { bundleIds, loading, error } = useBundleIds();
  if (loading) return <div className="spinner">Loading bundle IDs...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div className="card">
      <div className="toolbar">
        <h3>Bundle IDs</h3>
      </div>
      <div className="table-wrapper">
        <table className="data-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Identifier</th>
              <th>Platform</th>
              <th>Seed ID</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {bundleIds.map((b) => (
              <tr key={b.id}>
                <td>{b.name}</td>
                <td className="cell-mono">{b.identifier}</td>
                <td>{b.platform}</td>
                <td className="cell-mono">{b.seedId}</td>
                <td><AffordanceBar affordances={b.affordances} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function CertificatesTab() {
  const { certificates, loading, error } = useCertificates();
  if (loading) return <div className="spinner">Loading certificates...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div className="card">
      <div className="toolbar">
        <h3>Certificates</h3>
      </div>
      <div className="table-wrapper">
        <table className="data-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Type</th>
              <th>Serial</th>
              <th>Expires</th>
              <th>Status</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {certificates.map((c) => (
              <tr key={c.id}>
                <td>{c.name}</td>
                <td><span className="platform-badge">{c.certificateType}</span></td>
                <td className="cell-mono">{c.serialNumber}</td>
                <td>{c.expirationDate}</td>
                <td><span className={`status ${c.isValid ? 'live' : 'rejected'}`}>{c.status}</span></td>
                <td><AffordanceBar affordances={c.affordances} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function DevicesTab() {
  const { devices, loading, error } = useDevices();
  if (loading) return <div className="spinner">Loading devices...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div className="card">
      <div className="toolbar">
        <h3>Devices</h3>
      </div>
      <div className="table-wrapper">
        <table className="data-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>UDID</th>
              <th>Class</th>
              <th>Model</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {devices.map((d) => (
              <tr key={d.id}>
                <td>{d.name}</td>
                <td className="cell-mono" style={{ maxWidth: 160, overflow: 'hidden', textOverflow: 'ellipsis' }}>{d.udid}</td>
                <td><span className="platform-badge">{d.deviceClass}</span></td>
                <td>{d.model}</td>
                <td><span className={`status ${d.status === 'ENABLED' ? 'live' : 'expired'}`}>{d.status}</span></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}

function ProfilesTab() {
  const { profiles, loading, error } = useProfiles();
  if (loading) return <div className="spinner">Loading profiles...</div>;
  if (error) return <div className="error">Error: {error.message}</div>;

  return (
    <div className="card">
      <div className="toolbar">
        <h3>Profiles</h3>
      </div>
      <div className="table-wrapper">
        <table className="data-table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Type</th>
              <th>State</th>
              <th>Expires</th>
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            {profiles.map((p) => (
              <tr key={p.id}>
                <td>{p.name}</td>
                <td><span className="platform-badge">{p.profileType}</span></td>
                <td><span className={`status ${p.profileState === 'ACTIVE' ? 'live' : 'expired'}`}>{p.profileState}</span></td>
                <td>{p.expirationDate}</td>
                <td><AffordanceBar affordances={p.affordances} /></td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
