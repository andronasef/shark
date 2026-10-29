import type { APIRoute } from 'astro';
import { getCollection } from 'astro:content';
import { featureGroups } from '../data/features';

// llms.txt (https://llmstxt.org): a plain-text map of the site for AI search tools.
export const GET: APIRoute = async ({ site }) => {
  const url = (path: string) => new URL(path, site).href;
  const guides = await getCollection('guides');
  const body = `# Shark – File Manager

> Shark is a free, open source (Apache 2.0) native file manager and Finder alternative for macOS 14 or later, on Apple silicon and Intel. It keeps Finder's look and adds folder tabs, side-by-side split panes, a built-in terminal drawer, hover previews, cut and paste, an editable path bar, a command palette and an optional File Explorer style folder tree. It is made by Andrew Nasef and is currently in alpha.

Install with Homebrew: \`brew install --cask andronasef/shark/shark\`, or download the DMG from GitHub Releases. Shark browses local folders and volumes mounted in macOS; it has no built-in remote-server or cloud-account client.

## Main pages

- [Home](${url('/')}): overview, install options and FAQ
- [All features](${url('/features/')}): the complete list of what Shark does today
- [Privacy policy](${url('/privacy/')}): files never leave the Mac; anonymous usage stats and crash reports can be turned off
- [Source code](https://github.com/andronasef/shark): GitHub repository and releases

## Guides

${guides.map(g => `- [${g.data.title}](${url(`/guides/${g.id}/`)}): ${g.data.description}`).join('\n')}

## Features

${featureGroups.map(g => `### ${g.title}\n\n${g.features.map(f => `- ${f.title}${f.shortcut ? ` (${f.shortcut})` : ''}: ${f.description}`).join('\n')}`).join('\n\n')}
`;
  return new Response(body, { headers: { 'Content-Type': 'text/plain; charset=utf-8' } });
};
