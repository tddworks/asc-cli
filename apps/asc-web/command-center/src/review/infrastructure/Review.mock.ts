import { Review } from '../Review.ts';

export function mockReviews(appId: string): Review[] {
  return [
    new Review('r-1', appId, 'Amazing App!', 'Best weather app I have ever used. Accurate forecasts every time.', 5, 'US', 'WeatherFan42', '2024-03-15', {
      respond: `asc reviews respond --review-id r-1`,
    }),
    new Review('r-2', appId, 'Crashes on launch', 'App crashes every time I open it on iOS 17.', 1, 'GB', 'ApplUser', '2024-03-14', {
      respond: `asc reviews respond --review-id r-2`,
    }),
    new Review('r-3', appId, 'Pretty good', 'Works well but could use more widgets.', 4, 'DE', 'HansM', '2024-03-12', {
      respond: `asc reviews respond --review-id r-3`,
      getResponse: `asc reviews response --review-id r-3`,
    }),
  ];
}
