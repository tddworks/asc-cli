import type { Affordances } from '../shared/types.ts';

export class InAppPurchase {
  constructor(
    readonly id: string,
    readonly appId: string,
    readonly name: string,
    readonly productId: string,
    readonly inAppPurchaseType: string,
    readonly state: string,
    readonly affordances: Affordances,
  ) {}

  get isApproved(): boolean { return this.state === 'APPROVED'; }

  static fromJSON(json: Record<string, unknown>): InAppPurchase {
    return new InAppPurchase(
      (json.id as string) ?? '',
      (json.appId as string) ?? '',
      (json.name as string) ?? '',
      (json.productId as string) ?? '',
      (json.inAppPurchaseType as string) ?? '',
      (json.state as string) ?? '',
      (json.affordances as Affordances) ?? {},
    );
  }
}
