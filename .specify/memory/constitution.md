# OpenShelf Constitution

OpenShelf is an offline-first, privacy-centric, open-source Flutter application for
organizing a physical book library, built for the DACH (Germany, Austria,
Switzerland) market. It is a derivative fork of Openreads, reoriented around data
sovereignty, metadata accuracy, and reading statistics without telemetry or cloud
lock-in. This Constitution is the highest authority for the project; every
implementation, specification, and review decision MUST conform to it.

## Core Principles

### ARTICLE I: Core Philosophies & Privacy

1. **Offline-First Imperative.** Every primary feature — library management,
   reading tracking, local search, and statistics — MUST function completely
   offline with no internet connectivity. Network access is permitted only for
   explicit, user-initiated actions (e.g., metadata lookup, cover retrieval) and
   MUST never gate a primary feature.
2. **Zero Telemetry & Privacy.** The application MUST NOT include user tracking,
   analytics, third-party telemetry, or mandatory user accounts. Any network call
   MUST be opt-in, transparent, and attributable to a specific user action.
3. **Data Sovereignty.** User data belongs solely to the user. Full, unencrypted
   export and import (CSV, JSON, and SQLite) is MANDATORY. Every change to the
   data structure MUST preserve the ability to export all data in full.

*Rationale:* These three rules are the project's reason to exist. They are
non-negotiable and take precedence over any feature or convenience argument.

### ARTICLE II: Tech Stack & Architecture Boundaries

1. **Framework & Language.** Implementation MUST use Flutter (latest stable
   release) and Dart with strict null-safety. The use of `dynamic` is prohibited
   wherever an explicit, strongly-typed model is possible.
2. **State Management & Persistence.** Code MUST follow a layered architecture
   separating UI, State Management, and Repositories. All database interactions
   MUST be managed strictly through Drift (SQLite); direct ad-hoc SQL outside the
   repository layer is prohibited.
3. **Migration Safety.** Destructive database schema changes (e.g., dropping or
   redefining columns/tables) are STRICTLY PROHIBITED without backward-compatible
   migration scripts and accompanying tests.

### ARTICLE III: Metadata & Data Integrity

1. **Multi-Source Hierarchy.** The metadata pipeline MUST follow this strict
   priority order: Deutsche Nationalbibliothek (DNB) SRU, then Google Books API,
   then Open Library API. Lower-priority sources MUST NOT override data already
   obtained from a higher-priority source.
2. **Deterministic Fallbacks.** Merging remote metadata MUST NEVER overwrite a
   user-edited attribute without explicit, per-attribute user consent.
3. **Local Image Caching.** Cover images retrieved from remote APIs MUST be
   cached locally so the library remains fully browsable offline.

### ARTICLE IV: Code Quality & Engineering Standards

1. **Clean Code & Documentation.** Data models MUST be strongly typed. Sealed
   state classes MUST be consumed with exhaustive pattern matching. Complex domain
   logic (e.g., MARC21 XML parsing) MUST carry inline documentation.
2. **Test Coverage.** Unit tests are REQUIRED for metadata aggregator services,
   database migrations, and rating/statistics calculation engines.
3. **Error Handling.** API handling MUST be defensive: network failures and
   malformed XML/JSON responses MUST fail gracefully and resolve to meaningful
   local fallbacks rather than crashing or corrupting state.

### ARTICLE V: UI/UX & Accessibility

1. **Material Design 3 Consistency.** The UI MUST use native Material Design 3,
   support dark and light themes, and provide responsive layouts for mobile and
   tablet screens.
2. **Uninterrupted Workflows.** Batch operations (e.g., batch scanning, bulk
   location assignment) MUST minimize UI blocking and reduce confirmation modals
   to only those that are strictly necessary.
3. **Accessibility.** Interactive elements MUST meet a minimum tap target of
   48x48 dp, use high-contrast text, and expose all core interactive elements to
   screen readers.

### ARTICLE VI: Spec-Driven Development Workflow

1. **Specification Integrity.** No feature implementation or architectural change
   MAY begin without a valid, reviewed `.spec/spec.md` and its associated
   `tasks.md`.
2. **Task Granularity.** Development tasks MUST be atomic, testable, and directly
   traceable to a specification requirement.

### ARTICLE VII: Licensing & Open-Source Conduct

1. **License Compliance.** The project MUST respect the upstream Openreads
   license (GPLv2). All derivative work and all new modules MUST remain strictly
   open-source under the same license, with no proprietary exceptions.

## Governance

1. **Amendment Procedure.** Changes to this Constitution require a documented,
   reviewed proposal that names the affected Articles, states the rationale, and
   (where relevant) supplies a migration plan. Amendments MUST follow the
   versioning policy below.
2. **Versioning Policy.** `CONSTITUTION_VERSION` follows semantic versioning:
   MAJOR for backward-incompatible removal or redefinition of principles; MINOR
   for new or materially expanded guidance; PATCH for clarifications and
   non-semantic refinements.
3. **Compliance Review.** Every pull request and specification MUST be checked
   against this Constitution. Any deviation MUST be explicitly justified and
   approved before merge; unjustified deviation is grounds for rejection.

**Version**: 1.0.1 | **Ratified**: 2026-10-05 | **Last Amended**: 2026-10-05
