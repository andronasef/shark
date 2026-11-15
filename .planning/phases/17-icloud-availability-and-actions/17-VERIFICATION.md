---
phase: 17-icloud-availability-and-actions
status: human_needed
verifier: executor self-check (lean GSD)
---
- Unit: CloudStateTests 4/4 (state mapping, no badge for synced/non-cloud, local files, wait returns immediately). Full suite passes except the existing Reveal path test.
- Live: app builds, launches and renders its sidebar and toolbar after the FileItem change.
- NOT validated: real iCloud behaviour. This Mac has no iCloud Drive (`~/Library/Mobile Documents/com~apple~CloudDocs` is absent), so badges, Download Now, Remove Download, download-before-open, and error states were never exercised against a real provider or account. Recorded as unavailable per the phase criteria. Legacy `.icloud` placeholder files are not handled.
