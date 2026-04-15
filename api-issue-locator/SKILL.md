---
name: api-issue-locator
description: Read-only API troubleshooting and issue localization for backend projects. Use when Codex needs to investigate an interface problem from API path, method, name, or symptom description and quickly locate likely causes, code locations, entry points, logs, and call chains without modifying code, configuration, data, or system state.
---

# API Issue Locator

Investigate API issues in read-only mode. Read logs, search routes, locate entry points, trace call chains, and produce evidence-backed hypotheses. Do not repair anything, do not change project files, and do not run commands that mutate the environment.

## Required Operating Mode

- Stay strictly read-only.
- Read, search, and analyze only.
- Never modify project code, configuration, database state, caches, logs, or generated artifacts.
- Never output patch proposals or repair code.
- If a command could change system state, do not run it.
- Load [references/readonly-investigation-rules.md](references/readonly-investigation-rules.md) before investigation.
- Use [references/output-format.md](references/output-format.md) for the final response structure.
- Use [references/troubleshooting-playbook.md](references/troubleshooting-playbook.md) when matching symptoms to likely causes.

## Inputs

Collect these inputs before analysis:

1. API path, method, or interface name.
2. Problem description, symptom, status code, or observed anomaly.
3. Optional context such as request parameters, environment, timestamp, trace id, user id, or sample error text.

If one identifier is missing, continue with what is available. If the API cannot be uniquely identified, return Top 3 entry candidates and Top 3 likely causes.

## Investigation Workflow

### Step 1: Read Logs

Run `scripts/read_logs.sh` first.

Purpose:
- Scan common backend log directories and `*.log` files.
- Extract nearby evidence for `error`, `exception`, `timeout`, `null`, and other issue markers.
- Capture file paths and snippets that may match the symptom.

Usage:

```bash
bash scripts/read_logs.sh "<optional-keyword>"
```

### Step 2: Search the API

Run `scripts/locate_issue.sh` with path, method, name, or other route clues.

Purpose:
- Search route definitions, controller/view handlers, and framework annotations.
- Support Java, PHP, Node.js, and Python frameworks.
- Return candidate files and matching route declarations.

Usage:

```bash
bash scripts/locate_issue.sh "<api clue>" "<optional method>"
```

### Step 3: Locate the Entry Point

Identify the most likely route and request entry.

Look for:
- Route declaration file.
- Controller, view, handler, or endpoint function.
- Middleware, permission, authentication, or validation layers.
- Request parsing and parameter mapping.

Framework hints:

- Java Spring Boot / Spring MVC:
  - Route annotations: `@RequestMapping`, `@GetMapping`, `@PostMapping`, `@PutMapping`, `@DeleteMapping`, `@PatchMapping`
  - Entry files: `Controller`, `RestController`
  - Focus on request DTOs, interceptors, validation, service calls, repository usage

- PHP Laravel / ThinkPHP / native:
  - Route files: `routes/*.php`, `route/*.php`
  - Entry files: controllers, middleware, services, models
  - Focus on request validation, middleware, ORM queries, config lookups

- Node.js NestJS / Express:
  - Route markers: decorators, router methods, `app.use`, `router.get/post/put/delete`
  - Entry files: controllers, modules, middleware, service providers
  - Focus on pipes, guards, interceptors, DTOs, async dependency failures

- Python Django:
  - Route files: `urls.py`
  - Route patterns: `path(`, `re_path(`, router registration
  - Entry files: `views.py`, `APIView`, `ViewSet`, generic views
  - Focus on `serializer`, `permission_classes`, `queryset`, `settings.py`, authentication, filtering, request parsing

- Python Flask:
  - Route markers: `@app.route`, `Blueprint`, `blueprint.route`
  - Request access: `request.args`, `request.json`, `request.form`
  - Focus on Blueprint prefix, SQLAlchemy queries, middleware, before/after request hooks

- Python FastAPI:
  - Route markers: `APIRouter`, `@router.get`, `@router.post`, `@app.get`, `@app.post`
  - Dependency markers: `Depends`
  - Data models: `BaseModel`, Pydantic schemas
  - Focus on parameter mapping, dependency injection, DB session lifecycle, response model shaping

- Python native routing:
  - Search for manual WSGI/ASGI dispatchers, regex routes, path maps, request method branches, lightweight framework wrappers
  - Focus on handler registration, request parsing, config loading, direct DB calls, and exception swallowing

Required Python search keywords:
- `urls.py`
- `path(`
- `APIView`
- `ViewSet`
- `@app.route`
- `Blueprint`
- `APIRouter`
- `Depends`
- `request.args`
- `request.json`
- `BaseModel`
- `settings.py`

### Step 4: Trace the Call Chain

Run `scripts/trace_callchain.sh` using the discovered route, handler, class, or function name.

Purpose:
- Trace likely flow from route to controller/view to service to model or repository.
- Surface candidate cross-file hops.
- Highlight nearby invocations and framework glue code.

Usage:

```bash
bash scripts/trace_callchain.sh "<symbol or file clue>"
```

### Step 5: Build Evidence-Based Hypotheses

Combine logs, route matches, and call-chain candidates with the reported symptom.

Required behavior:
- Produce Top 1 to Top 3 likely causes.
- Bind every cause to one or more concrete code locations.
- State why each cause matches the evidence.
- Assign a confidence level.
- Provide verification suggestions only.
- Do not suggest code edits.

### Step 6: Output the Diagnosis

Use the structure in [references/output-format.md](references/output-format.md).

Minimum required sections:
- Interface information
- Log evidence
- Entry point candidates
- Call-chain candidates
- Top 1 to Top 3 likely causes
- Problem code locations
- Reasoning and evidence
- Confidence
- Verification steps
- Conclusion

### Step 7: Provide Verification Suggestions

Verification must remain read-only where possible.

Examples:
- Re-check the exact route declaration and HTTP method.
- Compare request field names with parser or serializer expectations.
- Re-read the relevant logs around the event timestamp.
- Inspect permission or authentication branches.
- Confirm query filters, tenant scoping, or soft-delete conditions.
- Inspect dependency injection wiring and external client initialization.
- Check environment-specific config reads without changing config.

## Supported Problem Types

Cover at least these issue classes:

- `400` parameter error
- `401` unauthenticated
- `403` permission denied
- `404` route not found
- `500` unhandled exception
- missing parameter
- empty data
- inconsistent data
- not persisted / not inserted
- timeout
- external dependency failure
- configuration issue

## Framework Search Guide

### Java

Search route and handler markers:
- `@RequestMapping`
- `@GetMapping`
- `@PostMapping`
- `@PutMapping`
- `@DeleteMapping`
- `@PatchMapping`
- `@RestController`
- `@Controller`

Search downstream layers:
- `Service`
- `Repository`
- `Mapper`
- `Feign`
- `RestTemplate`
- `WebClient`

### PHP

Search route and handler markers:
- `Route::get`
- `Route::post`
- `Route::put`
- `Route::delete`
- `Route::any`
- `Route::group`
- `->middleware`
- `Route::rule`
- `Route::resource`

Search downstream layers:
- `Controller`
- `Service`
- `Model`
- `Repository`
- `validate`
- `request()->`

### Node.js

Search route and handler markers:
- `@Controller`
- `@Get`
- `@Post`
- `@Put`
- `@Delete`
- `router.get`
- `router.post`
- `app.get`
- `app.post`

Search downstream layers:
- `@Injectable`
- `service`
- `repository`
- `guard`
- `pipe`
- `interceptor`

### Python

Search route and handler markers:
- `urls.py`
- `path(`
- `re_path(`
- `router.register`
- `APIView`
- `ViewSet`
- `@app.route`
- `Blueprint`
- `APIRouter`
- `Depends`
- `@router.get`
- `@router.post`
- `@app.get`
- `@app.post`

Search request and validation markers:
- `request.args`
- `request.json`
- `request.form`
- `BaseModel`
- `serializer`
- `permission_classes`
- `queryset`
- `settings.py`

Search downstream layers:
- `SessionLocal`
- `db.session`
- `objects.filter`
- `objects.get`
- `select_related`
- `prefetch_related`
- `SQLAlchemy`

## Command Policy

Allowed command families:
- `rg`
- `grep`
- `find`
- `ls`
- `cat`
- `sed -n`
- `awk`
- `head`
- `tail`
- `sort`
- `uniq`
- `xargs` for read-only pipelines only

Forbidden actions:
- Any file write or in-place edit
- `rm`, `mv`, `cp`
- `sed -i`
- `chmod` on project files
- database writes
- `migrate`
- cache clear, queue restart, service restart, deployment, or any state-changing command

## Resource Loading Guide

Read only what is needed:
- Load [references/readonly-investigation-rules.md](references/readonly-investigation-rules.md) at the start of investigation.
- Load [references/troubleshooting-playbook.md](references/troubleshooting-playbook.md) when symptom classification or ranking is needed.
- Load [references/output-format.md](references/output-format.md) before producing the final diagnosis.
- Execute scripts in `scripts/` instead of rewriting the same shell logic.

## Script Entry Points

- `scripts/read_logs.sh`: extract issue evidence from logs
- `scripts/locate_issue.sh`: search route definitions and entry candidates
- `scripts/trace_callchain.sh`: trace likely route-to-service-to-model hops
- `scripts/inspect_api.sh`: run logs, search, and call-chain analysis in one read-only flow

## Final Guardrails

Before sending the answer, confirm all of the following:
- Every cause has a code location.
- Every cause includes explicit reasoning.
- Confidence is stated.
- Verification advice is read-only.
- No fix patch, migration, config change, or write action is proposed.
- If evidence is insufficient, say so explicitly and provide Top 3 candidates instead of pretending certainty.
