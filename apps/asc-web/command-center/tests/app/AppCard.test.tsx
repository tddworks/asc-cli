import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { AppCard } from '../../src/app/components/AppCard.tsx';
import { App } from '../../src/app/App.ts';

describe('AppCard', () => {

  it('renders app name', () => {
    const app = new App('a-1', 'WeatherApp', 'com.example.weather', 'SKU001', 'en-US', true, {});

    render(<AppCard app={app} />);

    expect(screen.getByText('WeatherApp')).toBeInTheDocument();
  });

  it('renders bundle id', () => {
    const app = new App('a-1', 'WeatherApp', 'com.example.weather', 'SKU001', 'en-US', true, {});

    render(<AppCard app={app} />);

    expect(screen.getByText('com.example.weather')).toBeInTheDocument();
  });

  it('renders primary locale as meta item', () => {
    const app = new App('a-1', 'WeatherApp', 'com.example.weather', 'SKU001', 'en-US', true, {});

    render(<AppCard app={app} />);

    expect(screen.getByText('en-US')).toBeInTheDocument();
  });

  it('renders app id as meta item', () => {
    const app = new App('a-1', 'WeatherApp', 'com.example.weather', 'SKU001', 'en-US', true, {});

    render(<AppCard app={app} />);

    expect(screen.getByText('a-1')).toBeInTheDocument();
  });

  it('renders app icon with first letter', () => {
    const app = new App('a-1', 'WeatherApp', 'com.example.weather', 'SKU001', 'en-US', true, {});

    const { container } = render(<AppCard app={app} />);

    const icon = container.querySelector('.app-icon');
    expect(icon).not.toBeNull();
    expect(icon!.textContent).toBe('W');
  });

  it('renders affordance buttons', () => {
    const app = new App('a-1', 'App', 'com.x', 'SKU', 'en-US', true, {
      getVersions: 'asc versions list --app-id a-1',
    });

    render(<AppCard app={app} />);

    expect(screen.getByText('Get Versions')).toBeInTheDocument();
  });
});
