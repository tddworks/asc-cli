import type { ReactNode } from 'react';

interface Props {
  children: ReactNode;
}

export function PageLayout({ children }: Props) {
  return <>{children}</>;
}
