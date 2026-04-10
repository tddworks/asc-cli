import { Suspense, lazy, useState, useCallback } from 'react';
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
import { Sidebar } from './shared/layout/Sidebar.tsx';
import { Header } from './shared/layout/Header.tsx';

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

function LoadingSpinner() {
  return <div className="spinner">Loading...</div>;
}

/** Inner shell that can use context hooks (must be rendered inside providers) */
function AppShell() {
  const mode = useDataMode();
  const toggleMode = useToggleMode();
  const { entries: _commandLogEntries } = useCommandLog();

  const [commandLogOpen, setCommandLogOpen] = useState(false);
  const [sidebarOpen, setSidebarOpen] = useState(false);

  const handleToggleTheme = useCallback(() => {
    document.documentElement.classList.toggle('light');
  }, []);

  const handleRefresh = useCallback(() => {
    window.location.reload();
  }, []);

  const pluginPages = pluginRegistry.getPages();

  return (
    <BrowserRouter>
      <PluginProvider>
        <div className="app">
          <Sidebar />
          <div className="main">
            <Header
              title="Command Center"
              mode={mode}
              onToggleMode={toggleMode}
              onToggleTheme={handleToggleTheme}
              onRefresh={handleRefresh}
              onOpenCommandLog={() => setCommandLogOpen(!commandLogOpen)}
              onToggleSidebar={() => setSidebarOpen(!sidebarOpen)}
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
      </PluginProvider>
    </BrowserRouter>
  );
}

export function App() {
  return (
    <DataModeProviderComponent>
      <CommandLogProvider>
        <AppShell />
      </CommandLogProvider>
    </DataModeProviderComponent>
  );
}
