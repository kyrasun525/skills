# Output Format

Use the following structure for every investigation result.

## Required Sections

### 1. Interface Information

Include:
- API path
- HTTP method
- interface name if available
- symptom summary

### 2. Log Evidence

Include:
- log file path
- matched keywords
- short relevant snippets
- note if no direct log evidence was found

### 3. Entry Localization

Include:
- route file
- controller / view / handler location
- framework guess if relevant
- Top 3 entry candidates if unique localization is not possible

### 4. Call-Chain Candidates

Include:
- route to controller/view
- controller/view to service
- service to model/repository/client
- Top 3 call-chain candidates if ambiguity remains

### 5. Most Likely Causes (Top 1 to Top 3)

For each cause include:
- cause title
- cause summary
- exact code location
- why it is likely

### 6. Problem Code Locations

List all key files and symbols tied to the diagnosis.

### 7. Reasoning Basis

Explain the judgment basis with explicit evidence:
- route match
- log message
- validation branch
- permission branch
- query branch
- external dependency marker
- config read

### 8. Confidence

State `High`, `Medium`, or `Low` for each cause.

### 9. Verification Steps

Provide read-only verification only.

Allowed examples:
- inspect nearby route declarations
- inspect serializer or schema fields
- inspect auth or permission branch
- inspect ORM filter conditions
- inspect external client error handling
- compare timestamps with log snippets

Forbidden examples:
- edit code
- edit config
- rerun migration
- write to database
- clear cache

### 10. Conclusion

Summarize:
- the strongest current conclusion
- what remains uncertain
- what should be verified next in read-only mode

## Quality Rules

- Every cause must have a code location.
- Do not use vague statements like `probably a bug in business logic` without evidence.
- If information is insufficient, say so explicitly.
- If route or entry is ambiguous, output Top 3 candidates.
- If no logs are found, say `No direct log evidence found` and rely on code evidence.
- Do not include repair patches, implementation steps, or configuration changes.
