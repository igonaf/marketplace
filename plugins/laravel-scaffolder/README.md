# laravel-scaffolder

## Purpose

A Claude Code plugin for this Laravel 13 + Inertia + React project. It bundles:

- a slash command that scaffolds a complete CRUD entity (migration, model, enums, Form Requests, controller, routes, factory, feature tests);
- a skill that enforces slim controller architecture (Actions/Services hold the database and business logic);
- a `PreToolUse` hook that blocks destructive Artisan and shell commands.

The plugin is a demo for homework 5.5.

## Install

The plugin is not published to a marketplace. Load it from the local folder:

```bash
claude --plugin-dir claude-plugins/laravel-scaffolder
```

Requirements:

- `jq` on the `PATH` (used by the hook script to read the tool input).
- `bash` available at `/usr/bin/env bash` (macOS and Linux both work).

## Commands

| Command | Arguments | Description |
|---------|-----------|-------------|
| `/scaffoldEntity` | `<Name>` (singular or plural, e.g. `Invoice` or `Invoices`), then the field table, relationships, and enums in the prompt | Generates all supporting files for the entity, following the Laravel version in `composer.json`. |

The command body is a template with placeholders (`{$ARGUMENTS[0]}`, field table, enums, soft-delete flag). It asks Claude to list its assumptions at the top of the reply, output each file path above its contents, and finish with the commands to run and a manual review checklist.

If no argument is passed, the command replies that input is missing.

## Skills

| Skill | Purpose | Contents |
|-------|---------|----------|
| `laravel-slim-architecture` | Controllers accept a Form Request, call one Action or Service, and return a Resource or an Inertia response. Database access stays in `app/Actions` or `app/Services`. Every new PHP class uses `declare(strict_types=1)` and typed properties. Multi-step writes use `DB::transaction()`. | `SKILL.md`, `references/category-refactor-example.md` (before/after refactor), `evals/evals.json` |

The skill triggers on controller, model, action, service, Form Request, and resource work, and on code-review requests about "fat controllers".

## Hooks

| Event | Matcher | Script | Effect |
|-------|---------|--------|--------|
| `PreToolUse` | `Bash` | `hooks/block-dangerous.sh` | Blocks the command with exit code 2 and an error message. |

Blocked patterns (matched as substrings of the Bash command):

- `artisan migrate:fresh`
- `artisan migrate:reset`
- `artisan migrate:refresh`
- `artisan db:wipe`
- `rm -rf /`

The hook reads the command from the JSON input via `jq`. If `jq` is missing, the command is empty and the hook allows everything (fail-open).
