import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { VersionBadge } from '../../src/version/components/VersionBadge.tsx';
import { Version, VersionState } from '../../src/version/Version.ts';

describe('VersionBadge', () => {

  it('shows Ready for Sale status for live version', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.ReadyForSale, 'IOS', {});

    render(<VersionBadge version={v} />);

    expect(screen.getByText('Ready for Sale')).toBeInTheDocument();
  });

  it('shows Prepare for Submission status for editable version', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {});

    render(<VersionBadge version={v} />);

    expect(screen.getByText('Prepare for Submission')).toBeInTheDocument();
  });

  it('shows Waiting for Review status', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.WaitingForReview, 'IOS', {});

    render(<VersionBadge version={v} />);

    expect(screen.getByText('Waiting for Review')).toBeInTheDocument();
  });

  it('shows Rejected status for rejected version', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.Rejected, 'IOS', {});

    render(<VersionBadge version={v} />);

    expect(screen.getByText('Rejected')).toBeInTheDocument();
  });

  it('applies live css class for ready for sale', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.ReadyForSale, 'IOS', {});

    const { container } = render(<VersionBadge version={v} />);

    expect(container.querySelector('.status.live')).not.toBeNull();
  });

  it('applies rejected css class for rejected', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.Rejected, 'IOS', {});

    const { container } = render(<VersionBadge version={v} />);

    expect(container.querySelector('.status.rejected')).not.toBeNull();
  });

  it('shows Submit button when version can submit', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {
      submitForReview: 'asc versions submit --id v-1',
    });

    render(<VersionBadge version={v} />);

    expect(screen.getByRole('button', { name: /submit/i })).toBeInTheDocument();
  });

  it('does not show Submit button when server omits affordance', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {});

    render(<VersionBadge version={v} />);

    expect(screen.queryByRole('button', { name: /submit/i })).not.toBeInTheDocument();
  });

  it('shows Release button when version can release', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.PendingDeveloperRelease, 'IOS', {
      releaseVersion: 'asc versions release --id v-1',
    });

    render(<VersionBadge version={v} />);

    expect(screen.getByRole('button', { name: /release/i })).toBeInTheDocument();
  });
});
