import type { Affordances } from '../shared/types.ts';

export class Simulator {
  constructor(
    readonly udid: string,
    readonly name: string,
    readonly state: string,
    readonly runtime: string,
    readonly affordances: Affordances,
  ) {}

  get id(): string { return this.udid; }
  get isBooted(): boolean { return this.state === 'Booted'; }

  static fromJSON(json: Record<string, unknown>): Simulator {
    return new Simulator(
      (json.udid as string) ?? '',
      (json.name as string) ?? '',
      (json.state as string) ?? 'Shutdown',
      (json.runtime as string) ?? '',
      (json.affordances as Affordances) ?? {},
    );
  }
}
