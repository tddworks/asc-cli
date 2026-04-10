import { App } from '../App.ts';

export function mockApps(): App[] {
  return [
    new App(
      'app-1',
      'WeatherApp',
      'com.example.weather',
      'SKU001',
      'en-US',
      true,
      {
        getVersions: 'asc versions list --app-id app-1',
        getBuilds: 'asc builds list --app-id app-1',
        getReviews: 'asc reviews list --app-id app-1',
        getTestFlight: 'asc beta-groups list --app-id app-1',
      },
    ),
    new App(
      'app-2',
      'FitnessTracker',
      'com.example.fitness',
      'SKU002',
      'en-US',
      true,
      {
        getVersions: 'asc versions list --app-id app-2',
        getBuilds: 'asc builds list --app-id app-2',
      },
      'USES_THIRD_PARTY_CONTENT',
    ),
  ];
}
