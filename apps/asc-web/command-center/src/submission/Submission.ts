import type { Affordances } from '../shared/types.ts';

export enum SubmissionState {
  ReadyForReview = 'READY_FOR_REVIEW',
  WaitingForReview = 'WAITING_FOR_REVIEW',
  InReview = 'IN_REVIEW',
  Rejected = 'REJECTED',
  Accepted = 'ACCEPTED',
}

export class Submission {
  constructor(
    readonly id: string,
    readonly versionId: string,
    readonly state: SubmissionState,
    readonly affordances: Affordances,
  ) {}

  // ── Semantic Booleans ──

  get isReady(): boolean {
    return this.state === SubmissionState.ReadyForReview;
  }

  get isWaiting(): boolean {
    return this.state === SubmissionState.WaitingForReview;
  }

  get isAccepted(): boolean {
    return this.state === SubmissionState.Accepted;
  }

  get isInReview(): boolean {
    return this.state === SubmissionState.InReview;
  }

  get isRejected(): boolean {
    return this.state === SubmissionState.Rejected;
  }

  // ── Capability Checks ──

  get canSubmit(): boolean {
    return 'submit' in this.affordances;
  }

  get canCancel(): boolean {
    return 'cancel' in this.affordances;
  }

  // ── Display ──

  get displayState(): string {
    return this.state.replace(/_/g, ' ');
  }

  // ── Factory ──

  static fromJSON(json: Record<string, unknown>): Submission {
    return new Submission(
      json.id as string,
      json.versionId as string,
      json.state as SubmissionState,
      (json.affordances as Affordances) ?? {},
    );
  }
}
