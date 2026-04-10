import { Submission, SubmissionState } from '../Submission.ts';

export function mockSubmission(versionId: string): Submission {
  return new Submission('sub-1', versionId, SubmissionState.ReadyForReview, {
    submit: `asc submissions submit --version-id ${versionId}`,
  });
}

export function mockSubmissions(): Submission[] {
  return [
    new Submission('sub-1', 'v-1', SubmissionState.ReadyForReview, {
      submit: 'asc submissions submit --version-id v-1',
    }),
    new Submission('sub-2', 'v-2', SubmissionState.WaitingForReview, {
      cancel: 'asc submissions cancel --submission-id sub-2',
    }),
    new Submission('sub-3', 'v-3', SubmissionState.InReview, {}),
    new Submission('sub-4', 'v-4', SubmissionState.Accepted, {}),
    new Submission('sub-5', 'v-5', SubmissionState.Rejected, {
      submit: 'asc submissions submit --version-id v-5',
    }),
  ];
}
