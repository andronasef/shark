import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import robotsTxt from 'astro-robots-txt';
import partytown from '@astrojs/partytown';

export default defineConfig({
  site: 'https://shark.andronasef.com',
  base: '/',
  output: 'static',
  // Partytown runs Google Analytics in a web worker so it stays off the main thread.
  integrations: [sitemap(), robotsTxt(), partytown({ config: { forward: ['dataLayer.push'] } })],
  image: { layout: 'constrained' },
});
