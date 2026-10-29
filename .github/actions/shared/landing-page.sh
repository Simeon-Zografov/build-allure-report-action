#!/usr/bin/env bash
# Builds gh_pages/index.html, the dashboard listing every environment's reports. Shared by the
# Publish Allure Report and Publish AI Analysis actions; run from the directory holding gh_pages/.
#
# AI_ANALYSIS=true adds an "AI analysis" column, read from each report's ai-analysis/ folder:
#   status.txt  running | not-needed | done | failed
#   run-url.txt the GitHub Actions run, linked while the analysis runs or after it failed
# Without it the page is exactly the dashboard the action has always built.

AI_ANALYSIS="${AI_ANALYSIS:-false}"
AI_TH=""
if [ "$AI_ANALYSIS" = "true" ]; then
  AI_TH="<th>AI analysis</th>"
fi

ai_analysis_cell() {
  local DIR="gh_pages/$1/$2/ai-analysis"
  local STATUS RUN_URL
  STATUS=$(cat "$DIR/status.txt" 2>/dev/null || true)
  RUN_URL=$(cat "$DIR/run-url.txt" 2>/dev/null || true)
  case "$STATUS" in
    running)    [ -n "$RUN_URL" ] && echo "<a href='${RUN_URL}'>Running&hellip;</a>" || echo "Running&hellip;" ;;
    not-needed) echo "Not needed" ;;
    done)       echo "<a href='$1/$2/ai-analysis/index.html'>View analysis</a>" ;;
    failed)     [ -n "$RUN_URL" ] && echo "<a href='${RUN_URL}'>Analysis failed</a>" || echo "Analysis failed" ;;
    *)          echo "&ndash;" ;;
  esac
}

LANDING_PAGE="gh_pages/index.html"

echo "<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Execution Reports</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body {
      font-family: Arial, sans-serif;
      background: #171D35;
      margin: 0;
      padding: 2rem;
      color: #333;
    }
    .container {
      max-width: 600px;
      margin: auto;
      background: white;
      padding: 2rem;
      border-radius: 8px;
      box-shadow: 0 4px 10px rgba(0,0,0,0.1);
    }
    h1 {
      text-align: center;
      margin-bottom: 1.5rem;
    }
    .env {
      margin: 1rem 0;
    }
    .env h2 {
      margin-bottom: 0.5rem;
    }
    a {
      display: inline-block;
      margin: 0.25rem 0;
      text-decoration: none;
      color: #0366d6;
    }
    a:hover {
      text-decoration: underline;
    }
    table { 
      border-collapse: collapse; width: 100%; margin-bottom: 2rem; 
    }
    th, td { 
      padding: 0.5rem; border-bottom: 1px solid #ccc; text-align: left; 
    }
    th {
      background-color: #eaeaea; 
    }
    .logo { max-width: 200px; margin-bottom: 1rem; }
  </style>
</head>
<body>
  <img src="https://hedgehoglab.com/wp-content/uploads/2023/05/Logos.svg" class='logo'>
  <div class="container">
  <h1>Test Report Dashboard</h1>" > "$LANDING_PAGE"

for ENV_DIR in gh_pages/*/; do
  ENV_NAME=$(basename "$ENV_DIR")
  [[ "$ENV_NAME" =~ ^(QA|UAT|DEV|PROD|STAGING)$ ]] || continue

  echo "<h2>Environment: <a href='${ENV_NAME}/index.html'>$ENV_NAME</a></h2>
  <table>
    <thead><tr><th>Execution</th><th>Date</th><th>Pass %</th><th>Link</th>${AI_TH}</tr></thead>
    <tbody>" >> "$LANDING_PAGE"

  REPORT_DIRS=$(find gh_pages/$ENV_NAME -maxdepth 1 -type d -regex ".*/[0-9]+" -printf "%f\n" | sort -nr)
  IS_FIRST=true
  for ID in $REPORT_DIRS; do
    REPORT_DIR="gh_pages/${ENV_NAME}/${ID}"
    TS_FILE="$REPORT_DIR/timestamp.txt"
    HISTORY_TREND_FILE="$REPORT_DIR/history/history-trend.json"

    if [ -f "$TS_FILE" ]; then
      TS=$(cat "$TS_FILE")
    else
      TS=$(date -r "$REPORT_DIR" +"%Y-%m-%d %H:%M")
    fi

    if [ -f "$HISTORY_TREND_FILE" ]; then
      PASSED=$(jq '.[0].data.passed' "$HISTORY_TREND_FILE")
      TOTAL=$(jq '.[0].data.total' "$HISTORY_TREND_FILE")
      if [ "$TOTAL" -gt 0 ]; then
        PASS_PERCENT=$(( 100 * PASSED / TOTAL ))
      else
        PASS_PERCENT="N/A"
      fi
    else
      PASS_PERCENT="N/A"
    fi
  
    if [ "$IS_FIRST" = true ]; then
      LABEL=" <span style='background-color:#007bff;color:#fff;padding:2px 6px;border-radius:4px;font-size:0.8rem;'>Latest</span>"
      IS_FIRST=false
    else
      LABEL=""
    fi
  
    AI_TD=""
    if [ "$AI_ANALYSIS" = "true" ]; then
      AI_TD="<td>$(ai_analysis_cell "$ENV_NAME" "$ID")</td>"
    fi

    echo "<tr><td>#${ID} $LABEL</td><td>${TS}</td><td>${PASS_PERCENT}%</td><td><a href='${ENV_NAME}/${ID}/index.html'>View Report</a></td>${AI_TD}</tr>" >> "$LANDING_PAGE"
  done

  echo "</tbody></table>" >> "$LANDING_PAGE"
done

echo "</body></html>" >> "$LANDING_PAGE"
