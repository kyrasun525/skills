# Read-Only Investigation Rules

These rules are mandatory for every use of this skill.

## Allowed

- Read logs.
- Search code with `rg`, `grep`, and `find`.
- View route, controller, view, service, model, repository, middleware, serializer, schema, config-reader, and client code.
- Analyze call chains.
- Use read-only shell pipelines that only print results.
- Summarize evidence and rank likely causes.

## Forbidden

- Modify code.
- Modify configuration.
- Create, delete, move, copy, or rename files.
- Run `rm`, `mv`, or `cp`.
- Run `sed -i`.
- Run database write operations.
- Run `migrate` or schema-changing commands.
- Run cache clear, queue restart, service restart, deployment, or any command that changes system state.
- Output repair code or implementation patches.

## Command Safety Policy

Allowed command patterns include:
- `rg ...`
- `grep ...`
- `find ...`
- `ls ...`
- `cat ...`
- `sed -n ...`
- `head ...`
- `tail ...`
- `awk ...`
- `sort ...`
- `uniq ...`

Do not run commands with in-place edits, destructive flags, or write redirection into project files.

## Scope Rules

Always exclude these directories from search when possible:
- `vendor`
- `node_modules`
- `.git`
- `__pycache__`
- `venv`

Prefer repository-local evidence in this order:
1. logs
2. route definitions
3. entry handlers
4. service code
5. model or repository code
6. config readers and external client wrappers

## Reporting Rules

- Diagnose only.
- Do not prescribe a code fix.
- Every likely cause must point to a concrete file and symbol or line context.
- State uncertainty explicitly when evidence is incomplete.
- Keep verification suggestions read-only.
