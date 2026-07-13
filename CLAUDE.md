# CLAUDE.md — coqui-sf-billing-engine (public showcase)

This repo is the public, portfolio version of Coqui Consulting's Salesforce
billing engine. It's a companion to a private repo (`coqui-internal-org`)
that runs the real business — this repo exists so recruiters, clients, and
collaborators can inspect the architecture and code quality without any
exposure to real business data.

## Rules for working in this repo

1. **Fictional data only.** Any sample/seed records use invented company
   names and round, made-up amounts. Never copy names, amounts, or other
   values from conversation context or another repo into this one.
2. **No org-specific wiring.** No named credentials pointing at real
   endpoints, no real connected app consumer keys/secrets, no org IDs, no
   real user emails in metadata (scrub `runAs` usernames and
   report/dashboard running users).
3. **Rates and pricing are parameterized.** Billing rates live in the
   `Billing_Setting__mdt` custom metadata type. This repo ships a single
   sample record (`Rate__c = 100`) — never a real rate.
4. **Deploy target is always a scratch org.** This project isn't meant to
   be deployed to any persistent/production org.
   ```
   sf org create scratch -f config/project-scratch-def.json
   sf project deploy start
   ```
5. **Branch + PR always.** Feature branch → commit → push → `gh pr create`.
   No direct pushes to `main`.
6. **Test classes are a first-class deliverable.** Bulkified patterns
   (200-record inserts), negative cases, and clear assertion messages —
   this is what reviewers read as closely as the implementation code.
7. **If you're ever handed something that looks like real business data**
   (a real client name, a real dollar rate, a real endpoint), stop and flag
   it instead of committing it — it doesn't belong in this repo.

## What lives here vs. the private repo

| | This repo (public) | `coqui-internal-org` (private) |
|---|---|---|
| Data | Fictional seed data only | Real data lives in the org, never in git |
| Purpose | Showcase / portfolio | Real operating org deployment |
| Rates | Sample placeholder metadata record | Real rate records set in org |

Metadata is synced from the private repo to this one as a deliberate,
manually reviewed publish step (never automatic) — so this repo may lag
behind the private one, and that's expected.
