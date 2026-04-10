import { Suspense, lazy } from 'react';
import { usePluginRegistry } from './PluginContext.tsx';

interface Props {
  name: string;
}

export function PluginSlot({ name }: Props) {
  const registry = usePluginRegistry();
  const widgets = registry.getWidgets(name);

  if (widgets.length === 0) return null;

  return (
    <div className="plugin-slot" data-slot={name}>
      {widgets.map((widget, i) => {
        const Component = lazy(widget.component);
        return (
          <Suspense key={i} fallback={<div className="plugin-loading" />}>
            <Component />
          </Suspense>
        );
      })}
    </div>
  );
}
