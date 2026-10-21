import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import { test } from 'node:test';

const output = new URL('../dist/', import.meta.url);
const read = (path) => readFile(new URL(path, output), 'utf8');

test('app-ads.txt is exact and remains a plain text static file', async () => {
  const text = await read('app-ads.txt');
  assert.equal(text, 'google.com, pub-6633902647647422, DIRECT, f08c47fec0942fa0\n');
  assert.equal(text.includes('<html'), false);
});

test('all required direct routes are emitted in English and Arabic', async () => {
  for (const path of ['', 'privacy', 'terms', 'delete-account', 'contact', 'about', 'ar', 'ar/privacy', 'ar/terms', 'ar/delete-account', 'ar/contact', 'ar/about']) {
    const html = await read(path ? `${path}/index.html` : 'index.html');
    assert.match(html, /<!doctype html>/i, path);
    assert.match(html, /Creative Rewards App/, path);
  }
});

test('public routes declare language, direction, a skip link, and a main landmark', async () => {
  for (const [path, lang, dir] of [['index.html', 'en', 'ltr'], ['privacy/index.html', 'en', 'ltr'], ['ar/index.html', 'ar', 'rtl'], ['ar/privacy/index.html', 'ar', 'rtl']]) {
    const html = await read(path);
    assert.match(html, new RegExp(`<html lang="${lang}" dir="${dir}"`), path);
    assert.match(html, /href="#main"/, path);
    assert.match(html, /<main id="main">/, path);
    assert.match(html, /aria-label="Main navigation|aria-label="التنقل الرئيسي/, path);
  }
});

test('local links on public pages resolve to generated files', async () => {
  const pages = ['index.html', 'privacy/index.html', 'terms/index.html', 'delete-account/index.html', 'contact/index.html', 'about/index.html', 'ar/index.html', 'ar/privacy/index.html', 'ar/terms/index.html', 'ar/delete-account/index.html', 'ar/contact/index.html', 'ar/about/index.html'];
  for (const sourcePath of pages) {
    const html = await read(sourcePath);
    const links = [...html.matchAll(/\shref="(\/[^"#?]*)"/g)].map((match) => match[1]);
    for (const link of links) {
      if (link === '/') continue;
      const target = link.endsWith('/') ? `${link.slice(1)}index.html` : link.slice(1);
      await read(target).catch(() => assert.fail(`${sourcePath} points to missing ${link}`));
    }
  }
});

test('privacy page discloses app data and advertising providers', async () => {
  const html = await read('privacy/index.html');
  for (const text of ['phone number', 'Supabase', 'Firebase', 'AdMob', 'App Open', 'Rewarded', 'deletion']) {
    assert.ok(html.toLowerCase().includes(text.toLowerCase()), `privacy page should include ${text}`);
  }
  assert.doesNotMatch(html, /No data collected|we collect no data/i);
});

test('deletion page does not claim instant or automated success', async () => {
  const html = await read('delete-account/index.html');
  assert.match(html, /no public phone-number deletion form/i);
  assert.match(html, /phone number by itself is not proof of identity/i);
  assert.doesNotMatch(html, /your data has been deleted|deleted instantly/i);
});

test('sitemap and crawler rules expose the public site and do not block crawlers', async () => {
  const sitemap = await read('sitemap.xml');
  const robots = await read('robots.txt');
  assert.match(sitemap, /https:\/\/creativerewardapp\.tech\/privacy\//);
  assert.match(sitemap, /https:\/\/creativerewardapp\.tech\/ar\/privacy\//);
  assert.match(robots, /User-agent: \*/);
  assert.match(robots, /Allow: \//);
  assert.doesNotMatch(robots, /Disallow: \/app-ads\.txt/);
  assert.equal(await read('CNAME'), 'creativerewardapp.tech\n');
});

test('built pages contain no known credentials or service-role secrets', async () => {
  const files = ['index.html', 'privacy/index.html', 'terms/index.html', 'delete-account/index.html', 'ar/privacy/index.html'];
  const pages = await Promise.all(files.map((file) => read(file)));
  const joined = pages.join('\n');
  assert.doesNotMatch(joined, /service[_-]?role|SUPABASE_SERVICE_ROLE|sb_secret_[A-Za-z0-9]+/i);
  assert.ok(joined.includes('mohamed.elsamman.dev@gmail.com'));
});
