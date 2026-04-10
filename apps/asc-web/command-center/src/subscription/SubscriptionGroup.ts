import type { Affordances } from '../shared/types.ts';

export class SubscriptionGroup {
  constructor(
    readonly id: string,
    readonly appId: string,
    readonly referenceName: string,
    readonly affordances: Affordances,
  ) {}

  static fromJSON(json: Record<string, unknown>): SubscriptionGroup {
    return new SubscriptionGroup(
      (json.id as string) ?? '',
      (json.appId as string) ?? '',
      (json.referenceName as string) ?? '',
      (json.affordances as Affordances) ?? {},
    );
  }
}
