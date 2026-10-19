---
description: generates new entity
---
scaffold

Generate all the supporting files, following Laravel conventions for the version this project
uses (check composer.json first and adapt if needed).

## Entity
- Name: {$ARGUMENTS[0]} (singular, StudlyCase, e.g. Invoice), if plural input then change to singular
- Table: use $ARGUMENTS[0] in plural snake_case, (e.g. invoices)
- Description: {one or two sentences about what this entity represents}

## Fields
| Name | Type | Nullable | Default | Notes |
|------|------|----------|---------|-------|
| {field} | {string/integer/decimal/boolean/date/json/enum...} | yes/no | {value or -} | {validation rules, unique, index, etc.} |

## Relationships
- make assamption as a comment

## Enums / constants
- {e.g. status: draft, sent, paid}

## What to generate
1. **Migration**: correct column types, nullability, defaults, indexes,
   unique constraints, foreign keys with onDelete behaviour, timestamps,
   and soft deletes if {yes/no}.
2. **Model**: $fillable (no $guarded = [] shortcuts), $casts (dates, enums,
   json, booleans), relationships with return types, scopes for common
   filters, and a PHPDoc block listing properties.
3. **Enum classes** (if any) as backed PHP enums in app/Enums.
4. **Form Requests**: {$ARGUMENTS[0]}StoreRequest and {$ARGUMENTS[0]}UpdateRequest
   with authorize() and rules(). Use Rule objects for enums and unique checks.
   Update rules must ignore the current record for unique fields.
5. **Controller**: {$ARGUMENTS[0]}Controller as a resource controller
   (index, create, store, show, edit, update, destroy). Use route model
   binding, the Form Requests above, and eager loading in index() to avoid
   N+1 queries. Keep business logic out of the controller: put it in an
   Action or Service class under app/Actions/{$ARGUMENTS[0]}/ if it is more
   than a simple save.
6. **Routes**: the resource route added to {routes/web.php or routes/api.php},
   inside the existing middleware group.
7. **Factory and Seeder**: a model factory with realistic fake data and a
   state for each enum value. Add the seeder call to DatabaseSeeder only if
   requested.
8. **Feature tests**: tests for each controller action covering the happy
    path, validation failures, and authorization failures.

## Constraints
- Follow PSR-12 and the coding style already used in this project.
- Use artisan generators where they help (make:model, make:migration,
  make:request, make:controller, make:policy, make:factory, make:test),
  then edit the generated files. Do not leave stub code behind.
- Do not change existing migrations or models unrelated to this entity.
- Do not hard-code secrets, environment values, or sample credentials.
- If no argumets provided, reply there are missed input
- If something in the spec is ambiguous, list the assumptions you made
  at the top of your reply before the code.

## Output
- Show the file path above each file.
- After the files, list the commands I need to run (migrate, test, etc.).
- Finish with a short checklist of anything I should review manually
  (business rules, authorization, indexes on large tables).