import { Simulator } from '../Simulator.ts';

export function mockSimulators(): Simulator[] {
  return [
    new Simulator('A1B2C3D4-E5F6-7890-ABCD-EF1234567890', 'iPhone 15 Pro', 'Booted', 'iOS 17.4', {}),
    new Simulator('B2C3D4E5-F6A7-8901-BCDE-F12345678901', 'iPad Air (5th gen)', 'Shutdown', 'iOS 17.4', {}),
    new Simulator('C3D4E5F6-A7B8-9012-CDEF-123456789012', 'Apple Watch Series 9', 'Shutdown', 'watchOS 10.4', {}),
  ];
}
