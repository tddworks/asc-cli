import { IrisApp } from '../IrisApp.ts';

export function mockIrisApps(): IrisApp[] {
  return [
    new IrisApp('iris-1', 'WeatherApp', 'com.example.weather', 'SKU001', ['IOS', 'WATCH_OS'], {}),
    new IrisApp('iris-2', 'FitnessTracker', 'com.example.fitness', 'SKU002', ['IOS'], {}),
  ];
}
