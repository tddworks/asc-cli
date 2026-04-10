import { Build, BuildProcessingState } from '../Build.ts';

export function mockBuilds(appId: string): Build[] {
  return [
    new Build('b-1', appId, '105', '2.0.0', BuildProcessingState.Valid, false, false, '2024-03-15', {
      addToTestFlight: `asc testflight add --build-id b-1`,
    }),
    new Build('b-2', appId, '104', '1.9.0', BuildProcessingState.Valid, false, false, '2024-03-10', {}),
    new Build('b-3', appId, '103', '1.8.0', BuildProcessingState.Processing, false, false, '2024-03-08', {}),
    new Build('b-4', appId, '102', '1.7.0', BuildProcessingState.Valid, true, false, '2024-02-01', {}),
    new Build('b-5', appId, '101', '1.6.0', BuildProcessingState.Invalid, false, false, '2024-01-20', {}),
  ];
}
