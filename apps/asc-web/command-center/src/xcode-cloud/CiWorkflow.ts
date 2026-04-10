import type { Affordances } from '../shared/types.ts';

export class CiWorkflow {
  constructor(
    readonly id: string,
    readonly productId: string,
    readonly name: string,
    readonly isEnabled: boolean,
    readonly isLockedForEditing: boolean,
    readonly affordances: Affordances,
  ) {}

  // ── Capability Checks ──

  get canStartBuild(): boolean {
    return 'startBuild' in this.affordances;
  }

  get canListBuildRuns(): boolean {
    return 'listBuildRuns' in this.affordances;
  }

  // ── Factory ──

  static fromJSON(json: Record<string, unknown>): CiWorkflow {
    return new CiWorkflow(
      json.id as string,
      json.productId as string,
      json.name as string,
      json.isEnabled as boolean,
      json.isLockedForEditing as boolean,
      (json.affordances as Affordances) ?? {},
    );
  }
}
