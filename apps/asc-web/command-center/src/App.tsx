import { Suspense, lazy, useState } from 'react';
import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { PluginProvider } from './plugin/PluginContext.tsx';
import { pluginRegistry } from './plugin/PluginRegistry.ts';
import {
  DataModeProviderComponent,
  CommandLogProvider,
  useDataMode,
  useToggleMode,
  useCommandLog,
} from './shared/api-client.tsx';
import { ThemeProvider, useTheme } from './shared/components/ThemeProvider.tsx';
import { Sidebar } from './shared/layout/Sidebar.tsx';
import { Header } from './shared/layout/Header.tsx';
import { CommandLogModal } from './shared/components/CommandLogModal.tsx';

const DashboardPage = lazy(() => import('./dashboard/pages/DashboardPage.tsx'));
const AppList = lazy(() => import('./app/pages/AppList.tsx'));
const AppDetail = lazy(() => import('./app/pages/AppDetail.tsx'));
const VersionList = lazy(() => import('./version/pages/VersionList.tsx'));
const BuildList = lazy(() => import('./build/pages/BuildList.tsx'));
const ReviewList = lazy(() => import('./review/pages/ReviewList.tsx'));
const TestFlightPage = lazy(() => import('./testflight/pages/TestFlightPage.tsx'));
const CodeSigningPage = lazy(() => import('./code-signing/pages/CodeSigningPage.tsx'));
const SubmissionPage = lazy(() => import('./submission/pages/SubmissionPage.tsx'));
const XcodeCloudPage = lazy(() => import('./xcode-cloud/pages/XcodeCloudPage.tsx'));
const ReportsPage = lazy(() => import('./report/pages/ReportsPage.tsx'));
const SimulatorPage = lazy(() => import('./simulator/pages/SimulatorPage.tsx'));
const UserPage = lazy(() => import('./user/pages/UserPage.tsx'));
const IrisPage = lazy(() => import('./iris/pages/IrisPage.tsx'));
const IAPPage = lazy(() => import('./iap/pages/IAPPage.tsx'));
const SubscriptionPage = lazy(() => import('./subscription/pages/SubscriptionPage.tsx'));
const AppInfoPage = lazy(() => import('./app-info/pages/AppInfoPage.tsx'));
const ScreenshotPage = lazy(() => import('./screenshot/pages/ScreenshotPage.tsx'));
const PluginsPage = lazy(() => import('./plugin/pages/PluginsPage.tsx'));

function LoadingSpinner() {
  return <div className="spinner">Loading...</div>;
}

function AppShell() {
  const mode = useDataMode();
  const toggleMode = useToggleMode();
  const { entries: commandLogEntries } = useCommandLog();
  const { toggleTheme } = useTheme();

  const [commandLogOpen, setCommandLogOpen] = useState(false);

  const pluginPages = pluginRegistry.getPages();

  return (
    <BrowserRouter>
      <PluginProvider>
        <div className="app">
          <Sidebar />
          <div className="main">
            <Header
              title="Dashboard"
              mode={mode}
              onToggleMode={toggleMode}
              onToggleTheme={toggleTheme}
              onRefresh={() => window.location.reload()}
              onOpenCommandLog={() => setCommandLogOpen(true)}
              onToggleSidebar={() => {
                document.getElementById('sidebar')?.classList.toggle('open');
              }}
            />
            <div className="content">
              <Suspense fallback={<LoadingSpinner />}>
                <Routes>
                  <Route path="/" element={<DashboardPage />} />
                  <Route path="/apps" element={<AppList />} />
                  <Route path="/apps/:appId" element={<AppDetail />} />
                  <Route path="/apps/:appId/versions" element={<VersionList />} />
                  <Route path="/builds" element={<BuildList />} />
                  <Route path="/reviews" element={<ReviewList />} />
                  <Route path="/testflight" element={<TestFlightPage />} />
                  <Route path="/code-signing" element={<CodeSigningPage />} />
                  <Route path="/submissions" element={<SubmissionPage />} />
                  <Route path="/xcode-cloud" element={<XcodeCloudPage />} />
                  <Route path="/reports" element={<ReportsPage />} />
                  <Route path="/simulators" element={<SimulatorPage />} />
                  <Route path="/users" element={<UserPage />} />
                  <Route path="/iris" element={<IrisPage />} />
                  <Route path="/iap" element={<IAPPage />} />
                  <Route path="/subscriptions" element={<SubscriptionPage />} />
                  <Route path="/app-info" element={<AppInfoPage />} />
                  <Route path="/screenshots" element={<ScreenshotPage />} />
                  <Route path="/plugins" element={<PluginsPage />} />

                  {pluginPages.map((page) => {
                    const LazyComponent = lazy(page.component);
                    return (
                      <Route
                        key={page.path}
                        path={page.path}
                        element={
                          <Suspense fallback={<LoadingSpinner />}>
                            <LazyComponent />
                          </Suspense>
                        }
                      />
                    );
                  })}
                </Routes>
              </Suspense>
            </div>
          </div>
        </div>

        <CommandLogModal
          isOpen={commandLogOpen}
          onClose={() => setCommandLogOpen(false)}
          entries={commandLogEntries}
        />
      </PluginProvider>
    </BrowserRouter>
  );
}

export function App() {
  return (
    <ThemeProvider>
      <DataModeProviderComponent>
        <CommandLogProvider>
          <AppShell />
        </CommandLogProvider>
      </DataModeProviderComponent>
    </ThemeProvider>
  );
}
