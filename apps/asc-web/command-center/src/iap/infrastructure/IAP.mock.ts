import { InAppPurchase } from '../InAppPurchase.ts';

export function mockIAPs(appId: string): InAppPurchase[] {
  return [
    new InAppPurchase('iap-1', appId, 'Premium Upgrade', 'com.example.premium', 'NON_CONSUMABLE', 'APPROVED', {}),
    new InAppPurchase('iap-2', appId, '100 Coins', 'com.example.coins100', 'CONSUMABLE', 'APPROVED', {}),
    new InAppPurchase('iap-3', appId, 'Special Offer', 'com.example.special', 'NON_CONSUMABLE', 'WAITING_FOR_REVIEW', {}),
  ];
}
