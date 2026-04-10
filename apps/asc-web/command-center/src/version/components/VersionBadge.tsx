import { Version, VersionState } from '../Version.ts';

interface Props {
  version: Version;
}

const stateMap: Record<VersionState, [string, string]> = {
  [VersionState.ReadyForSale]: ['live', 'Ready for Sale'],
  [VersionState.PrepareForSubmission]: ['pending', 'Prepare for Submission'],
  [VersionState.WaitingForReview]: ['review', 'Waiting for Review'],
  [VersionState.InReview]: ['review', 'In Review'],
  [VersionState.Rejected]: ['rejected', 'Rejected'],
  [VersionState.DeveloperRejected]: ['rejected', 'Developer Rejected'],
  [VersionState.PendingDeveloperRelease]: ['pending', 'Pending Release'],
};

export function VersionBadge({ version }: Props) {
  const [cssClass, label] = stateMap[version.state] ?? ['', version.state];

  return (
    <span className="version-badge">
      <span className={`status ${cssClass}`}>{label}</span>
      {version.canSubmit && <button className="btn btn-sm">Submit</button>}
      {version.canRelease && <button className="btn btn-sm">Release</button>}
    </span>
  );
}
