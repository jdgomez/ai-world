#!/usr/bin/env node
// Claude Code statusLine: shows cwd, git branch, context-window usage, and time to next rate-limit reset.
const fs = require('fs');
const { execSync } = require('child_process');

const FALLBACK_CONTEXT_LIMIT = 200000;
const RESET = '\x1b[0m';
const CYAN = '\x1b[36m';
const YELLOW = '\x1b[33m';
const GREEN = '\x1b[32m';
const RED = '\x1b[31m';
const DIM = '\x1b[2m';

function colorForPct(pct) {
  return pct >= 80 ? RED : pct >= 50 ? YELLOW : GREEN;
}

function formatDuration(ms) {
  if (ms <= 0) return 'now';
  const totalMin = Math.round(ms / 60000);
  const d = Math.floor(totalMin / 1440);
  const h = Math.floor((totalMin % 1440) / 60);
  const m = totalMin % 60;
  if (d > 0) return `${d}d ${h}h`;
  return h > 0 ? `${h}h ${m}m` : `${m}m`;
}

// Hooks don't receive rate-limit data, only the status line does. Publish it
// to a shared file so ~/.claude/hooks/usage-guard.py can warn agents before
// the quota runs out. The quota is account-wide, so one file serves every
// session.
function publishUsage(rateLimits) {
  if (!Object.keys(rateLimits).length) return;
  try {
    const os = require('os');
    const path = require('path');
    const dir = path.join(process.env.XDG_CACHE_HOME || path.join(os.homedir(), '.cache'), 'agent-flow');
    fs.mkdirSync(dir, { recursive: true });
    const tmp = path.join(dir, `.usage.json.${process.pid}`);
    fs.writeFileSync(tmp, JSON.stringify({ updated_at: Math.floor(Date.now() / 1000), rate_limits: rateLimits }));
    fs.renameSync(tmp, path.join(dir, 'usage.json'));
  } catch {
    // no-op: the status line must render even if the cache isn't writable
  }
}

let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', (chunk) => (input += chunk));
process.stdin.on('end', () => {
  let data = {};
  try {
    data = JSON.parse(input);
  } catch {
    // no-op: fall back to defaults below
  }

  const cwd = (data.workspace && data.workspace.current_dir) || data.cwd || process.cwd();
  const home = process.env.HOME || '';
  const displayDir = home && cwd.startsWith(home) ? '~' + cwd.slice(home.length) : cwd;

  let branch = '';
  try {
    branch = execSync('git rev-parse --abbrev-ref HEAD', {
      cwd,
      stdio: ['ignore', 'pipe', 'ignore'],
    })
      .toString()
      .trim();
  } catch {
    branch = '';
  }

  // Prefer Claude Code's own computed context-window usage; fall back to
  // parsing the transcript's last usage entry if that field isn't present.
  let tokenInfo = '';
  const cw = data.context_window;
  if (cw && typeof cw.context_window_size === 'number' && cw.context_window_size > 0) {
    const used = (cw.total_input_tokens || 0) + (cw.total_output_tokens || 0);
    const pct = Math.round(cw.used_percentage ?? (used / cw.context_window_size) * 100);
    tokenInfo = `${colorForPct(pct)}${(used / 1000).toFixed(1)}k/${(cw.context_window_size / 1000).toFixed(0)}k tokens (${pct}%)${RESET}`;
  } else {
    const transcriptPath = data.transcript_path;
    if (transcriptPath && fs.existsSync(transcriptPath)) {
      try {
        const lines = fs.readFileSync(transcriptPath, 'utf8').split('\n').filter(Boolean);
        for (let i = lines.length - 1; i >= 0; i--) {
          let entry;
          try {
            entry = JSON.parse(lines[i]);
          } catch {
            continue;
          }
          const usage = entry && entry.message && entry.message.usage;
          if (usage) {
            const used =
              (usage.input_tokens || 0) +
              (usage.cache_creation_input_tokens || 0) +
              (usage.cache_read_input_tokens || 0);
            const pct = Math.min(100, Math.round((used / FALLBACK_CONTEXT_LIMIT) * 100));
            tokenInfo = `${colorForPct(pct)}${(used / 1000).toFixed(1)}k/${FALLBACK_CONTEXT_LIMIT / 1000}k tokens (${pct}%)${RESET}`;
            break;
          }
        }
      } catch {
        // no-op: leave tokenInfo empty if transcript can't be parsed
      }
    }
  }

  // Claude Code's own rate-limit windows - this is quota *spent*, distinct
  // from the context-window number above: five_hour is the rolling session
  // limit, seven_day the weekly one, spend_limit a gateway/enterprise usage
  // cap. Each has its own used_percentage and resets_at (unix seconds).
  const rateLimits = data.rate_limits || {};
  publishUsage(rateLimits);
  const windowLabels = { five_hour: 'session', seven_day: 'week', spend_limit: 'spend' };
  const quotaParts = [];
  for (const key of ['five_hour', 'seven_day', 'spend_limit']) {
    const w = rateLimits[key];
    if (!w || typeof w.used_percentage !== 'number') continue;
    const pct = Math.round(w.used_percentage);
    let segment = `${colorForPct(pct)}${windowLabels[key]} ${pct}%${RESET}`;
    if (typeof w.resets_at === 'number' && Number.isFinite(w.resets_at)) {
      const remaining = formatDuration(w.resets_at * 1000 - Date.now());
      segment += `${DIM} (resets ${remaining})${RESET}`;
    }
    quotaParts.push(segment);
  }
  const quotaInfo = quotaParts.join(`${DIM}, ${RESET}`);

  const parts = [`${CYAN}${displayDir}${RESET}`];
  if (branch) parts.push(`${YELLOW}(${branch})${RESET}`);
  if (tokenInfo) parts.push(tokenInfo);
  if (quotaInfo) parts.push(quotaInfo);

  process.stdout.write(parts.join(`${DIM} | ${RESET}`));
});
