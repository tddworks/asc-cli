import { SubscriptionGroup } from '../SubscriptionGroup.ts';

export function mockSubscriptionGroups(appId: string): SubscriptionGroup[] {
  return [
    new SubscriptionGroup('sg-1', appId, 'Premium Plans', {}),
    new SubscriptionGroup('sg-2', appId, 'Add-on Features', {}),
  ];
}
