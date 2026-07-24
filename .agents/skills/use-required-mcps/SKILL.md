---
name: use-required-mcps
description: Mandatory direct execution of MCP tools without unnecessary code modifications or searches. Activates on explicit user request or natural MCP action intents.
---

# Use-Required MCPs

Enforces direct execution of configured Model Context Protocol (MCP) tools for data queries, mutations, and workflows across all connected MCP servers.

---

## 1. Core Rules

1. **Mandatory MCP Tool Usage**:
   - Execute all actions directly through active MCP tools.
   - Do NOT write auxiliary scripts, standalone code, or manual API clients.
2. **No Codebase Modifications**:
   - Do NOT edit or create project code files.
   - *Exception*: Reading or preparing local file bytes/paths is allowed **ONLY** when uploading files via an MCP tool (e.g., media/document upload endpoints).

3. **No Unnecessary Code Searches**:
   - Do not perform wide codebase scans. Reference tool definitions or documentation only when strictly necessary.

4. **Activation Policy**:
   - Activates when the user triggers the skill or requests data/actions managed by connected MCP servers.

5. **Fetch all information**
   - Some tools just return ID, you should use releant other tools to get enough information because users cannot understand ID directly.

6. **Focus on Final Results & Avoid Asking Unnecessary Questions**:
   - Users do not care about what you do behind the scenes, internal tool mechanics, or technical details—they only care about seeing the final results.
   - Users understand their daily workflow context, not tool usage or implementation details.
   - Execute the necessary actions autonomously and show the final result directly.
---

## 2. General Parameter & Query Guidelines

Agents must dynamically discover and adapt to parameter requirements across diverse MCP servers and runtime environments:

### 2.1. Parameter Discovery & Strict Typing
- **Discover Definitions**: Inspect tool definitions and schemas provided by the active runtime (in-memory tool declarations, system prompts, or local references if available).
- **Strict Data Types**: Adhere strictly to declared parameter types:
  - `string`: Text values, identifiers, or serialized JSON strings.
  - `number` / `integer`: Numeric values and numeric IDs (do not pass strings if integers are required).
  - `boolean`: `true` or `false`.
  - `array` / `object`: Structured collections matching the expected schema.
- **Serialized (Stringified) JSON vs. Raw Objects**:
  - If a tool parameter is defined as `type: "string"` for a query filter, configuration, or payload, **pass an escaped JSON string** (`"where": "{\"status\": \"active\"}"`).
  - Do NOT pass unstringified nested JSON objects when a string is expected.

### 2.2. Common Query & Action Patterns
- **Filters & Search**: Use the server's supported query syntax (e.g., query objects, `where` clauses, key-value criteria, or search keywords).
- **Pagination**: Adhere to pagination parameters (`limit`, `page`, `offset`, `cursor`).
- **Sorting**: Follow sorting conventions (e.g., field names, `-` prefix for descending, or explicit order properties).
- **Projection & Expansion**: Use field selection (`select`, `fields`) or relationship expansion (`depth`, `include`, `populate`) when supported.

---

## 3. Server-Specific References

Specific guidelines, query syntaxes, and optional reference files for configured MCP servers:

### 3.1. Payload CMS MCP
- **Documentation**: [Payload CMS Query Overview](https://payloadcms.com/docs/queries/overview)
- **Local Reference Schemas** *(if available)*: `references/payload/<toolName>.json`
- **Common Parameters**:
  - `where`: **JSON String** (escaped) for filtering conditions.
  - `select`: **JSON String** defining fields to return (e.g., `'{"title": true}'`).
  - `sort`: String (`"-createdAt"` for desc, `"date"` for asc).
  - `limit`: Integer (default: 10, max: 100).
  - `page`: Integer for pagination.
  - `depth`: Integer (`0` to `10`) to populate relationships.
  - `id`: Specific document ID.
- **`where` Operators (JSON String)**:
  - Comparison: `equals`, `not_equals`, `greater_than`, `greater_than_equal`, `less_than`, `less_than_equal`
  - Text & Pattern: `contains`, `like`
  - Arrays & Existence: `in`, `not_in`, `exists`
  - Logical Groups: `"and": [...]`, `"or": [...]`
  - *Example*: `"where": "{\"and\": [{\"category\": {\"equals\": 1}}, {\"status\": {\"equals\": \"active\"}}]}"`

### 3.2. Other MCP Servers
*(Additional MCP servers and their specific documentation can be added here as new services are integrated)*

---

## 4. Error Handling & Anti-Loop Protocol (CRITICAL)

If an MCP tool call fails or returns an error:

1. **STOP IMMEDIATELY**:
   - **NEVER** repeatedly call the same tool with identical arguments.

2. **Diagnose Root Cause**:
   - Read the exact error response returned by the server/runtime.
   - Identify schema mismatches: missing required fields, string vs. object formatting, unsupported operators, or type conflicts.

3. **Try an Alternative Approach (At most 1 retry)**:
   - **Fix types & encoding**: Cast string/number types, serialize JSON objects into strings, or correct field names.
   - **Simplify query**: Remove complex filters and query with minimal parameters (e.g., only `limit`, `page`, or `id`), then filter client-side.

4. **Report or Ask**:
   - If the single corrective retry still fails, stop immediately and report the error to the user rather than looping.
