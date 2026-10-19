# Worked example: CategoryController

This walks through applying the slim-controller pattern to a typical generated CRUD controller — the same shape you get from most scaffolding tools.

## Before (fat controller)

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\CategoryStoreRequest;
use App\Http\Requests\CategoryUpdateRequest;
use App\Models\Category;
use Illuminate\Http\RedirectResponse;
use Inertia\Inertia;
use Inertia\Response;

class CategoryController extends Controller
{
    public function index(): Response
    {
        return Inertia::render('categories/index', [
            'categories' => Category::with('parent')->latest()->get(),
        ]);
    }

    public function store(CategoryStoreRequest $request): RedirectResponse
    {
        Category::create($request->validated());

        return to_route('categories.index');
    }

    public function update(CategoryUpdateRequest $request, Category $category): RedirectResponse
    {
        $category->update($request->validated());

        return to_route('categories.index');
    }

    public function destroy(Category $category): RedirectResponse
    {
        $category->delete();

        return to_route('categories.index');
    }
}
```

Problems: every method touches `Category::` directly; no `declare(strict_types=1)`; no transactions; the controller is the only place that knows how a category is listed, created, updated, or deleted — none of that is reusable or unit-testable without HTTP.

## After

**`app/Actions/Category/ListCategoriesAction.php`**
```php
<?php

declare(strict_types=1);

namespace App\Actions\Category;

use App\Models\Category;
use Illuminate\Database\Eloquent\Collection;

final class ListCategoriesAction
{
    public function handle(): Collection
    {
        return Category::with('parent')->latest()->get();
    }
}
```

**`app/Actions/Category/CreateCategoryAction.php`**
```php
<?php

declare(strict_types=1);

namespace App\Actions\Category;

use App\Models\Category;

final class CreateCategoryAction
{
    public function handle(array $data): Category
    {
        return Category::create($data);
    }
}
```

No `DB::transaction()` here — a single `create()` call has nothing to roll back partway through. Compare with an Action that creates a category *and* attaches tags: that one does need the wrapper, since a failure after the create but before the `sync()` would leave an orphaned category.

**`app/Actions/Category/UpdateCategoryAction.php`**
```php
<?php

declare(strict_types=1);

namespace App\Actions\Category;

use App\Models\Category;

final class UpdateCategoryAction
{
    public function handle(Category $category, array $data): Category
    {
        $category->update($data);

        return $category;
    }
}
```

**`app/Actions/Category/DeleteCategoryAction.php`**
```php
<?php

declare(strict_types=1);

namespace App\Actions\Category;

use App\Models\Category;

final class DeleteCategoryAction
{
    public function handle(Category $category): void
    {
        $category->delete();
    }
}
```

**`app/Http/Controllers/CategoryController.php`**
```php
<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Actions\Category\CreateCategoryAction;
use App\Actions\Category\DeleteCategoryAction;
use App\Actions\Category\ListCategoriesAction;
use App\Actions\Category\UpdateCategoryAction;
use App\Http\Requests\CategoryStoreRequest;
use App\Http\Requests\CategoryUpdateRequest;
use App\Models\Category;
use Illuminate\Http\RedirectResponse;
use Inertia\Inertia;
use Inertia\Response;

class CategoryController extends Controller
{
    public function index(ListCategoriesAction $action): Response
    {
        return Inertia::render('categories/index', [
            'categories' => $action->handle(),
        ]);
    }

    public function store(CategoryStoreRequest $request, CreateCategoryAction $action): RedirectResponse
    {
        $action->handle($request->validated());

        return to_route('categories.index');
    }

    public function update(CategoryUpdateRequest $request, Category $category, UpdateCategoryAction $action): RedirectResponse
    {
        $action->handle($category, $request->validated());

        return to_route('categories.index');
    }

    public function destroy(Category $category, DeleteCategoryAction $action): RedirectResponse
    {
        $action->handle($category);

        return to_route('categories.index');
    }
}
```

Laravel's container autowires the Action as a method-injected parameter (same mechanism that injects the `FormRequest` and route-bound `Category`), so there's no extra `app()->make()` ceremony needed in the controller.

Note what *didn't* change: the route signatures, the Inertia page names, the FormRequest classes. The refactor is additive — it moves logic, it doesn't change behavior — which is exactly why it's safe to do opportunistically whenever you're already touching a controller.
