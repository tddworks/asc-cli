/**
 * TerminalOutput — renders syntax-highlighted JSON in terminal style.
 *
 * Key design: each output line wraps its content in ONE <span> so it is the
 * only flex child of the .t-line container — the CSS gap between flex children
 * therefore never affects the inner syntax-highlighting spans.
 *
 * API:
 *   TerminalOutput.render(el, sessions)
 *     sessions: [{ cmd, json?, success?, comment? }, ...]
 *
 *   TerminalOutput.renderJson(el, data, {comment?})
 *     Renders only JSON (no command prompt), with an optional comment line.
 */
(function () {
  function esc(s) {
    return String(s)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;');
  }

  /** Syntax-highlight one line of JSON.stringify output. */
  function highlightLine(rawLine) {
    const indentLen = rawLine.match(/^(\s*)/)[1].length;
    const content   = rawLine.trimStart();
    const pad       = '\u00a0'.repeat(indentLen); // non-breaking spaces for indent

    if (!content) return '';

    // "key": value[,]
    const kv = content.match(/^"([^"]+)":\s*(.*?)$/s);
    if (kv) {
      const key = kv[1];
      let rest  = kv[2].trimEnd();

      const hasComma = rest.endsWith(',');
      if (hasComma) rest = rest.slice(0, -1).trimEnd();

      const keyHtml   = `<span class="t-key">"${esc(key)}"</span><span class="t-dim">: </span>`;
      const commaHtml = hasComma ? '<span class="t-dim">,</span>' : '';

      let valHtml;
      if (rest === '{' || rest === '[') {
        valHtml = `<span class="t-dim">${rest}</span>`;
      } else if (rest.startsWith('"') && rest.endsWith('"')) {
        const str = rest.slice(1, -1);
        valHtml = str.startsWith('asc ')
          ? `<span class="t-val">"${esc(str)}"</span>`
          : `<span class="t-str">"${esc(str)}"</span>`;
      } else if (rest === 'true' || rest === 'false') {
        valHtml = `<span class="t-success">${rest}</span>`;
      } else if (/^-?\d+(\.\d+)?$/.test(rest)) {
        valHtml = `<span class="t-success">${rest}</span>`;
      } else {
        valHtml = `<span class="t-dim">${esc(rest)}</span>`;
      }

      return pad + keyHtml + valHtml + commaHtml;
    }

    // Structural tokens: {, }, [, ], },  ],
    return pad + `<span class="t-dim">${esc(content)}</span>`;
  }

  /** Create a .t-line div whose content is wrapped in ONE span (avoids flex gap). */
  function jsonLine(html) {
    const div  = document.createElement('div');
    div.className = 't-line t-indent';
    const wrap = document.createElement('span');
    wrap.innerHTML = html;
    div.appendChild(wrap);
    return div;
  }

  function commentLine(text) {
    const div = document.createElement('div');
    div.className = 't-line t-indent';
    const wrap = document.createElement('span');
    wrap.innerHTML = `<span class="t-dim">${esc(text)}</span>`;
    div.appendChild(wrap);
    return div;
  }

  function cmdDiv(cmd) {
    const div = document.createElement('div');
    div.className = 't-line';
    div.innerHTML = `<span class="t-prompt">$</span> <span class="t-cmd">${esc(cmd)}</span>`;
    return div;
  }

  function blankDiv() {
    const div = document.createElement('div');
    div.className = 't-blank';
    return div;
  }

  /** Append syntax-highlighted JSON lines for `data` into `container`. */
  function appendJson(container, data) {
    JSON.stringify(data, null, 2).split('\n').forEach(rawLine => {
      const html = highlightLine(rawLine);
      if (html) container.appendChild(jsonLine(html));
    });
  }

  /**
   * Render full terminal sessions.
   * sessions: [{ cmd, json?, success? }, ...]
   */
  function render(container, sessions) {
    container.innerHTML = '';

    sessions.forEach(session => {
      container.appendChild(cmdDiv(session.cmd));

      if (session.json !== undefined) appendJson(container, session.json);

      if (session.success) {
        const div = document.createElement('div');
        div.className = 't-line';
        div.innerHTML = `<span class="t-success">✓</span> <span class="t-dim">${esc(session.success)}</span>`;
        container.appendChild(div);
      }

      container.appendChild(blankDiv());
    });

    // Cursor
    const cur = document.createElement('div');
    cur.className = 't-line';
    cur.innerHTML = '<span class="t-prompt">$</span> <span class="t-cursor"></span>';
    container.appendChild(cur);
  }

  /**
   * Render only JSON (no command prompt) — for feature card previews.
   * options: { comment? }
   */
  function renderJson(container, data, options) {
    container.innerHTML = '';
    const opts = options || {};
    if (opts.comment) container.appendChild(commentLine(opts.comment));
    appendJson(container, data);
  }

  window.TerminalOutput = { render, renderJson };
})();
