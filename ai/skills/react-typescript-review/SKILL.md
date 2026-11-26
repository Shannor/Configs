---
name: react-typescript-review
description: >
  Review React, TypeScript, and React Router (SSR/SPA) code and pull requests for component
  composability, thin React Context providers, clean data flow, OpenAPI contract fidelity,
  readability, and bundle/module hygiene. Flags prop drilling where `children` / slots belong,
  bloated "God Context" providers with inline fetchers/effects/unmemoized values, nested ternaries,
  oversized inline derivations in components/loaders/actions, `.map()` side-effect mutations and
  repeated `.filter()` passes, duplicate hand-rolled DTOs or re-mapping over generated backend
  types, magic numbers, default exports, `~/.server` boundary leaks, and dev-mock leaks into
  production bundles. Use whenever reviewing `.ts` or `.tsx` code, auditing frontend
  components/contexts/routes/actions, or running `pr-review` on a TypeScript/React repository.
---

# Idiomatic & Composable React / TypeScript Review Skill

Review React and TypeScript code with the mindset of an experienced UI & full-stack frontend engineer. Prioritize **component composability (`children` over prop drilling)**, **thin, memoized Context providers backed by focused hooks**, **flat, readable control flow**, **thin route/action orchestrators backed by pure standalone functions**, and **strict fidelity to generated backend/OpenAPI contracts**.

---

## Core Review Pillars

### 1. Component Composition Over Prop Drilling (`children` & Slots)

- **Anti-pattern (Pass-through Prop Drilling)**: A parent layout/card/bar component accepts 3–7 props (`session`, `otherActiveSession`, `bulkOutcome`, `results`, `memberNames`, `onDismiss`, etc.) that it **never uses itself**, solely to forward them to a rendered child component (`<MemberSessionStatus />`, `<BulkStartResultsSummary />`), or duplicates state-resolution logic already computed by the caller just to feed that child.
- **Our Standard**: Accept `children?: ReactNode` (or a small named `ReactNode` slot when a component genuinely has two independent regions) and let the parent route/container compose the child directly:
  ```tsx
  // Bad: Card bloats to 10 props just to drill 6 of them into MemberSessionStatus
  <FireteamMemberCard
    member={member}
    activeSessions={activeSessions}
    bulkOutcome={bulkOutcome}
    otherActiveSession={otherActive}
  />

  // Good: Card owns card layout & picker; caller composes status via children
  <FireteamMemberCard member={member} characterId={savedCharId}>
    <MemberSessionStatus
      session={selectedSession}
      bulkOutcome={bulkOutcome}
      userId={memberKey}
      characterId={effectiveCharId}
    />
  </FireteamMemberCard>
  ```
- **No JSX Variables or Section-Divider Comments**:
  - Never store large chunks of JSX in local variables (`const metaTags = (<>...</>)`) inside a component or separate inline JSX sections with `{/* Header section */}` comments. Extract small, named, composable subcomponents instead.
  - Never nest visual cards inside of cards.

---

### 2. Flat Control Flow — No Nested Ternaries

- **Anti-pattern**: Multi-branch nested ternaries (`a ? b : c ? d : e`) in variable assignments, object literals, `cn(...)` class expressions, or inline JSX — or ternaries whose `else` branch re-checks part of the `if` condition (`{!isActive && canSelect ? <Toggle /> : !isActive && <Icon />}`).
- **Our Standard**: Extract a small pure helper function with flat early `if (...) return ...` statements for values/strings/classes, or a dedicated subcomponent with early returns for multi-state UI:
  ```ts
  // Bad: 4-level nested ternary inside component body
  const statusText =
    readyCount === 0
      ? 'All teammates are actively tracking a session.'
      : selectedCount === 0
        ? 'Select at least one inactive teammate below to start.'
        : activeCount > 0
          ? `${selectedCount} selected · ${activeCount} already tracking`
          : `${selectedCount} ready to start`;

  // Good: Flat early returns in a named pure helper
  export function getFireteamBarStatusText({
    readyCount,
    selectedCount,
    activeCount,
  }: FireteamBarCounts): string {
    if (readyCount === 0) return 'All teammates are actively tracking a session.';
    if (selectedCount === 0) return 'Select at least one inactive teammate below to start.';
    if (activeCount > 0) return `${selectedCount} selected · ${activeCount} already tracking`;
    return `${selectedCount} ${selectedCount === 1 ? 'teammate' : 'teammates'} ready to start`;
  }
  ```

---

### 3. Thin Components, Loaders & Actions (Extract Standalone Functions)

Route components, `loader`s, and `action`s should read as clean orchestrators — not 200+ line monoliths mixing transformation pipelines, cookie plumbing, and JSX.

- **Extract View-Model Derivations**: Any inline `.map()` / `.reduce()` derivation exceeding ~10–15 lines inside a component or `loader` belongs in a standalone pure function (e.g., `buildFireteamViewModel(...)` in `app/lib/`) with direct unit tests.
- **Extract Inline JSX State Updaters**: Never embed multi-branch `setState((prev) => { ... })` logic directly inside `.map()` JSX props (`onCharacterSelect={(next) => { ... 13 lines ... }}`). Extract named handler functions (`handleCharacterSelect`) or a focused custom hook.
- **Deduplicate Server/Action Side Effects**: Flag repeated blocks across branches in `loader` / `action` handlers (such as reading, merging, and serializing preference cookies in two places) and extract a single helper (`saveFireteamMemberPreferences(request, members)`).

---

### 4. Thin React Context Providers (Extract Hooks, Memoize Values & Split Concerns)

Refactoring bloat out of a route component by dumping 150–250+ lines of fetchers, refs, `useEffect` lifecycles, `FormData` builders, and multi-state updaters into a `*-context.tsx` file just relocates the monolith into a "God Provider".

- **Providers Should Be Thin Wiring Layers (~15–30 lines)**:
  - **Anti-pattern**: `SomeProvider` directly owns `useFetcher`, `previousFetcherState` refs, toast side-effect `useEffect`s, `FormData` construction, draft/selection `useState` maps, and view-model computation inline.
  - **Our Standard**: Extract cohesive state machines into focused custom hooks (`useFireteamBulkStart`, `useFireteamSelection`) and pure helpers (`buildBulkStartFormData`) that can be unit-tested directly with `renderHook`. Let the provider compose those hooks and pass their outputs into `<Context.Provider>`.
- **Keep Provider Action Signatures Minimal & Prune Stale Drafts**:
  - **Anti-pattern**: Exposing `selectMemberCharacter(memberKey, savedCharId, nextCharId)` where child callers must pass `savedCharId` back into the provider even though the provider already owns `savedCharacters` — or keeping stale `draftCharacters` entries after loader revalidation updates the underlying saved state.
  - **Fix**: Resolve internal state inside the hook (`const savedCharId = savedCharacters[memberKey]`) so callers only pass `(memberKey, nextCharId)`, and prune stale client overrides when loader props revalidate.
- **Memoize View Models, Callbacks & Provider `value`s**:
  - **Anti-pattern**: Computing `const viewModel = buildViewModel(...)` on every render and passing an unmemoized object literal `<Context.Provider value={{ ...viewModel, toggleX, submitY }}>` alongside unrelated local state (e.g., `trackComp`). Flipping a single boolean toggle recomputes the entire view model and forces every consumer subtree to re-render.
  - **Fix**: Wrap non-trivial derivations in `useMemo`, stabilize action callbacks with `useCallback` (or stable dispatchers), memoize the provider `value` with `useMemo`, and split high-frequency/orthogonal state into its own context when needed.
- **One Context Responsibility Per File**:
  - Do not bundle a feature-wide container context (`FireteamContext`) and a per-item/card row context (`FireteamMemberContext`) in the same file. Split item-scoped providers into their own module (`fireteam-member-context.tsx`).

---

### 5. Pure Single-Pass Data Builders & Key-Matching Correctness

- **No Side-Effect Mutations Inside `.map()`**:
  - **Anti-pattern**: Mutating an outer dictionary or array inside a `.map()` callback (`const names = {}; const views = items.map((m) => { names[m.id] = m.name; return ...; })`).
  - **Fix**: Return a structured result `{ views, names, counts }` from a pure single-pass builder function.
- **Avoid Redundant Multi-Pass Scans & `O(n * m)` Loop Lookups**:
  - **Anti-pattern**: Running `.map()` to build `views`, followed immediately by 4–5 separate `views.filter(...)` passes (`selectedTargets`, `readyCount`, `activeCount`, etc.), or calling linear `.find()` / `.filter()` over `results` inside `members.map(...)` (`O(n * m)`).
  - **Fix**: Index secondary collections into a `Map` / `Set` upfront (`O(n + m)`) and accumulate sibling counts/targets in a single pass inside the pure builder function.
- **Strict Composite-Key Matching (No Silent Cross-Entity Fallbacks)**:
  - **Trap**: Filtering by `userId` and then doing `if (characterId) { const exact = matching.find(...); if (exact) return exact; } return matching[0];` — when `characterId` *is* supplied and doesn't match, falling through to `matching[0]` misattributes another character's/sub-entity's state!
  - **Rule**: When a specific sub-key (`characterId`, `itemId`, etc.) is provided, return `undefined` if that sub-key has no match rather than falling back to an unrelated sibling record.

---

### 6. Trust Generated Backend / OpenAPI Contracts (No Redundant DTO Re-Mapping or Type Aliases)

- **Anti-pattern**:
  1. Hand-rolling custom frontend interfaces (`BulkFireteamSessionResult`) that duplicate types already generated from OpenAPI (`FireteamSessionResult` in `~/api/types.gen.ts`), or exporting zero-value pass-through aliases (`export type SessionData = MemberSessionData;`).
  2. Manually re-mapping every field of a backend SDK response inside an `action` or `loader` (`responseData.results.map((item) => ({ userId: item.userId, session: { id: item.session.id, ... } }))`) when no domain transformation is occurring.
- **Why It Hurts**: Field-by-field re-mapping adds maintenance noise, **silently strips fields** omitted from the manual mapper (`description`, `summary`, `startedBy`), and drifts whenever the backend OpenAPI schema evolves. Note that generated OpenAPI response transformers already hydrate `Date`s, and React Router v7's `turbo-stream` transport natively serializes `Date`, `BigInt`, `Map`, and `Set` across server/client boundaries.
- **Our Standard**: Import and return generated `~/api` (or canonical domain) types directly unless narrowing/combining distinct endpoints into a genuinely different UI view model.

---

### 7. No Magic Numbers

- **Anti-pattern**: Bare numeric literals in validation conditions, slicing/pagination bounds, timeouts, or inline millisecond arithmetic (`if (members.length > 12)`, `new Date(now - (index + 1) * 9 * 60 * 1000)`, `86400 * 30`).
- **Our Standard**: Define self-documenting `UPPER_SNAKE_CASE` constants (`const MAX_FIRETEAM_SESSION_TARGETS = 12`) at module scope (or shared constants) and prefer standard date/time helpers (`subMinutes` from `date-fns`) over raw `60 * 1000` multiplication chains.

---

### 8. Named Exports Only, Module Boundaries & Bundle Hygiene

- **Named Exports Everywhere**:
  - Export all components, hooks, utilities, and types via **named exports** (`export function FireteamMemberCard(...)`).
  - In framework route modules that require a `default` export (e.g., React Router routes), declare `export function RouteName(...)` as a named export so tests and callers use named imports, and place `export default RouteName;` at the bottom solely to satisfy the framework's route loader.
- **Respect `~/.server/*` Client/Server Boundaries**:
  - Never import from `~/.server/*` (even `import type`) inside `app/components/*` or client-side hooks. Move shared string-union or contract types into `app/lib/*` or `~/api` so UI components remain cleanly decoupled from server-only modules.
- **Keep Dev Mocks Out of Production Bundles & Request Paths**:
  - **Client Bundle Leak**: Rendering dev-only UI behind a runtime `loaderData` value (`{devMockScenario && <DevMockBanner />}`) prevents Vite/Rollup from tree-shaking `DevMockBanner` and its fixture constants out of the production client JS bundle. Always include a static `import.meta.env.DEV` guard (`{import.meta.env.DEV && devMockScenario && <DevMockBanner />}`).
  - **Handler Hygiene**: Avoid weaving `?mock=` / `mockScenario` branches into production `loader` and `action` handlers (especially before `getAuth(request)` checks) when unit/route tests or isolated non-production routes (`process.env.NODE_ENV !== 'production'` in `routes.ts`) can cover previewing without polluting production paths.

---

## Review Severity Calibration

- **[Blocking]**:
  - Wrong-entity state attribution bugs (e.g., falling back to `matching[0]` when an explicit sub-key doesn't match), stale client state overriding fresh loader revalidation, broken auth/validation boundaries, or unintentional production exposure of dev bypass paths.
  - Unbounded `O(n^2)` loops or N+1 per-item network fetches in loaders/components.
- **[Suggestion]**:
  - Pass-through prop drilling where `children` / slot composition simplifies the parent component.
  - Bloated Context providers mixing inline `useFetcher`/toast `useEffect`s/`FormData`/selection state instead of delegating to focused custom hooks, unmemoized provider `value`s/derivations causing unnecessary subtree re-renders, or bundling multiple contexts in a single file.
  - Nested ternaries in logic or JSX instead of flat helper functions / subcomponents.
  - Oversized inline derivations, `.map()` side-effect mutations, 4+ chained `.filter()` passes, or duplicated cookie/persistence blocks in components, loaders, or actions.
  - Duplicate hand-rolled DTO types or field-by-field re-mapping of OpenAPI-generated backend responses.
  - `~/.server/*` imports inside `app/components/*`, magic numbers in validation or business logic, missing named exports on route/UI components, or dev-only UI missing `import.meta.env.DEV` tree-shaking guards.
- **[Nit / Question]**:
  - Redundant pass-through type aliases, minor helper naming, magic numbers in dev-only fixture files, or small styling/breakpoint polish.
