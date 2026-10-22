import { defineConfig } from 'astro/config';
import sitemap from '@astrojs/sitemap';
import robotsTxt from 'astro-robots-txt';

export default defineConfig({
  site: 'https://shark.andronasef.com',
  base: '/',
  output: 'static',
  integrations: [sitemap(), robotsTxt()],
});
