import type { Affordances } from '../shared/types.ts';

export class CiProduct {
  constructor(
    readonly id: string,
    readonly name: string,
    readonly productType: string,
    readonly appId: string | undefined,
    readonly affordances: Affordances,
  ) {}

  // ── Capability Checks ──

  get canListWorkflows(): boolean {
    return 'listWorkflows' in this.affordances;
  }

  // ── Factory ──

  static fromJSON(json: Record<string, unknown>): CiProduct {
    return new CiProduct(
      json.id as string,
      json.name as string,
      json.productType as string,
      json.appId as string | undefined,
      (json.affordances as Affordances) ?? {},
    );
  }
}
