import { describe, it, expect } from 'vitest';
import { render, screen } from '@testing-library/react';
import { AffordanceBar } from '../../src/shared/components/AffordanceBar.tsx';

describe('AffordanceBar', () => {

  it('renders nothing when affordances are empty', () => {
    const { container } = render(<AffordanceBar affordances={{}} />);
    expect(container.firstChild).toBeNull();
  });

  it('renders a button for each affordance', () => {
    render(<AffordanceBar affordances={{
      getVersions: 'asc versions list --app-id app-1',
      getBuilds: 'asc builds list --app-id app-1',
    }} />);

    expect(screen.getByText('Get Versions')).toBeInTheDocument();
    expect(screen.getByText('Get Builds')).toBeInTheDocument();
  });

  it('shows the full command as tooltip', () => {
    render(<AffordanceBar affordances={{
      submitForReview: 'asc versions submit --id v-1',
    }} />);

    expect(screen.getByTitle('asc versions submit --id v-1')).toBeInTheDocument();
  });

  it('formats camelCase labels to title case', () => {
    render(<AffordanceBar affordances={{
      listScreenshotSets: 'asc screenshot-sets list --version-id v-1',
    }} />);

    expect(screen.getByText('List Screenshot Sets')).toBeInTheDocument();
  });
});
