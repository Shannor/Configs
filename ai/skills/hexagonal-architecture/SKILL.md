---
name: hexagonal-architecture
description: >
  Design, implement, and review backend applications using Pragmatic Hexagonal Architecture
  (Ports & Adapters). Emphasizes powerful Application Services owning orchestration, plain
  value-semantic Domain Models (no Java DDD rich-entity ceremony), consumer-defined Driven Ports
  (repositories & external gateways), thin Driving Adapters (HTTP/OpenAPI, CLI, cron) with
  explicit DTO converters, and incremental Boy-Scout adoption on existing codebases. Use when
  designing services, implementing backend tickets, refactoring boundaries, or running `pr-review`.
---

# Pragmatic Hexagonal Architecture (Ports & Adapters) Skill

Structure backend services around **Hexagonal Architecture (Ports & Adapters)** with a pragmatic, service-centric philosophy: **powerful Application Services** own use-case orchestration while **plain, value-semantic Domain Models** keep core logic decoupled from HTTP transport schemas, third-party vendor SDKs, and database drivers.

---

## 1. The Dependency Rule (Outside -> Inside)

Dependencies point **strictly inward** toward the Application & Domain Core:

```text
[ Driving Adapters ]  --->  [ Application Services + Domain Models ]  <---  [ Driven Adapters ]
 (HTTP / OpenAPI,            (Use-case orchestration, invariants,            (Firestore / SQL stores,
  Cron / Ticks, CLI)          domain errors, consumer-defined ports)          Vendor REST gateways, Caches)
```

- **Inside the Hexagon (Core)**:
  - Zero imports of generated HTTP/OpenAPI server DTOs (`api`), web frameworks (`gin`, `hono`, `express`), database SDKs (`firestore`, `gorm`, `sqlx`), or upstream vendor client types (`bungie`, `stripe`, etc.).
- **Outside the Hexagon (Adapters & Composition Root)**:
  - Adapters import the Core to call Driving Ports or implement Driven Ports, translating external wire/persistence formats into pure domain types at the boundary.

---

## 2. Inside the Hexagon: Powerful Services + Plain Domain Models

Avoid Java/C# DDD ceremony (anemic service wrappers around heavily encapsulated "Rich Entities" with private fields, getters/setters, and state-machine boilerplate). Instead:

1. **Application Services Own Orchestration**:
   - Services implement real business workflows: coordinating driven ports (stores, external gateways), enforcing authorization/ownership rules, deduplicating/merging records, and handling partial failures.
   - Keep service constructors pure: accept **driven port interfaces** and plain config values (`NewService(store, gateway)`), never raw infrastructure clients (`*firestore.Client`, `*sql.DB`, `*http.Client`).

2. **Domain Models Are Plain, Value-Semantic Types**:
   - Define clean domain structs without transport or persistence tags (`json:"..."`, `firestore:"..."`, `db:"..."`) and without nullable pointer soup (`*string`, `*float64`) forced by OpenAPI/PATCH schemas.
   - Make zero values useful and prefer values (`[]Item`, `StatsSummary`) over pointers (`[]*Item`, `*StatsValuePair`) unless `nil` carries genuine domain meaning.
   - Attach **pure functions or value-receiver methods** to domain types *only* for cohesive, self-contained domain invariants (e.g., deterministic loadout hashing, canonical identity keys, KD/stat math, merge compatibility, orphan checks)—never I/O.

3. **Domain Errors Live in the Core**:
   - Define sentinel or typed domain errors (`ErrNotFound`, `ErrUnauthorized`, `ErrConflict`, `ErrValidation`) in the core package.
   - Never return HTTP status codes or raw driver errors (`grpc/codes.NotFound`, `sql.ErrNoRows`) across port boundaries.

---

## 3. Ports: Narrow & Consumer-Defined

1. **Driven (Outbound) Ports (Repositories & Gateways)**:
   - Declare small interfaces (typically 1–6 methods) **inside the consuming service package** representing what that service needs from persistence or external APIs (`sessionStore`, `compRankGateway`, `manifestLookup`).
   - Speak **domain types and scalars** across port methods:
     - **Good**: `Save(ctx context.Context, snap Snapshot) (Snapshot, error)`, `UpdateLoadout(ctx context.Context, id string, loadout Loadout) error`
     - **Bad (Leaky Port)**: `Update(ctx context.Context, id string, fn func(map[string]any) error) error` or passing `[]firestore.Update` / vendor `*bungie.DestinyItem` across a port.

2. **Cross-Service Collaboration Without Mega-Interfaces**:
   - Do **not** couple Service A to Service B's 15-method producer `Service` interface when Service A only needs 1–2 read/lookup operations.
   - Define a narrow consumer port in Service A (e.g., `type membershipResolver interface { GetPrimaryMembership(ctx context.Context, userID string) (Membership, error) }`) satisfied naturally by Service B (or an adapter) and wired in `main`.
   - When an operation coordinates multiple peer domains at the top level, orchestrate in a dedicated use-case service rather than creating circular service dependencies or stuffing orchestration into HTTP handlers.

3. **Driving (Inbound) Ports**:
   - Expose clear use-case methods on the Application Service accepting `ctx context.Context` and domain command/query structs or scalars. Driving adapters (HTTP handlers) may define consumer-side interfaces for handler unit testing or call concrete Application Services directly.

---

## 4. Outside the Hexagon: Thin Adapters & Explicit Converters

### Driving (Inbound) Adapters (HTTP / OpenAPI, Cron, CLI)
- **Responsibilities (and nothing more)**:
  1. Parse/validate transport framing and extract actor identity + request observability fields.
  2. Convert transport request DTOs (`api.*`) -> domain inputs via explicit converter functions.
  3. Call **one** Application Service use-case method.
  4. Map domain sentinel/typed errors -> transport responses (`errors.Is(err, domain.ErrNotFound)` -> `404`, `ErrUnauthorized` -> `401`/`403`, `ErrValidation` -> `400`).
  5. Convert domain outputs -> transport response DTOs (`api.*`).
- **Anti-patterns to flag**:
  - Business loops, cross-entity cleanup rules, or raw map mutations (`data["field"] = ...`) inside HTTP handlers.
  - Monolithic "god handler" files mixing transport plumbing with domain algorithms—split handlers by domain resource and move converters into `converter/` or focused `converters.go` files.

### Driven (Outbound) Adapters (DB Stores & External Gateways)
- **Persistence Adapters (Firestore / SQL)**:
  - Own persistence document/row structs (`sessionDoc` with `firestore:"..."` / `db:"..."` tags) when persistence layout differs from or would pollute domain structs, converting cleanly to/from domain models.
  - Translate DB not-found/conflict codes (`codes.NotFound`, `sql.ErrNoRows`) into domain sentinel errors (`ErrNotFound`).
  - Respect collection/table ownership: avoid having unrelated services query or mutate another domain's collection directly when a port/store owns those invariants.
- **External API Gateways (e.g., Bungie, Stripe, OAuth)**:
  - Confine generated vendor client types (`bungie.*`) strictly inside the gateway adapter; convert responses into domain types before returning from the port.

### Composition Root (`main.go` / `cmd/*`)
- Initialize DB clients, HTTP clients, caches, and environment config once in `main`.
- Instantiate driven adapters (`firestore.NewSessionStore(db)`, `bungie.NewGateway(client)`), inject them into Application Services (`session.NewService(sessionStore, ...)`), and inject Application Services into HTTP/cron driving adapters.

---

## 5. Testing Across the Hexagon

- **Application Service & Domain Unit Tests (Default, Fast)**:
  - Test business rules, edge cases, and error paths against lightweight in-memory fakes/stubs of the consumer-defined driven ports—no DB emulator or network required.
- **Driven Adapter Integration Tests**:
  - Test Firestore/SQL stores against the local emulator or Testcontainers to verify query filters, composite indexes, document serialization, and `ErrNotFound` translation.
- **Driving Adapter (Handler) Tests**:
  - Test HTTP status mapping, auth headers, and OpenAPI DTO conversions using stubbed Application Services.

---

## 6. Incremental / Boy-Scout Migration (Existing Codebases)

Many real-world projects are in transition from a traditional `API -> Service -> DB` split (where `api.*` DTOs or raw DB clients leaked into `services/*`) toward Hexagonal Architecture. Apply pragmatic **Boy-Scout rules** rather than demanding disruptive big-bang rewrites:

1. **New Packages, Endpoints & Features (Strict Hexagonal)**:
   - New domain features must introduce clean domain types, consumer-defined driven ports, explicit HTTP/DB converters, and constructor injection from `main`.
2. **Touched Slices in Legacy Packages (Incremental Improvement)**:
   - Do **not** introduce *new* `api.*` DTOs, vendor SDK structs, `map[string]any` callbacks, or direct `*firestore.Client` / `*sql.DB` calls into Application Services.
   - When adding or modifying a persistence/external query in a partially migrated service, extract or extend that package's driven `store`/`gateway` port rather than adding more inline DB queries.
   - When touching an HTTP handler that contains business logic, extract the business workflow into the Application Service.
   - Leave untouched legacy methods in the same package alone unless the ticket explicitly scopes a refactor.

---

## Review Severity Calibration

- **[Blocking]**:
  - New business orchestration, loops, or persistence map mutations placed directly inside HTTP handlers.
  - New direct DB driver queries or upstream vendor client calls added inside an Application Service bypassing its driven port, or leaking vendor/driver errors directly to HTTP responses.
  - Circular dependencies or core domain packages importing HTTP handlers/frameworks.
- **[Suggestion]**:
  - Leaking generated HTTP/OpenAPI DTOs (`api.*` with pointer-heavy fields) or vendor structs (`bungie.*`) into new service signatures instead of clean value-semantic domain structs + converters.
  - Service constructors accepting `*firestore.Client` / `*sql.DB` directly instead of accepting the driven `Store` interface from `main`.
  - Depending on a sibling package's 12-method `Service` interface when a 1–2 method consumer port decouples them cleanly.
- **[Nit / Question]**:
  - Naming clarity between domain types, persistence docs (`*Doc`), and transport DTOs, or opportunities to hoist a pure invariant helper onto a domain value type in a follow-up refactor.
