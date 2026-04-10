import { describe, it, expect } from 'vitest';
import { Version, VersionState } from '../../src/version/Version.ts';

describe('Version', () => {

  // ── Semantic Booleans ──

  it('is live when state is READY_FOR_SALE', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.ReadyForSale, 'IOS', {});
    expect(v.isLive).toBe(true);
    expect(v.isEditable).toBe(false);
    expect(v.isPending).toBe(false);
    expect(v.isRejected).toBe(false);
  });

  it('is editable when state is PREPARE_FOR_SUBMISSION', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {});
    expect(v.isEditable).toBe(true);
    expect(v.isLive).toBe(false);
  });

  it('is pending when waiting for review', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.WaitingForReview, 'IOS', {});
    expect(v.isPending).toBe(true);
  });

  it('is pending when in review', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.InReview, 'IOS', {});
    expect(v.isPending).toBe(true);
  });

  it('is rejected when state is REJECTED', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.Rejected, 'IOS', {});
    expect(v.isRejected).toBe(true);
  });

  // ── Capability Checks (from API affordances) ──

  it('can submit when server provides submitForReview affordance', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {
      submitForReview: 'asc versions submit --id v-1',
    });
    expect(v.canSubmit).toBe(true);
  });

  it('cannot submit when server omits submitForReview affordance', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {});
    expect(v.canSubmit).toBe(false);
  });

  it('can release when server provides releaseVersion affordance', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.PendingDeveloperRelease, 'IOS', {
      releaseVersion: 'asc versions release --id v-1',
    });
    expect(v.canRelease).toBe(true);
  });

  it('can edit when server provides updateVersion affordance', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {
      updateVersion: 'asc versions update --id v-1',
    });
    expect(v.canEdit).toBe(true);
  });

  // ── State Transitions ──

  it('can transition from prepare to waiting for review', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.PrepareForSubmission, 'IOS', {});
    expect(v.canTransitionTo(VersionState.WaitingForReview)).toBe(true);
    expect(v.canTransitionTo(VersionState.ReadyForSale)).toBe(false);
  });

  it('can transition from rejected back to prepare', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.Rejected, 'IOS', {});
    expect(v.canTransitionTo(VersionState.PrepareForSubmission)).toBe(true);
  });

  it('can transition from pending release to ready for sale', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.PendingDeveloperRelease, 'IOS', {});
    expect(v.canTransitionTo(VersionState.ReadyForSale)).toBe(true);
  });

  it('live version cannot transition anywhere', () => {
    const v = new Version('v-1', 'app-1', '2.0', VersionState.ReadyForSale, 'IOS', {});
    expect(v.canTransitionTo(VersionState.PrepareForSubmission)).toBe(false);
    expect(v.canTransitionTo(VersionState.WaitingForReview)).toBe(false);
  });

  // ── Hydration ──

  it('hydrates from API JSON', () => {
    const json = {
      id: 'v-1',
      appId: 'app-1',
      versionString: '2.0',
      state: 'PREPARE_FOR_SUBMISSION',
      platform: 'IOS',
      affordances: { submitForReview: 'asc versions submit --id v-1' },
    };

    const v = Version.fromJSON(json);

    expect(v.id).toBe('v-1');
    expect(v.appId).toBe('app-1');
    expect(v.versionString).toBe('2.0');
    expect(v.isEditable).toBe(true);
    expect(v.canSubmit).toBe(true);
  });

  it('hydrates with empty affordances when missing from JSON', () => {
    const json = {
      id: 'v-1',
      appId: 'app-1',
      versionString: '1.0',
      state: 'READY_FOR_SALE',
      platform: 'IOS',
    };

    const v = Version.fromJSON(json);

    expect(v.affordances).toEqual({});
    expect(v.canSubmit).toBe(false);
    expect(v.canRelease).toBe(false);
    expect(v.isLive).toBe(true);
  });
});
