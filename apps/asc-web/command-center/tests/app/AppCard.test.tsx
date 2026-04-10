import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { AppCard } from '../../src/app/components/AppCard.tsx';
import { App } from '../../src/app/App.ts';

describe('AppCard', () => {

  it('renders app display name', () => {
    const app = new App('a-1', 'WeatherApp', 'com.example.weather', 'SKU001', 'en-US', true, {});

    render(<AppCard app={app} />);

    expect(screen.getByText('WeatherApp (com.example.weather)')).toBeInTheDocument();
  });

  it('renders SKU', () => {
    const app = new App('a-1', 'WeatherApp', 'com.example.weather', 'SKU001', 'en-US', true, {});

    render(<AppCard app={app} />);

    expect(screen.getByText('SKU001')).toBeInTheDocument();
  });

  it('shows content rights badge when app has content rights', () => {
    const app = new App('a-1', 'App', 'com.x', 'SKU', 'en-US', true, {}, 'USES_THIRD_PARTY_CONTENT');

    render(<AppCard app={app} />);

    expect(screen.getByText('Content Rights')).toBeInTheDocument();
  });

  it('does not show content rights badge when absent', () => {
    const app = new App('a-1', 'App', 'com.x', 'SKU', 'en-US', true, {});

    render(<AppCard app={app} />);

    expect(screen.queryByText('Content Rights')).not.toBeInTheDocument();
  });

  it('renders affordance buttons', () => {
    const app = new App('a-1', 'App', 'com.x', 'SKU', 'en-US', true, {
      getVersions: 'asc versions list --app-id a-1',
    });

    render(<AppCard app={app} />);

    expect(screen.getByText('Get Versions')).toBeInTheDocument();
  });
});
