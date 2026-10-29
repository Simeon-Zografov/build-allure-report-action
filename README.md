# 📊 Allure Report Publisher for GitHub Actions

This repository provides a pair of GitHub composite actions to:

1. 🧪 **Upload individual Allure test results** (per browser or shard) as workflow artifacts.
2. 📈 **Merge and publish a full Allure report**, maintain historical trends, and generate a visual dashboard per environment.

---

## 🧩 Actions Overview

### 1. `Push Allure Results`

Uploads a job's `allure-results/` as a workflow artifact named `allure-results-${browser}`, for `Publish Allure Report` to merge.

#### 🔧 Inputs

| Input            | Description                                              | Required | Default          |
|------------------|----------------------------------------------------------|----------|------------------|
| `browser`        | Name of this job's results (browser, shard, ...)          | ❌       | `all`            |
| `results-path`   | Directory containing the Allure results                  | ❌       | `allure-results` |
| `retention-days` | How long to keep the uploaded results                    | ❌       | `3`              |

`branch`, `github-token` and `number-of-browsers` are still accepted but no longer used.

#### ✅ What It Does

- Uploads `allure-results/` as the `allure-results-${browser}` artifact of the current run.
- Skips the upload (without failing) when the job produced no results.

> Results used to be committed to `gh_pages` from every job. Parallel jobs then raced each other's
> pushes (`fatal: shallow file has changed since we read it`), and a cancelled run left its
> results on the branch to be merged into the next report. Artifacts belong to one run, so
> neither can happen.

---

### 2. `Publish Allure Report`

Merges results from all browsers, generates a full Allure report, tracks historical runs, and builds dashboards for multiple environments (QA, UAT, etc.).

#### 🔧 Inputs

| Input           | Description                             | Required | Default      |
|----------------|------------------------------------------|----------|--------------|
| `branch`        | Branch to publish reports to            | ❌        | `gh_pages`  |
| `env_name`      | Environment name (QA, UAT, etc.)        | ✅        | –           |
| `report_id`     | Unique ID for the report (e.g., run ID) | ✅        | –           |
| `keep_reports`  | Number of past reports to retain        | ❌        | `10`        |
| `results_pattern` | Name pattern of the results artifacts | ❌        | `allure-results-*` |
| `build_name`    | Build name shown in the report          | ❌        | `Automated tests` |
| `allure_version` | Allure CLI version to generate with    | ❌        | `2.36.0`    |
| `ai_analysis`   | Add an "AI analysis" column to the dashboard (see [AI analysis](#3-publish-ai-analysis)) | ❌ | `false` |

#### 📤 Outputs

| Output               | Description |
|----------------------|-------------|
| `ai_analysis_needed` | `true` when `ai_analysis` is on and the run had failed or broken tests, so an analysis should follow - use it as the analysis job's condition. `false` otherwise. |

#### ✅ What It Does

- Downloads every `allure-results-*` artifact of the run and merges them into a single Allure report.
- Cleans old reports (older than `keep_reports`).
- Maintains Allure history for trend graphs (`history.json`, etc.).
- Injects metadata (`executor.json`, `environment.properties`).
- Generates the full HTML report using Allure CLI.
- Creates a redirect `index.html` for latest environment report.
- Updates a central landing page with links and pass stats.
- With `ai_analysis: true`, records each run's analysis status and adds the "AI analysis" column. With the default `false` the landing page is exactly as before.

---

#### 📂 Output Structure (on gh_pages)
gh_pages/  
├── index.html   &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;              # Central dashboard  
├── QA/  
│ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  ├── index.html     &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;                # Redirects to latest QA report  
│ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  ├── 1234/        &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;              # Report #1234  
│ &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;  └── last-history/      &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;       # Keeps latest history files  
└── UAT/  
    └── ...  

#### 🧪 Requirements  
Your test jobs must output Allure results to allure-results/ and upload them with `Push Allure Results` in the same workflow run.  
The Allure CLI (allure-commandline) is installed via npm at the pinned `allure_version`.  
When publishing with `peaceiris/actions-gh-pages`, set `force_orphan: true` so the branch keeps a single commit instead of growing by a full report snapshot on every run.

---

### 3. `Publish AI Analysis`

Adds an AI-written analysis of a run (a Markdown file, e.g. from `anthropics/claude-code-action`) to that run's report and links it from the dashboard. Use it together with `ai_analysis: true` on `Publish Allure Report`.

The dashboard's "AI analysis" column shows, per run:

| Cell              | When |
|-------------------|------|
| *Running…*        | The run had failed or broken tests and the analysis isn't published yet (links to the GitHub Actions run) |
| *Not needed*      | Every test passed |
| *View analysis*   | The analysis is published - links to `<env>/<id>/ai-analysis/index.html` |
| *Analysis failed* | `Publish AI Analysis` ran without a report file (links to the GitHub Actions run) |
| –                 | Runs from before the column was turned on |

#### 🔧 Inputs

| Input            | Description                                                  | Required | Default                  |
|------------------|--------------------------------------------------------------|----------|--------------------------|
| `branch`         | Branch the reports are published to                          | ❌       | `gh_pages`               |
| `env_name`       | Environment the report was published under                   | ✅       | –                        |
| `report_id`      | Build/Run ID of the report                                   | ✅       | –                        |
| `report_file`    | The analysis as Markdown; missing or empty = "Analysis failed" | ❌     | `ci-analysis/report.md`  |
| `marked_version` | `marked` version used to render the Markdown                 | ❌       | `18.1.2`                 |

#### ✅ What It Does

- Checks out `gh_pages`, renders the Markdown as a styled page next to the run's Allure report (raw HTML in the Markdown is escaped, not rendered) and keeps the `.md` beside it.
- Marks the analysis done - or failed when there is no report file - and regenerates the landing page.
- Leaves the publishing to your `peaceiris/actions-gh-pages` step, as `Publish Allure Report` does. Run both with `if: always()` so a crashed analysis shows "Analysis failed" instead of "Running…" for good.

```yaml
  analyse:
    needs: [ aggregate ]
    if: always() && needs.aggregate.outputs.ai_analysis_needed == 'true'
    steps:
      # ... produce ci-analysis/report.md ...
      - uses: Simeon-Zografov/build-allure-report-action/.github/actions/publish-ai-report@v2.1.0
        if: always()
        with:
          env_name: QA
          report_id: ${{ github.run_number }}
      - uses: peaceiris/actions-gh-pages@v4
        if: always()
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_branch: gh_pages
          publish_dir: gh_pages
          force_orphan: true
```

## 🚀 Usage Example

Here's how you'd use these two actions in a workflow:

```yaml
name: Run UI Tests

on:
  push:
    branches: [main]

jobs:
  test-chrome:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests on Chrome
        run: |
          # Your test logic here...
          echo "Dummy test run"
      - name: Push Chrome results
        if: always()
        uses: Simeon-Zografov/build-allure-report-action/.github/actions/push-individual-report@main
        with:
          browser: chrome

  test-firefox:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run tests on Firefox
        run: |
          # Your test logic here...
          echo "Dummy test run"
      - name: Push Firefox results
        if: always()
        uses: Simeon-Zografov/build-allure-report-action/.github/actions/push-individual-report@main
        with:
          browser: firefox

  publish-report:
    needs: [test-chrome, test-firefox]
    if: always()
    runs-on: ubuntu-latest
    steps:
      - uses: Simeon-Zografov/build-allure-report-action/.github/actions/build-report@main
        with:
          env_name: QA
          report_id: ${{ github.run_number }}
      - uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_branch: gh_pages
          publish_dir: gh_pages
          force_orphan: true
