#!/bin/bash
# Generate productivity-data.json from all git repos in ~/
# Run: bash generate-productivity.sh [since-date]
# Output: productivity-data.json

SINCE="${1:-2026-02-01}"
OUTPUT="productivity-data.json"

echo "Scanning repos since $SINCE..."

TMPRAW=$(mktemp)

# Collect raw per-commit data
find /Users/admin -maxdepth 3 -name ".git" -type d 2>/dev/null \
  | grep -v '.nvm' | grep -v 'g-stack' | grep -v 'node_modules' \
  | while read gitdir; do
    repo=$(dirname "$gitdir")
    name=$(basename "$repo")
    git -C "$repo" log --all --since="$SINCE" --format="%aI" --shortstat --no-merges 2>/dev/null \
    | awk -v repo="$name" '
      /^[0-9]{4}-/ { day=substr($0,1,10); next }
      /insertion|deletion/ {
        ins=0; del=0; f=0
        for(i=1;i<=NF;i++) {
          if($(i+1) ~ /insert/) ins=$i
          if($(i+1) ~ /delet/) del=$i
          if($(i+1) ~ /file/)  f=$i
        }
        printf "%s|%s|%d|%d|%d\n", day, repo, ins, del, f
      }
    '
  done > "$TMPRAW" 2>/dev/null

echo "Collected $(wc -l < "$TMPRAW") raw entries"

# Build JSON with awk
awk -F'|' '
BEGIN {
  daily_count = 0
  repo_count = 0
}
NF >= 5 {
  day=$1; repo=$2; ins=$3+0; del=$4+0; files=$5+0
  commits[day]++
  insertions[day]+=ins
  deletions[day]+=del
  filechanges[day]+=files
  key=day SUBSEP repo
  if(!seen[key]++) repos_per_day[day]++

  repo_commits[repo]++
  repo_ins[repo]+=ins
  repo_del[repo]+=del
}
END {
  # Sort days - collect keys
  n = 0
  for (d in commits) { n++; sorted_days[n] = d }
  # Bubble sort asc
  for (i = 1; i <= n; i++)
    for (j = i+1; j <= n; j++)
      if (sorted_days[i] > sorted_days[j]) {
        tmp = sorted_days[i]; sorted_days[i] = sorted_days[j]; sorted_days[j] = tmp
      }

  printf "{\n"
  printf "  \"generated\": \"'"$(date -u +%Y-%m-%dT%H:%M:%SZ)"'\",\n"
  printf "  \"since\": \"'"$SINCE"'\",\n"

  # Daily
  printf "  \"daily\": [\n"
  for (i = 1; i <= n; i++) {
    d = sorted_days[i]
    if (i > 1) printf ",\n"
    printf "    {\"date\":\"%s\",\"commits\":%d,\"insertions\":%d,\"deletions\":%d,\"files\":%d,\"repos\":%d}", \
      d, commits[d], insertions[d], deletions[d], filechanges[d], repos_per_day[d]
  }
  printf "\n  ],\n"

  # Repos - sort by commits desc
  # Collect into arrays
  rc = 0
  for (r in repo_commits) {
    rc++
    rnames[rc] = r
    rvals[rc] = repo_commits[r]
  }
  # Simple insertion sort desc
  for (i = 2; i <= rc; i++) {
    j = i
    while (j > 1 && rvals[j] > rvals[j-1]) {
      tmp = rvals[j]; rvals[j] = rvals[j-1]; rvals[j-1] = tmp
      tmp = rnames[j]; rnames[j] = rnames[j-1]; rnames[j-1] = tmp
      j--
    }
  }

  printf "  \"repos\": [\n"
  limit = (rc < 20) ? rc : 20
  for (i = 1; i <= limit; i++) {
    r = rnames[i]
    if (i > 1) printf ",\n"
    printf "    {\"name\":\"%s\",\"commits\":%d,\"insertions\":%d,\"deletions\":%d}", \
      r, repo_commits[r], repo_ins[r], repo_del[r]
  }
  printf "\n  ]\n"
  printf "}\n"
}
' "$TMPRAW" > "$OUTPUT"

rm -f "$TMPRAW"
echo "Generated $OUTPUT ($(wc -c < "$OUTPUT" | tr -d ' ') bytes)"
