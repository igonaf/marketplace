---
name: laravel-slim-architecture
description: Controllers must only accept a FormRequest, call a single Action or Service class, and return a Resource or an Inertia/View response; all database reads/writes live in app/Actions or app/Services, never directly in Controllers or in .tsx/Blade views; every new PHP class needs declare(strict_types=1) and PHP 8.2+ typed properties; multi-step writes must be wrapped in DB::transaction(). Use this proactively whenever writing or editing a Controller, Model, Action, Service, FormRequest, or Resource in app/, whenever scaffolding a new entity/CRUD feature, and whenever the user asks for a code review of a controller, mentions "fat controllers", "business logic in controllers", "slim controllers", or "where should this query/logic live". Also trigger when a controller method is about to call Model::create/update/delete/save/query-builder methods directly.
disable-model-invocation: false
user-invocable: true
---

# Slim Controller Architecture

A controller's job is to receive a validated request, hand it to exactly one object that knows how to do the work, and shape the response. Every other responsibility — querying, writing, branching on business rules — belongs somewhere else. This keeps controllers readable in isolation and keeps business logic testable without spinning up HTTP.

## The rule in one picture

```
FormRequest  →  Controller::method()  →  Action or Service  →  Resource | Inertia::render | View
                     (1 call only)         (owns DB + rules)
```

If a controller method has more than one line that isn't `return`, a request type-hint, or a call into an Action/Service, that's the signal to extract.

## Checklist for every Controller method

- [ ] **Parameter**: a `FormRequest` subclass for anything that writes data (even if validation is thin — it's also where authorization (`authorize()`) and typed `validated()` shapes live). Route-model-bound parameters (e.g. `Category $category`) are fine alongside it.
- [ ] **Body**: exactly one call out — `app(SomeAction::class)->handle(...)` or `SomeService::method(...)` (or constructor/method-injection of the Action/Service). No `Model::`, no query builder, no conditional business logic inline.
- [ ] **Return**: an API Resource (`CategoryResource`), or for Inertia pages, `Inertia::render('page-name', [...])` where the props array is built from data the Action/Service already returned — not from a fresh query written inline in the controller.


## Actions vs Services — how to choose

- **Action** (`app/Actions/`): one verb, one job, tied to a single use case. Name it after what it does: `CreateCategoryAction`, `DeleteCategoryAction`. Exposes a single `handle()` (or `__invoke()`) method. Reach for this by default — most CRUD operations are one Action per operation.
- **Service** (`app/Services/`): a cohesive set of related operations with shared state or dependencies (e.g. `CategoryService` wrapping several related queries, or a service that talks to an external API). Reach for this when you have 3+ related operations that would otherwise be a pile of near-duplicate Actions.

Both live under `app/Actions/<Entity>/` or `app/Services/`, both get `declare(strict_types=1);`, and both are where `Model` classes get touched — never from a controller, never from a `.tsx` page, never from a Blade view.

## No direct Model access from views

Because this stack is Inertia + React, "views" means two things to watch for:
- **`.tsx` pages/components** never call PHP/Eloquent, obviously — but watch for controllers passing raw `Model` instances (with every column, including ones you didn't mean to expose) straight into `Inertia::render()` props. Shape the data through a Resource/Action first so the props array only contains what the page needs.
- **Blade views**, if any are added later (e.g. for emails/PDFs), must receive pre-built data from the controller/Action — never call `Model::` from inside a `.blade.php` file.

## Typed properties and `declare(strict_types=1)`

Every new PHP file in this project starts with:

```php
<?php

declare(strict_types=1);
```

Every class property gets an explicit PHP 8.2+ type, including constructor-promoted properties:

```php
final class CreateCategoryAction
{
    public function __construct(
        private readonly CategoryRepository $categories = new CategoryRepository(),
    ) {}

    public function handle(array $data): Category
    {
        return DB::transaction(fn () => $this->categories->create($data));
    }
}
```

Avoid untyped `public $foo;` or relying on inferred types — Larastan at level 7 (this repo's configured level, see `phpstan.neon`) will flag missing types, so this isn't just style, it's what CI enforces. 
Provide additional note to a user if you not sure about the type.

## Wrapping multi-step writes in `DB::transaction()`

Any Action/Service method that performs **more than one** database write (e.g. create a record *and* attach relations, or update a model *and* write a related log/audit row) must wrap those writes:

```php
return DB::transaction(function () use ($data) {
    $category = Category::create($data);
    $category->tags()->sync($data['tag_ids'] ?? []);

    return $category;
});
```

A single, standalone write (one `create()` call and nothing else) doesn't need a transaction wrapper — wrapping it adds nothing since there's no second statement that could leave data half-committed. Reach for `DB::transaction()` specifically when a failure partway through would leave the database in an inconsistent state.

## Worked example: refactoring a fat controller

See `references/category-refactor-example.md` for a full before/after walkthrough using this exact pattern applied to a CRUD controller — useful as a template when extracting any existing fat controller in this codebase.

## Gotchas

- If you find yourself about to write `Category::create(...)`, `->update(...)`, `->delete(...)`, `Category::with(...)->get()`, or any other Eloquent call *inside a controller method*, stop — that line belongs in an Action or Service.
- Skip typed properties declarations and provide notification if current environment has PHP version is less then 8.2.

## When reviewing existing code

Flag if done, in order of severity:
- [ ] Direct `Model::create/update/delete/save()` calls inside a Controller — these bypass the Action/Service layer entirely.
- [ ] Multi-step writes not wrapped in `DB::transaction()`.
- [ ] Missing `declare(strict_types=1);` or untyped properties in new/touched files.
- [ ] Controllers returning raw Eloquent models/collections instead of a Resource, when the response is JSON/API-shaped.
- [ ] Query-builder calls (`Model::with(...)->get()`, `Model::where(...)->first()`) inline in a controller — even for simple read-only Inertia props, move these into a Service/Action so the controller stays a pure pass-through.
