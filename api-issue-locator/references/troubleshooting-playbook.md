# Troubleshooting Playbook

Use this playbook to rank likely causes after collecting logs, route matches, and call-chain evidence.

## General Ranking Rules

1. Prefer causes backed by both logs and code matches.
2. Prefer causes close to the API entry when the symptom is request rejection (`400`, `401`, `403`, `404`).
3. Prefer causes deeper in service or model layers when the symptom is empty data, inconsistent data, persistence gaps, or downstream failures.
4. Reduce confidence when route identification is ambiguous, logs are missing, or multiple handlers match the same path.
5. If evidence is sparse, return Top 3 possibilities instead of overcommitting.

## Symptom Mapping

### 400 Parameter Error

Common cause buckets:
- Request field name mismatch
- Required parameter absent
- DTO / serializer / schema validation failure
- Type conversion failure
- Method mismatch causing unexpected parser branch

Inspection focus:
- Request parsers and validators
- DTOs, serializers, Pydantic models, request classes
- Parameter extraction logic
- Query string vs body vs form source mismatch

Evidence examples:
- Validation exception in logs
- `request.args` or `request.json` mismatch with documented request
- `BaseModel` or serializer required field missing

### 401 Unauthenticated

Common cause buckets:
- Missing token or cookie parsing
- Authentication middleware rejection
- Token decoding failure
- Wrong auth header name or prefix

Inspection focus:
- Middleware, guards, permission classes, auth backends
- Header extraction code
- Settings or security config reads

Evidence examples:
- `Unauthorized`, `invalid token`, `missing authorization`
- Auth decorator or guard around the route

### 403 Permission Problem

Common cause buckets:
- Permission class or guard denial
- Role mismatch
- Tenant or ownership filter mismatch
- Feature flag or config gate

Inspection focus:
- Permission classes
- Guards / middleware
- Resource ownership checks
- Settings or ACL sources

Evidence examples:
- Explicit `forbidden` logs
- `permission_classes` or guard branches denying access

### 404 Route Problem

Common cause buckets:
- Path mismatch
- HTTP method mismatch
- Prefix mismatch from router, Blueprint, or module mount
- Versioned route mismatch
- Nested group prefix not accounted for

Inspection focus:
- Route declaration files
- Global prefixes
- Router registration
- Blueprints, Nest modules, Spring class-level mappings

Evidence examples:
- Similar route exists with different prefix or method
- Route declaration found but under different mount path

### 500 Exception

Common cause buckets:
- Unhandled null / none / nil access
- Serializer or schema crash
- External dependency error
- Database query exception
- Missing config or bad env read

Inspection focus:
- Stack trace frames
- Service and repository calls
- External client wrappers
- Exception handling blocks that rethrow or swallow context

Evidence examples:
- stack trace lines
- `NullPointerException`, `AttributeError`, `TypeError`, `SQL` exception, timeout markers

### Missing Parameter

Common cause buckets:
- Request source mismatch (`query` vs `json` vs `form`)
- Framework dependency extraction mismatch
- Serializer / DTO field alias mismatch
- Middleware consuming request body incorrectly

### Empty Data

Common cause buckets:
- Query filters too strict
- Tenant / ownership / status filter
- Soft-delete exclusion
- Pagination window issue
- Wrong data source or environment config

Inspection focus:
- ORM filter conditions
- queryset, repository methods, SQLAlchemy query chains
- default scopes and status filters

### Inconsistent Data

Common cause buckets:
- Response shaping mismatch
- Multiple serializers or DTOs for same endpoint
- Different environment config or data source
- Conditional branches by role / feature flag / tenant

### Not Persisted / Not Inserted

Common cause buckets:
- Save branch not reached
- transaction rollback
- async queue path not executed
- external service accepted request but local persistence skipped
- ORM flush/commit branch absent

Inspection focus:
- write path control flow
- service save branches
- repository insert methods
- queue or event dispatch boundaries

Note:
- Diagnose only; do not run write operations to verify.

### Timeout

Common cause buckets:
- External HTTP dependency slow or unavailable
- Slow DB query
- Lock contention symptoms visible in logs
- Missing timeout override or retry storm

Inspection focus:
- external client wrappers
- repository queries
- async wait points
- timeout config reads

### External Dependency Exception

Common cause buckets:
- Third-party API error
- message queue unavailable
- cache service unavailable
- DNS or network failure
- downstream response contract change

Inspection focus:
- client adapters
- integration service classes
- error handling and fallbacks

### Configuration Problem

Common cause buckets:
- Missing env variable
- incorrect settings key
- route prefix config mismatch
- auth or DB config mismatch by environment

Inspection focus:
- `settings.py`, `.env` readers, config loaders, Spring properties access, Laravel config calls
- feature gates and environment branches

## Confidence Guide

- High: logs and code location strongly agree; entry point is clear; symptom directly matches the found branch or exception.
- Medium: route and downstream code are likely matches, but logs are partial or multiple branches remain possible.
- Low: evidence is indirect, route is ambiguous, or the issue could originate from multiple layers.

## Output Rule

For each likely cause, always provide:
- concrete code location
- evidence summary
- reason the symptom matches
- confidence
- read-only verification suggestion
