# Deployment and domain setup

The site is built as static HTML/CSS/JavaScript. It does not require a server-side runtime, database, environment secret, or SPA fallback.

## GitHub Pages

Use GitHub Actions as the Pages source. The workflow at `.github/workflows/deploy-website.yml` builds `website/` and publishes its `dist/` directory. Configure the new repository's Pages source as **GitHub Actions**. The generated output includes a root `CNAME` file with `creativerewardapp.tech`.

At the domain registrar, add the apex DNS records GitHub currently documents for Pages and optionally the `www` CNAME. Check the provider's current custom-domain page and the repository's Pages settings immediately before changing DNS. Do not leave conflicting AAAA/A/ALIAS records. After DNS resolves, set the custom domain in Pages and enable HTTPS once GitHub finishes issuing the certificate. GitHub documents its current record values and HTTPS status in its [custom-domain guide](https://docs.github.com/en/pages/configuring-a-custom-domain-for-your-github-pages-site/managing-a-custom-domain-for-your-github-pages-site) and [HTTPS guide](https://docs.github.com/en/pages/getting-started-with-github-pages/securing-your-github-pages-site-with-https).

The primary public URLs will be `/`, `/privacy/`, `/terms/`, `/delete-account/`, and the same page paths prefixed with `/ar/`. Astro creates actual directory-index files. `/app-ads.txt` is a separate plain text file and is not rewritten to HTML.

## Vercel alternative

Set the Vercel project's root directory to `website`; framework Astro; build command `npm run build`; output directory `dist`. Add the apex and `www` domains in Project Settings. Choose `creativerewardapp.tech` as primary and redirect `www` to the apex. Vercel may suggest `www` as primary; either direction works if one canonical redirect is configured consistently. Apply only the DNS records Vercel displays for this project, then wait for certificate issuance. See [Vercel custom domains](https://vercel.com/docs/domains/set-up-custom-domain) and [domain redirects](https://vercel.com/docs/domains/working-with-domains/deploying-and-redirecting).

`vercel.json` adds response security headers. GitHub Pages does not offer per-site response-header configuration; its deployment therefore relies on static output, HTTPS enforcement, and the absence of third-party scripts/forms rather than those Vercel headers.

## Post-deployment verification

```sh
curl -i https://creativerewardapp.tech/app-ads.txt
curl -I https://creativerewardapp.tech/privacy/
curl -I https://creativerewardapp.tech/ar/privacy/
curl -I https://www.creativerewardapp.tech/app-ads.txt
```

Check that app-ads returns `200`, a text content type, and exactly `google.com, pub-6633902647647422, DIRECT, f08c47fec0942fa0` (plus a final newline). Check whether `www` redirects to the apex and that the redirect preserves the requested path. These URLs are not considered live or verified until the site is deployed and tested over HTTPS.
