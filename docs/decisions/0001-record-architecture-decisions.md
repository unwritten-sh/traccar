# 1. Record architecture decisions

Date: 2026-11-01

Status: accepted

## Context

Traccar has more than 10,000 commits and very few written explanations of why the code is shaped the way it is. New contributors and coding agents must guess, and they guess wrong on things like schema changes or where to put a new protocol.

## Decision

We keep short architecture decision records in `docs/decisions/`, one Markdown file per decision, numbered `NNNN-short-title.md`. Each record has:

- **Context**: the problem and the forces at play.
- **Decision**: what we do, in one or two paragraphs.
- **Consequences**: what gets easier, what gets harder, what to watch.

A record is never rewritten after it is accepted. When a decision changes, a new record supersedes the old one and the old one gets `Status: superseded by NNNN`.

Records that describe a decision found in the code but never written down by the team say "Inferred from the code, to be confirmed by the team."

## Consequences

- Agents and humans can read why before they change how.
- A pull request that changes an important design choice should add a record.
