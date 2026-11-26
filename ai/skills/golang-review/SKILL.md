---
name: golang-review
description: >
  Review Go (Golang) code and pull requests for idiomatic Go style, memory/Garbage Collector
  efficiency, pointer discipline, and algorithmic performance. Flags Java/TypeScript patterns
  translated into Go, unnecessary pointer usage and heap escapes (`[]*T` vs `[]T`, `*string`),
  GC allocation churn, and O(n^2) or N+1 complexity traps. Use whenever reviewing Go code,
  auditing Go services/packages, or running `pr-review` on a repository containing `.go` files.
---

# Idiomatic & Performance-Conscious Go Review Skill

Review Go code with the mindset of an experienced Go systems engineer. Prioritize **idiomatic Go simplicity**, **low Garbage Collector (GC) pressure through value semantics**, and **linear algorithmic scaling** over patterns imported from Java or TypeScript.

---

## Core Review Pillars

### 1. Idiomatic Go — Not Java or TypeScript in Go Syntax

Watch for habits carried over from OOP-heavy Java or functional/dynamic TypeScript codebases and guide them toward idiomatic Go:

- **Consumer-Side Interfaces, Concrete Returns ("Accept interfaces, return structs")**:
  - **Anti-pattern (Java)**: Defining `IUserService` + `UserServiceImpl` in the producer package for every struct, or exporting 15-method interfaces before a second implementation or mock boundary exists.
  - **Idiomatic Go**: Return concrete structs (`*Service` or value types) from constructors (`NewService(...)`). Define small, focused interfaces (1–3 methods) in the **consuming** package where the abstraction is actually needed. Never prefix interfaces with `I` or suffix structs with `Impl`.
- **Plain Data & Composition Over Class Ceremony**:
  - **Anti-pattern (Java)**: Builder classes, Factory hierarchies, Strategy/Visitor boilerplate, or `GetFoo()` / `SetFoo()` accessors on passive data structs.
  - **Idiomatic Go**: Export struct fields directly when no invariants are enforced. If an accessor method is required (e.g., to satisfy an interface), name it `Foo()`, never `GetFoo()`. Prefer plain structs, top-level functions, and struct embedding/composition when behavior genuinely needs sharing.
- **Explicit `for` Loops Over Allocating Functional Chains**:
  - **Anti-pattern (TypeScript)**: Writing generic `Map(...)`, `Filter(...)`, `Reduce(...)` helpers that allocate a brand-new intermediate slice at each pipeline stage, or simulating `Option<T>` / `Result<T>` monads.
  - **Idiomatic Go**: Write a clear single-pass `for` loop (or use non-allocating stdlib `slices` / `maps` helpers). A single loop is easier to step through in a debugger, handles `error` returns naturally, and allocates once.
- **Concrete Types & Useful Zero Values Over TS "Options Bags" & `any`**:
  - **Anti-pattern (TypeScript)**: Passing `map[string]any` / `any` where a typed struct belongs, or making every struct field a pointer (`*string`, `*bool`, `*int`) to mimic TS `field?: string` optional properties.
  - **Idiomatic Go**: Design structs so their zero value (`""`, `0`, `false`, `nil` slice) is immediately valid and meaningful. Reserve pointer primitives for transport/serialization boundaries (e.g., JSON `PATCH` / OpenAPI nullable fields / SQL `NULL`) where distinguishing "unset" from "zero" is strictly required, and convert to values at the boundary.
- **Explicit Error Handling & Package Naming**:
  - Wrap errors with context (`fmt.Errorf("load profile %s: %w", id, err)`) and inspect via `errors.Is` / `errors.As` — never string-match `err.Error()` and never use `panic` for recoverable runtime/request failures.
  - Avoid catch-all packages (`util`, `utils`, `common`, `helpers`, `types`, `models`) and stuttering names (`user.UserConfig` -> `user.Config`).
- **Return Results, Don't Mutate Caller Data (System Architecture Rule)**:
  - **Anti-pattern**: Void helpers (`fillResults(out, ...)`, `populateMap(m, ...)`) or pointer-receiver domain mutators (`func (s *Session) EnableX(...)`) that silently mutate caller-owned slices, maps, or structs in place. In-place mutation hides data flow, couples helpers to caller buffer layouts, and makes side effects harder to reason about and test.
  - **Our Standard**: Every function and domain helper **must return its result** (`results := buildResults(...)`, `ses = ses.WithCompTracking(...)`, `indexed := indexPlayers(base, players...)`) instead of mutating arguments passed in by the caller. Reserve pointer receivers strictly for stateful infrastructure/service/store instances (`*service`, `*Store`), non-copyable sync primitives, or proven benchmarked hot paths.
- **Caller-Controlled Concurrency**:
  - **Anti-pattern (TypeScript `async` everywhere)**: Spawning hidden goroutines or returning channels from ordinary functions when synchronous execution suffices.
  - **Idiomatic Go**: Write synchronous functions by default and let the caller decide whether to run them concurrently. Always pass `ctx context.Context` as the first argument (never stored in a struct), bound concurrency (`errgroup.WithContext`), and guarantee goroutines have an exit path on cancellation.

---

### 2. Garbage Collector (GC) Pressure & Pointer Discipline

Go is **not** Java or TypeScript where every object reference is a pointer by default. Overusing pointers defeats stack allocation, inflates heap object counts, increases GC mark-scan latency, and causes CPU cache misses.

#### Flag Unnecessary Pointers
- **Slices of pointers (`[]*T` vs `[]T`)**:
  - `[]*T` performs **1 + N heap allocations** (the slice header backing array plus an independent heap allocation per element), scatters elements across memory (pointer chasing / L1-L2 cache misses), and forces the GC tri-color mark phase to trace N pointers.
  - `[]T` performs **1 contiguous allocation**, keeps data cache-local, and — if `T` contains no pointers itself — marks the entire backing array `noscan` so the GC skips scanning its elements completely.
  - **Rule**: Default to `[]T` unless `T` is genuinely large (hundreds of bytes, verified by benchmark), elements require shared identity/mutation in place, or `nil` elements carry domain meaning.
- **Pointers to Reference/Header Types (`*[]T`, `*map[K]V`, `*string`, `*chan T`, `*error`, `*MyInterface`)**:
  - `string` (16 bytes), `[]T` (24 bytes), `map`, `chan`, `func`, and `interface` values **already wrap internal pointers** and are cheap to copy by value. Passing `*string` or `*map[K]V` almost always indicates non-idiomatic code (except slice headers mutated outside `return` or JSON nullable primitives at DTO boundaries).
- **Pointers to Small Value Structs & Return-by-Pointer Heap Escapes**:
  - Returning `*SmallStruct` (`return &Point{X: 1, Y: 2}`) routinely forces `Point` to **escape from the stack to the heap**, turning a free stack operation into a heap allocation + future GC sweep. Returning `SmallStruct` by value keeps it on the stack or in CPU registers.
  - Unnecessary pointers also introduce `nil` dereference panics and defensive `if x != nil` noise throughout business logic.

#### When Pointers ARE Appropriate
1. **Mutation / Shared State**: Receivers or arguments that must mutate the caller's instance (`func (s *Store) Save(...)`).
2. **Non-Copyable Types**: Any struct containing `sync.Mutex`, `sync.RWMutex`, `sync.Once`, `sync.WaitGroup`, or `atomic.*` **must** use pointer receivers so locks are never copied by value.
3. **Explicit Tri-State / Nullable Boundaries**: OpenAPI/JSON request/response structs or DB rows where `null` vs `""`/`0`/`false` has distinct protocol semantics.
4. **Large Structs on Hot Paths**: Structs large enough that copying measurably hurts throughput (verify with `go test -bench` and `-gcflags="-m"`, not guesswork) or keeping receiver types consistent when other methods on the struct already require pointer receivers.

#### Reduce Heap Allocation Churn
- **Pre-size slices and maps** whenever length or an upper bound is known:
  ```go
  // Good: 1 allocation instead of ~log2(N) grow+copy allocations
  out := make([]Item, 0, len(rawItems))
  byID := make(map[string]Item, len(rawItems))
  ```
- **Avoid allocations in hot loops**:
  - Prefer `strconv.Itoa` / `strconv.FormatInt` over `fmt.Sprintf("%d", id)`.
  - Avoid repeated `[]byte(s)` / `string(b)` conversions inside loops.
  - Avoid capturing loop variables in closures or boxing concrete values into `any` inside tight loops when avoidable.

---

### 3. Algorithmic Complexity & `O(n^2)` Traps

Treat hidden quadratic (`O(n^2)` or `O(n * m)`) paths as real production risks. Collections that look small in unit tests (10 items) routinely grow to hundreds or thousands of items in real user profiles, inventories, batch jobs, or API responses.

Always scan diffs for these patterns:

1. **Nested Linear Scans / Loop Joins (`O(n * m)`)**:
   - **Trap**: Nested `for` loops matching IDs/keys, or calling `slices.Contains`, `slices.IndexFunc`, or a `find*` helper inside a `for` loop.
   - **Fix**: Build a pre-sized lookup `map[K]V` or `map[K]struct{}` once before the loop (`O(n + m)` time):
     ```go
     // Bad: O(n * m)
     for _, order := range orders {
         for _, user := range users {
             if user.ID == order.UserID { ... }
         }
     }

     // Good: O(n + m) with pre-sized map and zero-size struct{} when set membership suffices
     usersByID := make(map[string]User, len(users))
     for _, u := range users {
         usersByID[u.ID] = u
     }
     for _, order := range orders {
         if u, ok := usersByID[order.UserID]; ok { ... }
     }
     ```
   - *Note*: Only skip map indexing when `m` is provably tiny and bounded by a constant (e.g., `<= 4` fixed enum slots) where linear scan beats map hashing.

2. **String Concatenation Inside Loops (`O(n^2)` Bytes Copied)**:
   - **Trap**: `result += chunk` inside a `for` loop. Because Go strings are immutable, every iteration allocates a new buffer and copies all prior bytes (`1 + 2 + ... + n = O(n^2)`).
   - **Fix**: Use `strings.Builder` (call `b.Grow(estimatedBytes)` when estimable) or `strings.Join(parts, sep)`.

3. **Repeated Slice Element Deletion / Shifting in a Loop (`O(n^2)`)**:
   - **Trap**: `items = append(items[:i], items[i+1:]...)` or `slices.Delete(items, i, i+1)` inside a loop, shifting the tail on every removal.
   - **Fix**: Use `slices.DeleteFunc(items, shouldRemove)` (which compacts in a single `O(n)` pass and zeroes trailing elements to prevent memory leaks) or a single-pass write index.

4. **N+1 I/O, Database, or External API Calls in Loops**:
   - **Trap**: Executing Firestore/SQL reads, RPCs, or HTTP requests per iteration inside a `for` loop.
   - **Fix**: Batch-fetch upfront (`GetAll`, `WHERE id IN (...)`, bulk endpoints) or bound concurrent fetches when batch APIs do not exist, then join in memory via a map.

5. **Repeated Expensive Work Inside Loops**:
   - **Trap**: Calling `regexp.MustCompile(...)`, `slices.SortFunc(...)`, reflection-heavy validators, or `json.Marshal` of invariant data on every loop iteration.
   - **Fix**: Hoist regexes to package-level `var`, sort once after collecting elements (`O(n log n)` instead of `O(n^2 log n)`), and compute loop-invariant structures once outside the loop.

6. **Sub-Slicing Large Backing Arrays (Hidden Memory Retention)**:
   - **Trap**: Returning `hugeSlice[:5]` or `[]byte` sub-slices from a multi-megabyte buffer, pinning the entire backing array in memory so the GC cannot reclaim it.
   - **Fix**: `slices.Clone(hugeSlice[:5])` when retaining a tiny window of a large short-lived buffer.

---

## Verification Commands (When Inspecting Local Code)

When reviewing code in a local checkout or validating a performance/escape concern, back claims with Go's built-in tooling rather than speculation:

- **Escape analysis** (confirm whether values escape to heap):
  ```bash
  go build -gcflags="-m" ./path/to/pkg 2>&1 | grep -E "escapes to heap|moved to heap"
  ```
- **Static analysis & race detection**:
  ```bash
  go vet ./...
  go test -race ./...
  ```
- **Allocation & throughput benchmarks** (when reviewing hot paths):
  ```bash
  go test -bench=. -benchmem ./path/to/pkg
  ```

---

## Review Severity Calibration

Keep review comments constructive, specific, and proportional:

- **[Blocking]**:
  - Unbounded `O(n^2)` loops or N+1 DB/network calls on user, inventory, or batch collections.
  - Nil-pointer dereference risks caused by pointer overuse, data races, goroutine leaks, copied `sync.Mutex`, or swallowed errors.
- **[Suggestion]**:
  - Functions or domain helpers that mutate caller-supplied slices, maps, or structs in place instead of returning new/updated values.
  - Unnecessary `[]*T` or `*SmallStruct` / `*string` usage that increases heap escapes, GC scan cost, or nil-check boilerplate.
  - Missing slice/map pre-allocation (`make(..., 0, len(src))`) on non-trivial transformations.
  - Java/TypeScript patterns (`IFooService` / `FooServiceImpl`, `GetX()` accessors, allocating `Map`/`Filter` helpers, `map[string]any` instead of structs) that hurt clarity or performance.
- **[Nit / Question]**:
  - Minor package/type naming stutter, small stdlib simplifications (`maps.Clone`, `slices.DeleteFunc`, `errors.Join`), or questions about expected upper bounds on collection sizes when a loop looks bounded.
