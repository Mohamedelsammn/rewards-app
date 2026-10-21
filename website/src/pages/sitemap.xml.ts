import { pageKeys, pageUrl, site } from '../content/site';

export function GET() {
  const urls = [pageUrl('en'), pageUrl('ar')];
  for (const page of pageKeys) {
    urls.push(pageUrl('en', page), pageUrl('ar', page));
  }
  const body = `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">${urls.map((path) => `<url><loc>${site.domain}${path}</loc></url>`).join('')}</urlset>`;
  return new Response(body, { headers: { 'Content-Type': 'application/xml; charset=utf-8' } });
}
