import { createContext, useContext, type ReactNode } from 'react';
import { PluginRegistry, pluginRegistry } from './PluginRegistry.ts';

const PluginRegistryContext = createContext<PluginRegistry>(pluginRegistry);

export function usePluginRegistry(): PluginRegistry {
  return useContext(PluginRegistryContext);
}

export function PluginProvider({ children, registry = pluginRegistry }: { children: ReactNode; registry?: PluginRegistry }) {
  return (
    <PluginRegistryContext.Provider value={registry}>
      {children}
    </PluginRegistryContext.Provider>
  );
}
