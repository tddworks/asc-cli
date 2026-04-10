import { Build } from '../Build.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

interface Props {
  build: Build;
}

function statusBadge(build: Build): [string, string] {
  switch (build.processingState) {
    case 'VALID': return ['live', 'Valid'];
    case 'PROCESSING': return ['processing', 'Processing'];
    case 'INVALID': return ['rejected', 'Invalid'];
    case 'FAILED': return ['rejected', 'Failed'];
    default: return ['draft', build.processingState];
  }
}

export function BuildRow({ build }: Props) {
  const [cls, label] = statusBadge(build);

  return (
    <tr>
      <td className="cell-primary">{build.version}</td>
      <td>{build.preReleaseVersion}</td>
      <td><span className={`status ${build.isUsable ? 'live' : 'draft'}`}>{build.isUsable ? 'Yes' : 'No'}</span></td>
      <td><span className={`status ${cls}`}>{label}</span></td>
      <td><span className={`status ${build.isExpired ? 'rejected' : 'live'}`}>{build.isExpired ? 'Expired' : 'Active'}</span></td>
      <td>{build.uploadedDate}</td>
      <td><AffordanceBar affordances={build.affordances} /></td>
    </tr>
  );
}
