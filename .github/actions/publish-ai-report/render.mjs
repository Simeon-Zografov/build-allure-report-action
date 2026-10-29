// Renders the AI analysis Markdown as a standalone HTML page. Raw HTML in the Markdown is
// escaped rather than passed through - the analysis quotes test output and app data.
// Usage: node render.mjs <report.md> <out.html> <title> <dashboard-href> <report-href>
import { readFileSync, writeFileSync } from 'node:fs'
import { Marked } from 'marked'

const [input, output, title, dashboardHref, reportHref] = process.argv.slice(2)
const escapeHtml = text => text.replace(/[&<>"']/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c])

const marked = new Marked({ gfm: true, renderer: { html: ({ text }) => escapeHtml(text) } })
const body = marked.parse(readFileSync(input, 'utf8'))

writeFileSync(output, `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(title)}</title>
  <style>
    body { font-family: Arial, sans-serif; background: #171D35; margin: 0; padding: 2rem 1rem; color: #333; }
    .container { max-width: 960px; margin: auto; background: white; padding: 2rem; border-radius: 8px; box-shadow: 0 4px 10px rgba(0,0,0,0.1); line-height: 1.5; }
    nav { margin-bottom: 1.5rem; font-size: 0.9rem; }
    nav a { color: #0366d6; text-decoration: none; margin-right: 1rem; }
    nav a:hover { text-decoration: underline; }
    h1, h2, h3 { line-height: 1.25; }
    h2 { border-bottom: 1px solid #eaeaea; padding-bottom: 0.3rem; margin-top: 2rem; }
    table { border-collapse: collapse; width: 100%; margin: 1rem 0; display: block; overflow-x: auto; }
    th, td { padding: 0.5rem; border: 1px solid #ddd; text-align: left; vertical-align: top; }
    th { background-color: #eaeaea; }
    code { background: #f4f4f4; padding: 0.1rem 0.3rem; border-radius: 3px; font-size: 0.9em; }
    pre { background: #f4f4f4; padding: 1rem; border-radius: 6px; overflow-x: auto; }
    pre code { background: none; padding: 0; }
    a { color: #0366d6; }
    .logo { max-width: 200px; margin: 0 auto 1rem; display: block; }
  </style>
</head>
<body>
  <img src="https://hedgehoglab.com/wp-content/uploads/2023/05/Logos.svg" class="logo" alt="">
  <div class="container">
    <nav><a href="${dashboardHref}">&larr; All reports</a><a href="${reportHref}">Allure report for this run</a></nav>
${body}
  </div>
</body>
</html>
`)
