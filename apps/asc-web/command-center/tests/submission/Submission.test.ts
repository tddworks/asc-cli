import { describe, it, expect } from 'vitest';
import { Submission, SubmissionState } from '../../src/submission/Submission.ts';

describe('Submission', () => {

  // ── Semantic Booleans ──

  it('is ready when state is READY_FOR_REVIEW', () => {
    const s = new Submission('s-1', 'v-1', SubmissionState.ReadyForReview, {});
    expect(s.isReady).toBe(true);
    expect(s.isWaiting).toBe(false);
    expect(s.isAccepted).toBe(false);
  });

  it('is waiting when state is WAITING_FOR_REVIEW', () => {
    const s = new Submission('s-1', 'v-1', SubmissionState.WaitingForReview, {});
    expect(s.isWaiting).toBe(true);
    expect(s.isReady).toBe(false);
  });

  it('is accepted when state is ACCEPTED', () => {
    const s = new Submission('s-1', 'v-1', SubmissionState.Accepted, {});
    expect(s.isAccepted).toBe(true);
    expect(s.isRejected).toBe(false);
  });

  it('is in review when state is IN_REVIEW', () => {
    const s = new Submission('s-1', 'v-1', SubmissionState.InReview, {});
    expect(s.isInReview).toBe(true);
    expect(s.isReady).toBe(false);
  });

  it('is rejected when state is REJECTED', () => {
    const s = new Submission('s-1', 'v-1', SubmissionState.Rejected, {});
    expect(s.isRejected).toBe(true);
    expect(s.isAccepted).toBe(false);
  });

  // ── Capability Checks ──

  it('can submit when server provides submit affordance', () => {
    const s = new Submission('s-1', 'v-1', SubmissionState.ReadyForReview, {
      submit: 'asc submissions submit --version-id v-1',
    });
    expect(s.canSubmit).toBe(true);
    expect(s.canCancel).toBe(false);
  });

  it('can cancel when server provides cancel affordance', () => {
    const s = new Submission('s-1', 'v-1', SubmissionState.WaitingForReview, {
      cancel: 'asc submissions cancel --submission-id s-1',
    });
    expect(s.canCancel).toBe(true);
    expect(s.canSubmit).toBe(false);
  });

  it('cannot submit or cancel when affordances are empty', () => {
    const s = new Submission('s-1', 'v-1', SubmissionState.InReview, {});
    expect(s.canSubmit).toBe(false);
    expect(s.canCancel).toBe(false);
  });

  // ── Display ──

  it('formats display state with spaces', () => {
    const s = new Submission('s-1', 'v-1', SubmissionState.ReadyForReview, {});
    expect(s.displayState).toBe('READY FOR REVIEW');
  });

  // ── Hydration ──

  it('hydrates from API JSON', () => {
    const json = {
      id: 's-1',
      versionId: 'v-1',
      state: 'READY_FOR_REVIEW',
      affordances: { submit: 'asc submissions submit --version-id v-1' },
    };

    const s = Submission.fromJSON(json);

    expect(s.id).toBe('s-1');
    expect(s.versionId).toBe('v-1');
    expect(s.isReady).toBe(true);
    expect(s.canSubmit).toBe(true);
  });

  it('hydrates with empty affordances when missing', () => {
    const json = {
      id: 's-2',
      versionId: 'v-2',
      state: 'ACCEPTED',
    };

    const s = Submission.fromJSON(json);
    expect(s.affordances).toEqual({});
    expect(s.isAccepted).toBe(true);
    expect(s.canSubmit).toBe(false);
  });
});
