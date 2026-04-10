import { BetaGroup } from '../BetaGroup.ts';
import { AffordanceBar } from '../../shared/components/AffordanceBar.tsx';

interface Props {
  group: BetaGroup;
}

export function BetaGroupCard({ group }: Props) {
  return (
    <tr>
      <td>{group.name}</td>
      <td>
        <span className={`status ${group.isInternal ? 'review' : 'live'}`}>
          {group.isInternal ? 'Internal' : 'External'}
        </span>
      </td>
      <td>{group.hasPublicLink ? 'Enabled' : 'Disabled'}</td>
      <td><AffordanceBar affordances={group.affordances} /></td>
    </tr>
  );
}
