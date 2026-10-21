# Creative Rewards App official website

Static bilingual Astro site for `https://creativerewardapp.tech/`. The website is intentionally isolated in this `website/` directory; it does not depend on Flutter at build time and contains no Supabase credentials, tracking, participant lookup, or public deletion API.

## Local development

Requirements: Node.js 24 and npm.

```sh
npm ci
npm run dev
```

Build and verify the production output:

```sh
npm run check
npm run build
npm test
```

The static output is `dist/`. Routes are generated as real files, so direct visits work for `/privacy/`, `/terms/`, `/delete-account/`, their Arabic equivalents under `/ar/`, and `/app-ads.txt` without a single-page-app fallback.

## GitHub Pages (preferred)

1. Create a GitHub repository and push this project.
2. In repository **Settings → Pages**, set the source to **GitHub Actions**.
3. Keep the repository default branch named `main` or edit `.github/workflows/deploy-website.yml` to match it.
4. The workflow installs dependencies, runs type/content checks, builds the site, runs route and `app-ads.txt` assertions, and deploys `website/dist`.
5. The build output includes the root `CNAME` file for `creativerewardapp.tech`. In Pages settings, use that custom domain and enable **Enforce HTTPS** after DNS has propagated and the certificate is ready.
6. At the registrar, configure the GitHub Pages apex records using the current values in [GitHub's custom-domain guide](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site). To support `www`, add the corresponding `www` CNAME to the GitHub Pages host shown in the repository settings. DNS is not changed by this project.

Astro emits directory-index pages for the legal routes. GitHub Pages serves `/privacy/` from `privacy/index.html`; no SPA rewrite is needed. `app-ads.txt` is copied unchanged from `public/` to the site root.

## Vercel alternative

Import the repository and set **Root Directory** to `website`. Vercel detects Astro; the build command is `npm run build` and output directory is `dist`. `vercel.json` sets trailing-slash handling and security response headers. Add `creativerewardapp.tech` and `www.creativerewardapp.tech` in Project Settings → Domains, select the apex as primary and redirect `www` to it, then apply the exact DNS records Vercel shows for this project. Wait for HTTPS certificate issuance and verify `/app-ads.txt` returns plain text. This project does not deploy to Vercel automatically.

## Legal content and publication review

The source audit is in `../docs/privacy-data-audit.md`. Legal copy is in `src/content/site.ts`, with English and Arabic kept together. `legalOperatorName` is intentionally blank until the owner confirms the operator's legal identity; public text identifies the app and its contact without inventing a company. The owner-confirmed support address is stored beside the domain and package ID in that file.

The Data Deletion page provides a support request route, not an automated deletion claim. The code's deletion RPC migration says it has not been applied, and no in-app action was found. The current Play listing's Data Safety answers and deletion claim conflict with the inspected source; review `docs/privacy-data-audit.md` before updating Play Console.

## Domain and Google Play checklist

- Configure DNS only after selecting the hosting provider; verify current provider instructions rather than relying on stale record values.
- Confirm both apex and `www` resolve as intended, HTTPS is valid, and the apex is the canonical host.
- Test `https://creativerewardapp.tech/app-ads.txt` for HTTP 200 and exact plain text after deployment, then check AdMob crawler status. The file does not integrate website display ads.
- Add the developer website and final Privacy Policy/Data Deletion URLs to Google Play Console after legal review.
- Reconcile Data Safety, account/data deletion, age/eligibility, AdMob/UMP consent configuration, Firebase disclosures, and the actual production Supabase migration/RLS state.
- Confirm the operator identity before setting `legalOperatorName` or publishing a legal entity name.

## Content updates

Edit `src/content/site.ts` for translated page text, routes and metadata. The current policy date is written in the translations; update both languages together when the policy changes. `public/app-ads.txt` must remain exactly one line:

```text
google.com, pub-6633902647647422, DIRECT, f08c47fec0942fa0
```
