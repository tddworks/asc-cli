import type { Affordances } from '../shared/types.ts';

export type DeviceStatus = 'ENABLED' | 'DISABLED';

export class Device {
  constructor(
    readonly id: string,
    readonly name: string,
    readonly udid: string,
    readonly deviceClass: string,
    readonly model: string,
    readonly status: DeviceStatus,
    readonly affordances: Affordances,
  ) {}

  // ── Semantic Booleans ──

  get isEnabled(): boolean {
    return this.status === 'ENABLED';
  }

  // ── Display ──

  get displayName(): string {
    return `${this.name} (${this.model})`;
  }

  // ── Factory ──

  static fromJSON(json: Record<string, unknown>): Device {
    return new Device(
      json.id as string,
      json.name as string,
      json.udid as string,
      json.deviceClass as string,
      json.model as string,
      json.status as DeviceStatus,
      (json.affordances as Affordances) ?? {},
    );
  }
}
