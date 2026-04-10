import { Build } from '../Build.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

interface Props {
  build: Build;
}

export function BuildRow({ build }: Props) {
  return (
    <tr>
      <td className="cell-mono">{build.displayName}</td>
      <td>{build.isUsable ? 'Yes' : 'No'}</td>
      <td>
        {build.isValid && <span className="badge badge-green">Valid</span>}
        {build.isProcessing && <span className="badge badge-yellow">Processing</span>}
        {build.processingState === 'INVALID' && <span className="badge badge-red">Invalid</span>}
        {build.processingState === 'FAILED' && <span className="badge badge-red">Failed</span>}
      </td>
      <td>{build.isExpired ? <span className="badge badge-red">Expired</span> : 'No'}</td>
      <td>{build.uploadedDate}</td>
      <td><AffordanceBar affordances={build.affordances} /></td>
    </tr>
  );
}
