#!/bin/bash
# Claude Code statusline, exceptions only: model · project:branch · effort when not high ·
# context % with the 25% handoff tag (CLAUDE.md rule) · 5h/7d limits only from 50%.
# One jq call, plus git for the branch outside worktree sessions.
input=$(cat)
command -v jq >/dev/null || exit 0

# unit separator keeps empty fields (tabs would collapse)
IFS=$'\x1f' read -r MODEL PROJ CWD BRANCH EFFORT PCT U5 R5 U7 < <(
	jq -r '[
    .model.display_name,
    .workspace.project_dir,
    (.workspace.current_dir // .cwd),
    .worktree.branch,
    ((.effort | objects | .level) // (.effort | strings) // null),
    .context_window.used_percentage,
    .rate_limits.five_hour.used_percentage,
    .rate_limits.five_hour.resets_at,
    .rate_limits.seven_day.used_percentage
  ] | map(. // "" | tostring) | join("")' <<<"$input"
)

DIM='\033[38;5;245m'
RST='\033[0m'
seg() { [ -n "$2" ] && printf ' %b·%b \033[38;5;%sm%s%b' "$DIM" "$RST" "$1" "$2" "$RST"; }
int() {
	local v=${1%%.*}
	printf '%s' "${v:-0}"
}
# green/yellow/red by two thresholds: level VALUE WARN CRIT
level() { if [ "$1" -ge "$3" ]; then echo 196; elif [ "$1" -ge "$2" ]; then echo 214; else echo 143; fi; }

DIR=${PROJ:-$CWD}
if [ "$DIR" = "$HOME" ]; then DIR=HOME; else DIR=${DIR##*/}; fi
[ -n "$BRANCH" ] || BRANCH=$(git -C "${CWD:-.}" symbolic-ref --short -q HEAD 2>/dev/null || true)
HAVE_CTX=$PCT
PCT=$(int "$PCT")
U5=$(int "$U5")
U7=$(int "$U7")

printf '\033[38;5;110m%s%b' "${MODEL:-?}" "$RST"
seg 180 "${DIR:-$BRANCH}${DIR:+${BRANCH:+:$BRANCH}}"
[ "$EFFORT" = high ] || seg 108 "$EFFORT"

CTX="ctx ${PCT}%"
[ "$PCT" -ge 25 ] && CTX+=" handoff"
[ -n "$HAVE_CTX" ] && seg "$(level "$PCT" 25 40)" "$CTX"

if [ "$U5" -ge 50 ]; then
	LABEL=5h
	if [[ $R5 =~ ^[0-9]+$ ]]; then
		LEFT=$((R5 - $(date +%s)))
		if [ "$LEFT" -ge 3600 ]; then
			LABEL="$((LEFT / 3600))h$((LEFT % 3600 / 60))m"
		elif [ "$LEFT" -gt 0 ]; then LABEL="$((LEFT / 60))m"; fi
	fi
	seg "$(level "$U5" 50 80)" "$LABEL ${U5}%"
fi
[ "$U7" -ge 50 ] && seg "$(level "$U7" 50 80)" "7d ${U7}%"
exit 0
