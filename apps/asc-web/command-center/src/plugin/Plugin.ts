import type { ComponentType } from 'react';

export interface PluginRegistration {
  id: string;
  name: string;
  version: string;
  pages?: PluginPage[];
  sidebarItems?: PluginSidebarItem[];
  widgets?: PluginWidget[];
}

export interface PluginPage {
  path: string;
  title: string;
  icon?: string;
  component: () => Promise<{ default: ComponentType }>;
}

export interface PluginSidebarItem {
  id: string;
  label: string;
  icon?: string;
  section: string;
  path: string;
}

export interface PluginWidget {
  slot: string;
  component: () => Promise<{ default: ComponentType }>;
  priority?: number;
}
