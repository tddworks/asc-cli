// Presentation: Console state + command log
export const state = {
  currentPage: 'dashboard',
  commandLog: [],
};

export function logCommand(cmd) {
  state.commandLog.push({ type: 'cmd', text: cmd, time: new Date() });
}

export function logOutput(text) {
  state.commandLog.push({ type: 'output', text, time: new Date() });
}

export function logError(text) {
  state.commandLog.push({ type: 'error', text, time: new Date() });
}
