#!/bin/bash
# PostToolUse hook: one-time context usage reminder per session.
# Reads context percentage from /tmp/.claude_context_pct (written by statusline)
# and fires a wrap-up reminder when usage >= 20%. Only fires once per session.

input=$(cat)

CTX_FILE="/tmp/.claude_context_pct"
session_id=$(echo "$input" | jq -r '.session_id // empty')
WARNED_FLAG="/tmp/.claude_context_warned_${session_id}"

# Already warned this session — exit silently
[ -f "$WARNED_FLAG" ] && exit 0

# No context data yet — exit silently
[ -f "$CTX_FILE" ] || exit 0

pct=$(cat "$CTX_FILE")

# Check if percentage >= threshold (using awk for float comparison)
threshold=20
if awk -v pct="$pct" -v thresh="$threshold" 'BEGIN { exit !(pct >= thresh) }'; then
    touch "$WARNED_FLAG"
    cat <<HOOKJSON
{
    "hookSpecificOutput": {
        "hookEventName": "PostToolUse",
        "additionalContext": "CONTEXT LIMIT REMINDER: Context usage is at ${pct}%. Reasoning and tool-use quality degrades past 20%. Wrap up now: (1) Save game state, (2) Log any open bugs in BUG_LOG.md, (3) Update Game Progress in CLAUDE.md with exact location, party, and what to do next, (4) Commit and push, (5) End the session. A fresh context will pick up where you left off."
    }
}
HOOKJSON
fi
