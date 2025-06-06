# 📊 Allure Report Publisher for GitHub Actions

This repository provides a pair of GitHub composite actions to:

1. 🧪 **Push individual Allure test results** (per browser) to the `gh_pages` branch.
2. 📈 **Merge and publish a full Allure report**, maintain historical trends, and generate a visual dashboard per environment.

---

## 🧩 Actions Overview

### 1. `Push Allure Results`

Pushes individual `allure-results/` from a test job into a per-browser folder on the `gh_pages` branch.

#### 🔧 Inputs

| Input                | Description                                      | Required | Default     |
|----------------------|--------------------------------------------------|----------|-------------|
| `branch`             | Target branch to push the results                | ❌       | `gh_pages`  |
| `browser`            | Browser name (used as folder name)               | ❌       | `all`       |
| `github-token`       | GitHub token with push permissions               | ✅       | –           |
| `number-of-browsers` | Number of parallel browser executions expected   | ❌       | `5`         |

#### ✅ What It Does

- Copies `allure-results/` into `results-${browser}` on `gh_pages`.
- Commits and pushes with retry logic (to avoid rebase conflicts in parallel jobs).

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

#### ✅ What It Does

- Merges per-browser results into a single Allure report.
- Cleans old reports (older than `keep_reports`).
- Maintains Allure history for trend graphs (`history.json`, etc.).
- Injects metadata (`executor.json`, `environment.properties`).
- Generates the full HTML report using Allure CLI.
- Creates a redirect `index.html` for latest environment report.
- Updates a central landing page with links and pass stats.

---

📂 Output Structure (on gh_pages)
gh_pages/
├── index.html                     # Central dashboard
├── QA/
│   ├── index.html                 # Redirects to latest QA report
│   ├── 1234/                      # Report #1234
│   └── last-history/             # Keeps latest history files
└── UAT/
    └── ...

🧪 Requirements
Your test jobs must output Allure results to allure-results/.
Requires allure-commandline via npm.

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
        uses: Simeon-Zografov/build-allure-report-action/.github/actions/push-individual-report@main
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
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
        uses: Simeon-Zografov/build-allure-report-action/.github/actions/push-individual-report@main
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
          browser: firefox

  publish-report:
    needs: [test-chrome, test-firefox]
    runs-on: ubuntu-latest
    steps:
      - uses: Simeon-Zografov/build-allure-report-action/.github/actions/build-report@main
        with:
          env_name: QA
          report_id: ${{ github.run_number }}
          github-token: ${{ secrets.GITHUB_TOKEN }}



