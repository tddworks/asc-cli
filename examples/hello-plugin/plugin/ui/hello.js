// Hello Plugin UI — loaded dynamically by the web app
//
// This script demonstrates how a plugin's UI handles affordance buttons.
//
// Flow:
//   1. Plugin registers affordance via AffordanceRegistry (Swift, at startup)
//      → adds "greet" key to App model's affordances
//   2. Web app renders a "Greet" button from the affordance
//   3. User clicks → dispatches to handler registered here
//   4. Handler calls plugin's /api/hello/greet endpoint
//   5. Shows result as a toast notification
//
(function() {
  'use strict';

  // --- Register affordance handler ---
  // The key "greet" matches what AffordanceRegistry.register(App.self) returns.
  // When the web app renders an App's affordances and the user clicks "Greet",
  // this handler is called instead of the default CLI execution.

  window.appAffordanceHandlers = window.appAffordanceHandlers || {};

  window.appAffordanceHandlers['greet'] = async function(appId, appName) {
    const base = window.DataProvider?._serverUrl || '';
    try {
      const resp = await fetch(`${base}/api/hello/greet?name=${encodeURIComponent(appName || appId)}`);
      const data = await resp.json();
      if (window.showToast) {
        window.showToast(data.message, 'success');
      }
    } catch (err) {
      if (window.showToast) {
        window.showToast('Greet failed: ' + err.message, 'error');
      }
    }
  };

  console.log('[Hello Plugin] UI loaded — "greet" affordance handler registered');
})();
