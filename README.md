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

#### ✅ What It Does

- Downloads every `allure-results-*` artifact of the run and merges them into a single Allure report.
- Cleans old reports (older than `keep_reports`).
- Maintains Allure history for trend graphs (`history.json`, etc.).
- Injects metadata (`executor.json`, `environment.properties`).
- Generates the full HTML report using Allure CLI.
- Creates a redirect `index.html` for latest environment report.
- Updates a central landing page with links and pass stats.

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
