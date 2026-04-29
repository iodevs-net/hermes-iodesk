# Repository Guidelines

Instructions for AI coding assistants and developers working on the hermes-agent codebase.

## Project Overview

Hermes Agent is a self-improving AI agent framework built by Nous Research. It provides a CLI, TUI, and multi-platform messaging gateway around an LLM-driven agent loop with tool calling, memory, skills, delegation, and extensible plugin/backend architecture.

**Version:** 0.11.0 (from pyproject.toml)
**Python:** >=3.11
**License:** MIT

---

## Development Environment

```bash
# Activate virtual environment
source .venv/bin/activate   # or: source venv/bin/activate

# Install extras as needed
pip install -e ".[dev,web,messaging,mcp,pty,acp,all]"
```

`scripts/run_tests.sh` probes `.venv` first, then `venv`, then `$HOME/.hermes/hermes-agent/venv` (for worktrees that share a venv with the main checkout).

---

## Project Structure

```
hermes-agent/
├── run_agent.py              # AIAgent class — core conversation loop (~12k LOC)
├── model_tools.py            # Tool orchestration, discover_builtin_tools(), handle_function_call()
├── toolsets.py               # Toolset definitions, TOOLSETS dict
├── toolset_distributions.py  # Per-platform toolset filtering
├── cli.py                    # HermesCLI class — interactive CLI orchestrator (~11k LOC)
├── batch_runner.py           # Parallel batch processing
├── trajectory_compressor.py  # Trajectory storage and compression
├── hermes_constants.py       # get_hermes_home(), display_hermes_home() — profile-aware paths
├── hermes_state.py           # SessionDB — SQLite session store (FTS5 search)
├── hermes_logging.py         # setup_logging() — agent.log / errors.log / gateway.log (profile-aware)
├── hermes_time.py            # Timezone-aware datetime utilities
├── rl_cli.py                 # RL training CLI (Atropos environments)
├── utils.py                  # Shared utilities (truthy, deep merge, etc.)
├── mcp_serve.py              # Standalone MCP server adapter
│
├── agent/                    # Agent internals (~35 files)
│   ├── transports/           # API transport layer (chat_completions, anthropic, bedrock, codex)
│   ├── anthropic_adapter.py  # Anthropic Messages API adapter
│   ├── bedrock_adapter.py    # AWS Bedrock Converse API adapter
│   ├── gemini_native_adapter.py / gemini_cloudcode_adapter.py / gemini_schema.py
│   ├── codex_responses_adapter.py
│   ├── copilot_acp_client.py
│   ├── google_code_assist.py
│   ├── memory_manager.py     # Memory provider orchestration
│   ├── memory_provider.py    # MemoryProvider ABC
│   ├── context_compressor.py # Default context compression engine
│   ├── context_engine.py     # ContextEngine ABC
│   ├── context_references.py # File reference scanning
│   ├── prompt_builder.py     # System prompt assembly
│   ├── prompt_caching.py     # Anthropic-style cache_control breakpoints
│   ├── credential_pool.py    # Multi-strategy credential selection
│   ├── credential_sources.py # Auto-seed from various config sources
│   ├── display.py            # KawaiiSpinner, activity feed UI
│   ├── file_safety.py        # Path allow/deny lists
│   ├── image_gen_provider.py / image_gen_registry.py  # Image gen plugin system
│   ├── skill_commands.py / skill_preprocessing.py / skill_utils.py
│   ├── title_generator.py    # Session title generation
│   ├── trajectory.py         # Run trajectory persistence
│   ├── model_metadata.py     # Model context length, pricing, features
│   ├── models_dev.py         # Provider model catalogs
│   ├── rate_limit_tracker.py # Token bucket rate limiting
│   ├── retry_utils.py        # Retry/backoff utilities
│   ├── error_classifier.py   # API error classification
│   ├── onboarding.py         # First-run setup wizard
│   ├── redact.py             # PII redaction
│   ├── account_usage.py      # API usage tracking
│   └── ...                   # shell_hooks, insights, subdirectory_hints, etc.
│
├── tools/                    # Tool implementations — auto-discovered via tools/registry.py
│   ├── registry.py           # Singleton ToolRegistry with AST-based discovery
│   ├── environments/         # Terminal backends (local, docker, ssh, modal, singularity, daytona)
│   ├── file_operations.py    # ShellFileOperations — file read/write/edit/list/grep via terminal
│   ├── file_tools.py         # High-level file tool wrappers
│   ├── terminal_tool.py      # Terminal command execution tool
│   ├── delegate_tool.py      # Subagent delegation
│   ├── mcp_tool.py           # MCP server integration
│   ├── memory_tool.py        # Memory management tool
│   ├── todo_tool.py          # Task tracking tool
│   ├── browser_tool.py / browser_camofox.py / browser_cdp_tool.py / browser_supervisor.py
│   ├── web_tools.py          # Web search tools
│   ├── code_execution_tool.py
│   ├── image_generation_tool.py
│   ├── vision_tools.py       # Image understanding tools
│   ├── skills_tool.py / skills_hub.py / skill_manager_tool.py / skills_sync.py / skills_guard.py
│   ├── cronjob_tools.py      # Cron job management tools
│   ├── send_message_tool.py  # Cross-platform send via gateway
│   ├── process_registry.py / tool_backend_helpers.py / tool_output_limits.py
│   ├── ...                   # ~70 files total
│
├── hermes_cli/               # CLI subcommands, setup wizard, plugins loader, skin engine (~90 files)
│   ├── main.py               # CLI entry point — argparse, _apply_profile_override
│   ├── config.py             # DEFAULT_CONFIG, OPTIONAL_ENV_VARS, load_config() deep-merge
│   ├── commands.py           # COMMAND_REGISTRY — single source of truth for all slash commands
│   ├── setup.py              # Setup wizard (full/first-time/quick/--section)
│   ├── profiles.py           # Profile management (CRUD, wrapper scripts, export/import)
│   ├── plugins.py            # PluginManager — 4-source discovery, hook system
│   ├── skin_engine.py        # YAML-driven cosmetic theme system
│   ├── web_server.py + pty_bridge.py  # Web dashboard (FastAPI + PTY)
│   ├── banner.py             # CLI startup banner (Rich panels)
│   ├── curses_ui.py          # Curses-based interactive menus
│   ├── auth.py / auth_commands.py / copilot_auth.py / etc.
│   ├── model_catalog.py / model_normalize.py / model_switch.py / models.py
│   ├── tools_config.py / mcp_config.py
│   ├── skills_config.py / skills_hub.py
│   └── ...
│
├── gateway/                  # Messaging gateway — asyncio daemon (~50 files)
│   ├── run.py                # GatewayRunner — lifecycle, message dispatch, command handlers
│   ├── session.py            # SessionStore, session key derivation, reset policies
│   ├── config.py             # GatewayConfig dataclass, Platform enum, env loading
│   ├── platforms/            # 25+ platform adapters
│   │   ├── base.py           # BasePlatformAdapter ABC
│   │   └── telegram.py, discord.py, whatsapp.py, slack.py, signal.py,
│   │         matrix.py, mattermost.py, email.py, sms.py, homeassistant.py,
│   │         dingtalk.py, feishu.py, feishu_comment.py, wecom.py,
│   │         wecom_callback.py, weixin.py, bluebubbles.py, qqbot/,
│   │         yuanbao.py, yuanbao_media.py, api_server.py, webhook.py
│   ├── hooks.py              # HookRegistry — discover/emit with wildcard matching
│   ├── delivery.py           # DeliveryRouter — cross-platform output delivery
│   ├── stream_consumer.py    # Token streaming with rate-limiting
│   ├── display_config.py     # Per-platform display settings resolver
│   ├── channel_directory.py  # Channel name-to-ID resolution
│   ├── mirror.py             # Cross-platform message mirroring
│   ├── status.py             # PID files, runtime health, scoped locks
│   ├── pairing.py            # Code-based DM authorization
│   └── ...
│
├── plugins/                  # Plugin system
│   ├── memory/               # Memory-provider plugins (honcho, mem0, supermemory, etc.)
│   ├── context_engine/       # Context-engine plugins
│   ├── image_gen/            # Image-gen provider plugins (openai, openai-codex, xai)
│   ├── spotify/              # Spotify integration
│   ├── google_meet/          # Google Meet integration
│   ├── disk-cleanup/         # Disk cleanup tool
│   └── ...                   # example-dashboard, strike-freedom-cockpit
│
├── ui-tui/                   # Ink (React) terminal UI — `hermes --tui`
│   ├── src/                  # TypeScript: entry.tsx, app.tsx, components/, hooks/, lib/
│   └── packages/hermes-ink/  # Custom Ink renderer for terminal output
│
├── tui_gateway/              # Python JSON-RPC backend for the TUI
│   └── server.py, entry.py, render.py, transport.py, slash_worker.py
│
├── acp_adapter/              # ACP server (VS Code / Zed / JetBrains integration)
│   └── server.py, session.py, auth.py, tools.py, events.py, permissions.py
│
├── cron/                     # Scheduler
│   ├── jobs.py               # JSON file-backed job store
│   └── scheduler.py          # 60s tick cycle, file-based locking
│
├── environments/             # RL training environments (Atropos)
│   ├── hermes_base_env.py, agentic_opd_env.py, web_research_env.py
│   ├── benchmarks/           # tb-lite, terminalbench_2, yc_bench
│   ├── hermes_swe_env/       # SWE-bench-style evaluation
│   └── tool_call_parsers/    # Model-specific tool call parsers (~12 parsers)
│
├── scripts/                  # run_tests.sh, release.py, install.sh, etc.
├── website/                  # Docusaurus docs site
├── web/                      # Dashboard SPA (React + Vite)
│
├── nix/                      # Nix flake modules (python, tui, web, devShell)
├── docker/ + Dockerfile + docker-compose.yml
│
├── pyproject.toml            # Build config, extras, entry points
├── config.yaml               # User-facing default config
├── cli-config.yaml.example
└── tests/                    # Pytest suite (~15k tests across ~700 files)
```

---

## File Dependency Chain

```
tools/registry.py  (no deps — imported by all tool files)
       ↑
tools/*.py  (each calls registry.register() at import time)
       ↑
model_tools.py  (imports tools/registry + triggers tool discovery)
       ↑
run_agent.py, cli.py, batch_runner.py, environments/
```

**User config:** `~/.hermes/config.yaml` (settings), `~/.hermes/.env` (API keys only).
**Logs:** `~/.hermes/logs/` — `agent.log` (INFO+), `errors.log` (WARNING+), `gateway.log` when running the gateway. Profile-aware via `get_hermes_home()`. Browse with `hermes logs [--follow] [--level ...] [--session ...]`.

---

## AIAgent Class (run_agent.py)

The `AIAgent` class is the core conversation engine (~12k LOC). It orchestrates the synchronous tool-calling loop with provider routing, interrupt handling, budget tracking, fallback models, memory, skills, context compression, and credential pools.

### Constructor

Takes ~60 parameters. Key groups:
- **Provider:** `base_url`, `api_key`, `provider`, `api_mode`, `model`, `service_tier`, `fallback_model`
- **Routing:** `credential_pool`, `primary_runtime_override`
- **Session:** `session_id`, `platform`, `thread_id`, `user_id`, `chat_id`, `conversation_id`
- **Behavior:** `max_iterations`, `iteration_budget`, `enabled_toolsets`, `disabled_toolsets`, `quiet_mode`
- **Memory/Skills:** `skip_memory`, `skip_context_files`, `preload_skills`
- **Callbacks:** `tool_progress_cb`, `streaming_cb`, `thinking_cb`, `subagent_progress_cb`, `tool_result_will_be_added`
- **Control:** `system_prompt_override`, `prefill_messages`, `checkpoints_config`, `reasoning_config`, `context_compressor`

### Agent Loop

The core loop in `run_conversation()` is synchronous with interrupt polling:

```python
while (api_call_count < self.max_iterations and self.iteration_budget.remaining > 0) \
        or self._budget_grace_call:
    if self._interrupt_requested: break
    response = client.chat.completions.create(model=model, messages=messages, tools=tool_schemas)
    if response.tool_calls:
        for tool_call in response.tool_calls:
            result = handle_function_call(tool_call.name, tool_call.args, task_id)
            messages.append(tool_result_message(result))
        api_call_count += 1
    else:
        return response.content
```

- Messages follow OpenAI format: `{"role": "system/user/assistant/tool", ...}`
- Reasoning content stored in `assistant_msg["reasoning"]`
- Context compression triggers mid-loop when token budget is exceeded
- Interrupts checked between tool calls via `_check_interrupt()`
- Grace call: one additional LLM call after budget exhausted if a tool was in-flight

### Simple / Full interfaces

```python
def chat(self, message: str) -> str:  # Returns final response string
def run_conversation(self, user_message: str, ...) -> dict:  # Returns {final_response, messages}
```

---

## CLI Architecture (cli.py + hermes_cli/)

- **Rich** for banner/panels, **prompt_toolkit** for input with autocomplete
- **Skin engine** (`hermes_cli/skin_engine.py`) — YAML-driven cosmetic customization
- **KawaiiSpinner** (`agent/display.py`) — animated faces during API calls, `┊` activity feed for tool results
- `load_cli_config()` in cli.py merges hardcoded defaults + user config YAML
- `process_command()` dispatches on canonical command name via `resolve_command()` from the central registry
- Skill slash commands: `agent/skill_commands.py` scans `~/.hermes/skills/`, injects as **user message** (not system prompt) to preserve prompt caching

### CLI Entry Point Flow (`hermes_cli/main.py`)

```
hermes → hermes_cli/main.py:main()
  ├── _apply_profile_override()  # Sets HERMES_HOME before any module imports
  ├── argparse dispatch via set_defaults(func=...)
  │     ├── cmd_chat()     → cli.py HermesCLI  (interactive session)
  │     ├── cmd_gateway()  → gateway.py        (messaging daemon)
  │     ├── cmd_setup()    → setup.py           (wizard)
  │     ├── cmd_tools()    → tools_config.py    (tool management)
  │     ├── cmd_skills()   → skills_config.py   (skill management)
  │     ├── cmd_plugins()  → plugins_cmd.py     (plugin management)
  │     ├── cmd_profile()  → profiles.py        (multi-instance profiles)
  │     ├── cmd_dashboard()→ web_server.py      (web UI daemon)
  │     ├── cmd_logs()     → logs.py            (log viewer)
  │     └── cmd_doctor()   → doctor.py          (diagnostics)
  └── hermes --tui         → ui-tui/ + tui_gateway/  (Ink-based TUI)
```

### Slash Command Registry (`hermes_cli/commands.py`)

All slash commands defined in a central `COMMAND_REGISTRY` list of `CommandDef` objects.

**CommandDef fields:**
- `name` — canonical name without slash (e.g. `"background"`)
- `description` — human-readable description
- `category` — one of `"Session"`, `"Configuration"`, `"Tools & Skills"`, `"Info"`, `"Exit"`
- `aliases` — tuple of alternative names (e.g. `("bg",)`)
- `args_hint` — argument placeholder shown in help (e.g. `"<prompt>"`, `"[name]"`)
- `cli_only` — only available in the interactive CLI
- `gateway_only` — only available in messaging platforms
- `gateway_config_gate` — config dotpath (e.g. `"display.tool_progress_command"`); when set on a `cli_only` command, the command becomes available in the gateway if the config value is truthy. `GATEWAY_KNOWN_COMMANDS` always includes config-gated commands so the gateway can dispatch them; help/menus only show them when the gate is open.

**Adding a slash command:**
1. Add `CommandDef` entry to `COMMAND_REGISTRY` in `hermes_cli/commands.py`
2. Add handler in `HermesCLI.process_command()` in `cli.py`
3. If gateway-available, add handler in `gateway/run.py`
4. For persistent settings, use `save_config_value()` in `cli.py`

**Adding an alias** requires only adding it to the `aliases` tuple on the existing `CommandDef` — dispatch, help text, Telegram menu, Slack mapping, and autocomplete all update automatically.

### Config Loaders (three paths)

| Loader | Used by | Location |
|--------|---------|----------|
| `load_cli_config()` | CLI mode | `cli.py` — merges CLI-specific defaults + user YAML |
| `load_config()` | `hermes tools`, `hermes setup`, most CLI subcommands | `hermes_cli/config.py` — deep-merges `DEFAULT_CONFIG` + user YAML |
| Direct YAML load | Gateway runtime | `gateway/run.py` + `gateway/config.py` — reads user YAML raw |

If you add a new key and the CLI sees it but the gateway doesn't (or vice versa), you're on the wrong loader. Check `DEFAULT_CONFIG` coverage.

### Working directory
- **CLI** — uses the process's current directory (`os.getcwd()`).
- **Messaging** — uses `terminal.cwd` from `config.yaml`. The gateway bridges this to the `TERMINAL_CWD` env var for child tools.

---

## Agent Internals

### Provider Adapters

The agent supports multiple LLM providers through adapter modules in `agent/`. Each provider adapter converts the internal OpenAI-format message list into the provider's native API format:

| Adapter | Provider | Native API |
|---------|----------|------------|
| `agent/anthropic_adapter.py` | Anthropic | Messages API (with beta headers, OAuth, PKCE, adaptive thinking budget) |
| `agent/bedrock_adapter.py` | AWS Bedrock | Converse API (model discovery with caching, error classification) |
| `agent/gemini_native_adapter.py` | Google Gemini | Native Gemini API |
| `agent/gemini_cloudcode_adapter.py` | Gemini Cloud Code | Google Cloud Code API |
| `agent/codex_responses_adapter.py` | OpenAI Codex | Responses API |
| `agent/copilot_acp_client.py` | GitHub Copilot | ACP protocol |

Each adapter typically implements: `convert_messages_to_<provider>()`, `convert_tools_to_<provider>()`, `build_<provider>_kwargs()`, `normalize_<provider>_response()`, and streaming/async variants.

### Transport Layer (`agent/transports/`)

The transport layer abstracts over raw HTTP client configuration:

| File | Transport |
|------|-----------|
| `base.py` | BaseTransport ABC — defines `create_client()`, `chat_completions.create()` interface |
| `chat_completions.py` | OpenAI-style `/v1/chat/completions` transport |
| `anthropic.py` | Anthropic `/v1/messages` transport |
| `bedrock.py` | AWS Bedrock boto3-based transport |
| `codex.py` | OpenAI Codex Responses API transport |
| `types.py` | Shared transport type definitions |

### Memory System

**MemoryProvider ABC** (`agent/memory_provider.py`):
- Required: `name`, `is_available`, `initialize`, `get_tool_schemas`
- Optional: `system_prompt_block`, `prefetch`, `queue_prefetch`, `sync_turn`, `handle_tool_call`, `shutdown`, `on_turn_start`, `on_session_end`, `on_pre_compress`, `on_delegation`, `get_config_schema`, `save_config`, `on_memory_write`

**MemoryManager** (`agent/memory_manager.py`) orchestrates built-in memory + at most one external MemoryProvider. Provides:
- `prefetch_all()`, `sync_all()`, `initialize_all()`, `shutdown_all()`
- `build_system_prompt()` — injects memory context into system prompt
- `get_all_tool_schemas()` — merges memory provider tool schemas
- Context fencing via `StreamingContextScrubber` — strips `<memory-context>` tags from streaming output

Built-in memory providers (`plugins/memory/`): honcho, mem0, supermemory, byterover, hindsight, holographic, openviking, retaindb.

### Prompt Assembly (`agent/prompt_builder.py`)

Stateless system prompt assembly that builds:
1. **Agent identity** (`DEFAULT_AGENT_IDENTITY`)
2. **Platform hint** — per-platform system prompt injection (CLI, Telegram, WhatsApp, Discord, Slack, Signal, email, cron, SMS, etc.)
3. **Environment hints** — WSL detection, timezone
4. **Skills index** — loaded from on-disk cache with 2-layer LRU + disk snapshot
5. **Context files** — scans for `SOUL.md`, `.hermes.md`/`HERMES.md`, `AGENTS.md`, `CLAUDE.md`, `.cursorrules`/`.mdc` with prompt injection detection (13 regex patterns + invisible unicode)

### Prompt Caching (`agent/prompt_caching.py`)

Applies Anthropic `system_and_3` caching strategy: up to 4 `cache_control` breakpoints (system prompt + last 3 non-system messages). Configurable TTL (`ephemeral`, `1h`). Pure functions, no class state.

### Context Compression (`agent/context_compressor.py`)

Default ContextEngine with 4-phase algorithm:
1. **Cheap pruning** — tool outputs replaced with informative 1-line summaries
2. **Head protection** — first N messages preserved
3. **Token-budget tail protection** — ~20K tokens at the end preserved
4. **Structured LLM summarization** — Goal/Progress/Decisions/Questions/Files/Remaining Work template

Anti-thrashing: ≥2 ineffective compressions in a row → skip. Tool pair sanitization removes orphaned tool results. Guided compression via `/compress <focus>`.

### ContextEngine ABC (`agent/context_engine.py`)

Pluggable context management:
- Required: `name`, `update_from_response`, `should_compress`, `compress`
- Optional: `should_compress_preflight`, `has_content_to_compress`, `on_session_start/end/reset`, `get_tool_schemas`, `handle_tool_call`, `get_status`, `update_model`

### Image Generation (`agent/image_gen_provider.py` + `agent/image_gen_registry.py`)

**ImageGenProvider ABC:** required `generate()`, optional `is_available`, `list_models`, `get_setup_schema`, `default_model`. Helpers: `resolve_aspect_ratio`, `save_b64_image`, `success_response`, `error_response`.

**Registry:** thread-safe singleton with `register_provider`, `list_providers`, `get_provider`, `get_active_provider` (reads `image_gen.provider` from config, falls back to single provider or 'fal' legacy default).

Provider plugins in `plugins/image_gen/`: openai, openai-codex, xai.

### Credential Pool (`agent/credential_pool.py`)

`CredentialPool` manages `PooledCredential` objects with:
- **Multi-strategy selection:** `fill_first`, `round_robin`, `random`, `least_used`
- **OAuth token refresh** for Anthropic, Nous, OpenAI Codex
- **Exhaustion cooldown** — reset-at timestamps per credential
- **Soft leasing** — `acquire()/release()` with `max_concurrent` cap
- **Auto-seeding** from `auth.json`, `~/.claude/`, Qwen CLI, env vars
- **Custom endpoint pools** keyed by `custom:<name>`
- **Cross-process token sync** from `~/.claude/.credentials.json`, `auth.json`

### Rate Limiting (`agent/rate_limit_tracker.py`)

Token bucket rate limiter per model/provider. Tracks:
- Requests per minute (RPM), tokens per minute (TPM)
- Concurrent request caps
- Exponential backoff on 429 responses

### Account Usage (`agent/account_usage.py`)

Tracks API usage per provider: tokens in/out, cost, requests, rate limit hits. Persisted to SQLite.

---

## Tool System

### Tool Registry (`tools/registry.py`)

Singleton `ToolRegistry` with AST-based auto-discovery:
- `discover_builtin_tools()` scans `tools/*.py` for `registry.register()` calls at import time
- Thread-safe via `RLock`
- `register()`/`deregister()` with toolset-crossing protection
- Schema retrieval with `check_fn` filtering
- Dispatch with async bridging and error wrapping

### Tool Registration Pattern

```python
import json, os
from tools.registry import registry

def check_requirements() -> bool:
    return bool(os.getenv("EXAMPLE_API_KEY"))

def example_tool(param: str, task_id: str = None) -> str:
    return json.dumps({"success": True, "data": "..."})

registry.register(
    name="example_tool",
    toolset="example",
    schema={"name": "example_tool", "description": "...", "parameters": {...}},
    handler=lambda args, **kw: example_tool(param=args.get("param", ""), task_id=kw.get("task_id")),
    check_fn=check_requirements,
    requires_env=["EXAMPLE_API_KEY"],
)
```

Then add to `toolsets.py` — either `_HERMES_CORE_TOOLS` (all platforms) or a new toolset.

**All handlers MUST return a JSON string.** The registry handles schema collection, dispatch, availability checking, and error wrapping.

### Toolset Organization (`toolsets.py` + `toolset_distributions.py`)

- `toolsets.py`: central `TOOLSETS` dict defining ~30 tool groups. Supports composition via `includes: [other toolsets]`. `_HERMES_CORE_TOOLS` shared across CLI and all messaging platforms.
- `toolset_distributions.py`: per-platform toolset filtering (which toolsets are available on which platforms).

### Agent-Level Tools

Intercepted by `run_agent.py` before `handle_function_call()`:
- **todo_tool.py** (`tools/todo_tool.py`) — task tracking
- **memory_tool.py** (`tools/memory_tool.py`) — memory management
- **clarify_tool.py** (`tools/clarify_tool.py`) — user clarification

### File Operations (`tools/file_operations.py` + `tools/file_tools.py`)

`ShellFileOperations` wraps terminal commands for read/write/edit/list/grep operations. `file_tools.py` provides high-level tools (read, write, edit, search, etc.) with:
- Path security via `path_security.py` (allow/deny lists, symlink protection)
- File staleness detection (`tools/file_state.py`)
- Write safety checks (overwrite confirmation, file matching)
- Binary file detection (`tools/binary_extensions.py`)
- URL safety scanning (`tools/url_safety.py`)

### Environment Backends (`tools/environments/`)

All implement `BaseEnvironment` ABC (in `tools/environments/base.py`). Spawn-per-call model: every `execute()` spawns fresh `bash -c`.

| Backend | File | Execution |
|---------|------|-----------|
| Local | `local.py` | Host shell, `bash -c` |
| Docker | `docker.py` | Container, `cap-drop ALL` |
| Singularity | `singularity.py` | Apptainer, `--containall` |
| SSH | `ssh.py` | Remote, ControlMaster persistence |
| Modal | `modal.py` | Modal SDK cloud sandbox |
| ManagedModal | `managed_modal.py` | Gateway-owned Modal |
| Daytona | `daytona.py` | Daytona cloud SDK |

**BaseEnvironment ABC:**
- Required: `execute(command)`, `init_session()`, `stop()`
- Process: every call spawns fresh subprocess, CWD tracked via in-band stdout markers (remote) or temp file (local)
- `ProcessHandle` protocol, `_ThreadedProcessHandle` adapter for SDK backends
- `FileSyncManager` (`tools/environments/file_sync.py`) for remote backends: syncs credentials/skills/cache via mtime+size tracking

### MCP Tool Integration (`tools/mcp_tool.py`)

Runs MCP servers on a dedicated background event loop with stdio/HTTP transport. Features:
- Circuit breaker for failing servers
- Dynamic server discovery
- OAuth token management (`tools/mcp_oauth.py`, `tools/mcp_oauth_manager.py`)
- Reconnection with exponential backoff
- Structured content handling
- Session expiry detection and 401 handling

### Delegation (`tools/delegate_tool.py`)

Subagent spawning via `ThreadPoolExecutor`:
- Children get isolated context, restricted toolset (`DELEGATE_BLOCKED_TOOLS`), focused system prompt
- Supports `role='leaf'` or `role='orchestrator'`
- Depth cap [1-3] to prevent runaway recursion
- Global spawn pause during critical operations
- Active subagent registry for TUI observability
- `_last_resolved_tool_names` global saved/restored around subagent execution

### Browser Tools (`tools/browser_*.py`)

Multiple browser tool implementations:
- `browser_camofox.py` / `browser_camofox_state.py` — Camofox browser automation
- `browser_cdp_tool.py` — Direct CDP connection
- `browser_supervisor.py` — Browser session manager
- `browser_dialog_tool.py` — Dialog handling
- `browser_providers/` — browser_use, browserbase, firecrawl

### Skills Installation & Management

| File | Purpose |
|------|---------|
| `tools/skills_hub.py` | GitHub/official/community skill sources, optional-skill adapter |
| `tools/skill_manager_tool.py` | Install/uninstall/list skills at runtime |
| `tools/skills_sync.py` | Sync skills from remote sources |
| `tools/skills_guard.py` | Security validation for skill content |
| `tools/skills_tool.py` | Skill search/listing tool |

---

## Gateway Architecture

The gateway is a multi-platform messaging bridge running as a long-lived asyncio daemon.

**Entry point:** `hermes gateway` → `hermes_cli/gateway.py` → `gateway/run.py:start_gateway()`

### Message Flow

```
Platform WebSocket/Webhook/Stream
        │
        ▼
  adapter.handle_message(event)
        │
        ├─ session_key = build_session_key(event.source)
        │
        ├─ Level-1 guard: if session_key in _active_sessions:
        │     ├─ Command bypass (should_bypass_active_session):
        │     │   ├─ /stop, /new, /reset → _dispatch_active_session_command()
        │     │   ├─ /approve, /deny, /status, /background, /restart → direct dispatch
        │     │   └─ else → _busy_session_handler() → interrupt/queue/steer
        │     └─ Return
        │
        └─ _start_session_processing(event, session_key)
              │
              ▼
        _process_message_background(event, session_key)
              │
              ├─ Call _message_handler(event)  [async worker]
              │     │
              │     ▼
              │   GatewayRunner._handle_message(event)
              │     │
              │     ├─ Fire pre_gateway_dispatch hook
              │     ├─ Check user authorization
              │     ├─ Command dispatch (/help, /model, /skills, etc.)
              │     ├─ Place sentinel in _running_agents
              │     ├─ _handle_message_with_agent()
              │     │     ├─ Get/create session (reset policy checked)
              │     │     ├─ Build context prompt
              │     │     ├─ Load transcript history
              │     │     ├─ Session hygiene (auto-compress large transcripts)
              │     │     ├─ Enrich message (vision, STT, @-refs)
              │     │     └─ _run_agent()
              │     │           ├─ Proxy mode → _run_agent_via_proxy()
              │     │           ├─ AIAgent creation/reuse (LRU cache, 128 max)
              │     │           ├─ Tool progress callbacks (editable messages)
              │     │           ├─ Stream consumer (token streaming)
              │     │           ├─ run_sync() in thread pool (run_agent is sync)
              │     │           ├─ Interrupt monitoring (async poll)
              │     │           ├─ Inactivity timeout (staged warning + kill)
              │     │           └─ Auto-TTS voice reply
              │     └─ Return response
              │
              ├─ Send response via _send_with_retry(adapter.send)
              ├─ Extract & send MEDIA tags, images, local files
              └─ Release session guard
```

### Session Lifecycle

- **Session key derivation** (`gateway/session.py`): deterministic from platform + chat_id + user_id
- **SessionStore**: SQLite + JSONL persistence with `SessionEntry` (token tracking, reset flags, resume_pending)
- **Reset policies** (`SessionResetPolicy`): `daily`, `idle`, `both`, `none`
- **Session hygiene**: auto-compression of large transcripts (>20K tokens)
- **Context building**: `build_session_context_prompt()` with PII redaction

### Platform Adapter Pattern (`gateway/platforms/base.py`)

`BasePlatformAdapter` ABC defines:
- **Required:** `connect()`, `disconnect()`, `send()`
- **Optional:** `edit_message()`, `send_media()`, `send_typing()`, `get_channel_info()`, `build_session_key()`
- **Guard infrastructure:** `_active_sessions` dict, `_pending_messages` queue, `_busy_session_handler()`
- **Helpers:** `_send_with_retry()`, `merge_pending_message_event()`, image/audio/video/document cache utilities, proxy resolution chain

See `gateway/platforms/ADDING_A_PLATFORM.md` for the 16-step integration checklist.

### Hooks System (`gateway/hooks.py`)

`HookRegistry` discovers and loads hooks from `~/.hermes/hooks/` + built-in hooks (`gateway/builtin_hooks/`). 8 event types:
- `pre_gateway_dispatch`, `post_gateway_dispatch`, `pre_agent_response`, `post_agent_response`
- `command:*` — wildcard matching (`command:help`, `command:model`, etc.)
- `session_start`, `session_end`, `agent_start`, `agent_complete`

Each hook returns a decision: `deny`, `allow`, `handled`, `rewrite`, or `next`. Sync and async handlers supported.

### Stream Consumer (`gateway/stream_consumer.py`)

`GatewayStreamConsumer` provides queue-based token streaming with:
- Edit transport with adaptive rate limiting (1s default)
- Think-block suppression state machine (hides  tags from platform output)
- Segment breaks for tool boundaries
- Commentary messages (e.g. "Starting tool X...")
- Oversize splitting for message length limits
- Flood control backoff
- Fresh-final optimization (60s threshold — skip stream if response ready quickly)
- Cleanup regex for `MEDIA:` directives and `[[audio_as_voice]]` tags

### Display Config (`gateway/display_config.py`)

Per-platform display settings with 4-layer precedence:
```
platform override > global > platform default > global default
```

4 platform tiers:
- **Tier 1** (high/edit): Discord, Slack — support editing, tool progress
- **Tier 2** (medium): Telegram, Mattermost — support tool progress
- **Tier 3** (low): Matrix, Feishu, iMessage — text-only
- **Tier 4** (minimal): SMS, signal — minimal output

Overrideable keys: `tool_progress`, `show_reasoning`, `tool_preview_length`, `streaming`

### Command Dispatch in Gateway

The gateway runner (`gateway/run.py`) handles ~30 built-in commands: `/help`, `/model`, `/skills`, `/stop`, `/new`, `/reset`, `/queue`, `/status`, `/approve`, `/deny`, `/background`, `/compress`, `/debug`, `/resume`, `/title`, `/usage`, `/steer`, `/voice`, `/update`, `/restart`, `/fast`, `/reasoning`, `/yolo`, `/verbose`, `/compress_focus`, `/branch`, `/worktree`, `/fast_command`, `/stt_config`, `/busy_input_mode`, `/pre_gateway_dispatch`, `/session_boundary_hooks`.

### Delivery Router (`gateway/delivery.py`)

`DeliveryTarget.parse()` supports formats: `origin`, `local`, `platform:chat_id`. `deliver()` with truncation at 4000 chars. Cron output is saved to `~/.hermes/cron/output/{job_id}/`.

### Channel Directory (`gateway/channel_directory.py`)

Resolves channel names to IDs: Discord guild enumeration, Slack `users.conversations`, session-based fallback for other platforms. Supports exact/partial/Guild-qualified match.

---

## TUI Architecture (ui-tui + tui_gateway)

The TUI is a full replacement for the classic CLI, activated via `hermes --tui` or `HERMES_TUI=1`.

### Process Model

```
hermes --tui
  └─ Node (Ink)  ──stdio JSON-RPC──  Python (tui_gateway)
       │                                  └─ AIAgent + tools + sessions
       └─ renders transcript, composer, prompts, activity
```

TypeScript owns the screen. Python owns sessions, tools, model calls, and slash command logic.

### Key Surfaces

| Surface | Ink component | Gateway method |
|---------|---------------|----------------|
| Chat streaming | `app.tsx` + `messageLine.tsx` | `prompt.submit` → `message.delta/complete` |
| Tool activity | `thinking.tsx` | `tool.start/progress/complete` |
| Approvals | `prompts.tsx` | `approval.respond` ← `approval.request` |
| Clarify/sudo/secret | `prompts.tsx`, `maskedPrompt.tsx` | `clarify/sudo/secret.respond` |
| Session picker | `sessionPicker.tsx` | `session.list/resume` |
| Slash commands | Local handler + fallthrough | `slash.exec` → `_SlashWorker`, `command.dispatch` |
| Completions | `useCompletion` hook | `complete.slash`, `complete.path` |
| Theming | `theme.ts` + `branding.tsx` | `gateway.ready` with skin data |

### Dev Commands

```bash
cd ui-tui
npm install       # first time
npm run dev       # watch mode (rebuilds hermes-ink + tsx --watch)
npm start         # production
npm run build     # full build (hermes-ink + tsc)
npm run type-check # typecheck only (tsc --noEmit)
npm run lint      # eslint
npm run fmt       # prettier
npm test          # vitest
```

### TUI in the Dashboard

The dashboard embeds the real `hermes --tui` — **not** a rewrite. See `hermes_cli/pty_bridge.py` + the `@app.websocket("/api/pty")` endpoint in `hermes_cli/web_server.py`.

- Browser loads `web/src/pages/ChatPage.tsx`, which mounts xterm.js's `Terminal` with the WebGL renderer
- `/api/pty?token=…` upgrades to a WebSocket (auth via query param since browsers can't set `Authorization` on WS upgrade)
- The server spawns `hermes --tui` through `ptyprocess` (POSIX PTY — WSL works, native Windows does not)
- Frames: raw PTY bytes each direction; resize via `\x1b[RESIZE:<cols>;<rows>]` intercepted and applied with `TIOCSWINSZ`

**Do not re-implement the primary chat experience in React.** Extend Ink instead.

---

## ACP Adapter (`acp_adapter/`)

Bridges Hermes to the Agent Communication Protocol (ACP) for VS Code / Zed / JetBrains integration.

| File | Purpose |
|------|---------|
| `server.py` | `HermesACPAgent` extends `acp.Agent` — initialize, authenticate, session lifecycle, MCP server management |
| `session.py` | SessionManager maps ACP sessions to AIAgent instances, persisted via SessionDB |
| `tools.py` | `TOOL_KIND_MAP` maps Hermes tool names to ACP `ToolKind` (read/edit/search/execute/fetch) |
| `auth.py` | Token-based authentication |
| `events.py` | Callback factories for tool progress, thinking, messages via `asyncio.run_coroutine_threadsafe` |
| `permissions.py` | Bridges ACP `PermissionOption` to Hermes approval strings with 60s auto-deny |
| `entry.py` | Entry point for `hermes-acp` |

---

## Cron System (`cron/`)

| File | Purpose |
|------|---------|
| `jobs.py` | JSON file-backed job store (`~/.hermes/cron/jobs.json`). Supports cron expressions, intervals, one-shot, timezone handling. Threading lock for concurrent access. |
| `scheduler.py` | Gateway calls `tick()` every 60s. File-based lock (`~/.hermes/cron/.tick.lock`). Job delivery via `DeliveryRouter`. Output saved to `~/.hermes/cron/output/{job_id}/`. |

---

## Web Dashboard (`hermes_cli/web_server.py` + `hermes_cli/pty_bridge.py` + `web/`)

- **Backend:** FastAPI + uvicorn, session-token auth (ephemeral `_SESSION_TOKEN`), CORS localhost-only, SPA mount, plugin API routes
- **Frontend:** React + Vite SPA in `web/` (pages: Chat, Config, Sessions, Skills, Logs, Cron, Analytics, Env, Docs)
- **PTY bridge:** POSIX PTY via `ptyprocess` for embedded `hermes --tui` terminal in ChatPage
- **I18n:** English + Chinese (`web/src/i18n/`)
- **Themes:** Preset-based theme system (`web/src/themes/`)

---

## Plugins

### General Plugins (`hermes_cli/plugins.py` + `plugins/<name>/`)

`PluginManager` discovers plugins from 4 sources: bundled (`plugins/`), user (`~/.hermes/plugins/`), project (`./.hermes/plugins/`), pip entry points. Source order defines override priority.

Each plugin exposes a `register(ctx)` function that can:
- Register lifecycle hooks: `pre_tool_call`, `post_tool_call`, `pre_llm_call`, `post_llm_call`, `on_session_start`, `on_session_end`
- Register new tools via `ctx.register_tool(...)`
- Register CLI subcommands via `ctx.register_cli_command(...)` — argparse tree wired into `hermes` at startup

Hooks invoked from `model_tools.py` (pre/post tool) and `run_agent.py` (lifecycle).

**Discovery timing pitfall:** `discover_plugins()` only runs as a side effect of importing `model_tools.py`. Code paths that read plugin state without importing `model_tools.py` first must call `discover_plugins()` explicitly (it's idempotent).

**Rule (Teknium, May 2026):** plugins MUST NOT modify core files (`run_agent.py`, `cli.py`, `gateway/run.py`, `hermes_cli/main.py`, etc.). If a plugin needs a capability the framework doesn't expose, expand the generic plugin surface.

### Memory-Provider Plugins (`plugins/memory/<name>/`)

Each implements `MemoryProvider` ABC, orchestrated by `agent/memory_manager.py`. Lifecycle hooks: `sync_turn`, `prefetch`, `shutdown`, `post_setup`.

CLI commands via `plugins/memory/<name>/cli.py`: if a memory plugin defines `register_cli(subparser)`, `discover_plugin_cli_commands()` wires it into `hermes <plugin>`. Only exposed for the **currently active** memory provider.

---

## Skills

Two parallel surfaces:
- **`skills/`** — built-in skills shipped and loadable by default (organized by category: apple, creative, data-science, devops, github, mlops, productivity, research, etc.)
- **`optional-skills/`** — heavier or niche skills NOT active by default. Installed via `hermes skills install official/<category>/<skill>`. Categories: autonomous-ai-agents, blockchain, communication, creative, devops, email, health, mcp, migration, mlops, productivity, research, security, web-development.

### SKILL.md frontmatter

Standard fields: `name`, `description`, `version`, `platforms` (OS-gating list), `metadata.hermes.tags`, `metadata.hermes.category`, `metadata.hermes.config` (config.yaml settings the skill needs).

---

## Profiles: Multi-Instance Support

Hermes supports **profiles** — multiple fully isolated instances, each with its own `HERMES_HOME` directory (config, API keys, memory, sessions, skills, gateway, etc.).

The core mechanism: `_apply_profile_override()` in `hermes_cli/main.py` sets `HERMES_HOME` before any module imports. All `get_hermes_home()` references automatically scope to the active profile.

### Rules for profile-safe code

1. **Use `get_hermes_home()` for all HERMES_HOME paths.** Import from `hermes_constants`. NEVER hardcode `~/.hermes` or `Path.home() / ".hermes"` in code that reads/writes state.
   ```python
   # GOOD
   from hermes_constants import get_hermes_home
   config_path = get_hermes_home() / "config.yaml"

   # BAD — breaks profiles
   config_path = Path.home() / ".hermes" / "config.yaml"
   ```

2. **Use `display_hermes_home()` for user-facing messages.** Import from `hermes_constants`. Returns `~/.hermes` for default or `~/.hermes/profiles/<name>` for profiles.

3. **Module-level constants are fine** — they cache `get_hermes_home()` at import time, which is AFTER `_apply_profile_override()` sets the env var.

4. **Tests that mock `Path.home()` must also set `HERMES_HOME`** — since code now uses `get_hermes_home()` (reads env var):
   ```python
   with patch.object(Path, "home", return_value=tmp_path), \
        patch.dict(os.environ, {"HERMES_HOME": str(tmp_path / ".hermes")}):
       ...
   ```

5. **Gateway platform adapters should use token locks** — call `acquire_scoped_lock()` in `connect()`/`start()` and `release_scoped_lock()` in `disconnect()`/`stop()`. Prevents two profiles from using the same credential.

6. **Profile operations are HOME-anchored, not HERMES_HOME-anchored** — `_get_profiles_root()` returns `Path.home() / ".hermes" / "profiles"`, NOT `get_hermes_home() / "profiles"`.

## Known Pitfalls

### DO NOT hardcode `~/.hermes` paths
Use `get_hermes_home()` from `hermes_constants` for code paths. Use `display_hermes_home()` for user-facing print/log messages. Hardcoding `~/.hermes` breaks profiles — each profile has its own `HERMES_HOME` directory. This was the source of 5 bugs fixed in PR #3575.

### DO NOT introduce new `simple_term_menu` usage
Existing call sites in `hermes_cli/main.py` remain for legacy fallback only; the preferred UI is curses (stdlib) because `simple_term_menu` has ghost-duplication rendering bugs in tmux/iTerm2 with arrow keys. New interactive menus must use `hermes_cli/curses_ui.py` — see `hermes_cli/tools_config.py` for the canonical pattern.

### DO NOT use `\033[K` (ANSI erase-to-EOL) in spinner/display code
Leaks as literal `?[K` text under `prompt_toolkit`'s `patch_stdout`. Use space-padding: `f"\r{line}{' ' * pad}"`.

### `_last_resolved_tool_names` is a process-global in `model_tools.py`
`_run_single_child()` in `delegate_tool.py` saves and restores this global around subagent execution. If you add new code that reads this global, be aware it may be temporarily stale during child agent runs.

### DO NOT hardcode cross-tool references in schema descriptions
Tool schema descriptions must not mention tools from other toolsets by name (e.g., `browser_navigate` saying "prefer web_search"). Those tools may be unavailable (missing API keys, disabled toolset), causing the model to hallucinate calls to non-existent tools. If a cross-reference is needed, add it dynamically in `get_tool_definitions()` in `model_tools.py`.

### The gateway has TWO message guards — both must bypass approval/control commands
When an agent is running, messages pass through two sequential guards:
(1) **base adapter** (`gateway/platforms/base.py`) queues messages when `session_key in self._active_sessions`, and
(2) **gateway runner** (`gateway/run.py`) intercepts `/stop`, `/new`, `/queue`, `/status`, `/approve`, `/deny` before they reach `running_agent.interrupt()`. Any new command that must reach the runner while the agent is blocked MUST bypass BOTH guards.

### Squash merges from stale branches silently revert recent fixes
Before squash-merging a PR, ensure the branch is up to date with `main`. A stale branch's version of an unrelated file will silently overwrite recent fixes on main when squashed. Verify with `git diff HEAD~1..HEAD` after merging.

### Don't wire in dead code without E2E validation
Unused code that was never shipped was dead for a reason. Before wiring an unused module into a live code path, E2E test the real resolution chain with actual imports (not mocks) against a temp `HERMES_HOME`.

### Tests must not write to `~/.hermes/`
The `_isolate_hermes_home` autouse fixture in `tests/conftest.py` redirects `HERMES_HOME` to a temp dir. Never hardcode `~/.hermes/` paths in tests.

## Testing

**ALWAYS use `scripts/run_tests.sh`** — do not call `pytest` directly. The script enforces hermetic environment parity with CI (unset credential vars, TZ=UTC, LANG=C.UTF-8, 4 xdist workers matching GHA ubuntu-latest).

```bash
scripts/run_tests.sh                                  # full suite, CI-parity
scripts/run_tests.sh tests/gateway/                   # one directory
scripts/run_tests.sh tests/agent/test_foo.py::test_x  # one test
scripts/run_tests.sh -v --tb=long                     # pass-through pytest flags
```

### Why the wrapper

Five real sources of local-vs-CI drift the script closes:

| | Without wrapper | With wrapper |
|---|---|---|
| Provider API keys | Whatever is in your env | All `*_API_KEY`/`*_TOKEN`/etc. unset |
| HOME / `~/.hermes/` | Your real config+auth.json | Temp dir per test |
| Timezone | Local TZ | UTC |
| Locale | Whatever is set | C.UTF-8 |
| xdist workers | `-n auto` = all cores | `-n 4` matching CI |

### Running without the wrapper (only if you must)

```bash
source .venv/bin/activate
python -m pytest tests/ -q -n 4
```

### Don't write change-detector tests

A test is a **change-detector** if it fails whenever data that is **expected to change** gets updated — model catalogs, config version numbers, enumeration counts, hardcoded lists of provider models.

**Do not write:**
```python
# catalog snapshot — breaks every model release
assert "gemini-2.5-pro" in _PROVIDER_MODELS["gemini"]

# config version literal — breaks every schema bump
assert DEFAULT_CONFIG["_config_version"] == 21

# enumeration count — breaks every time a skill/provider is added
assert len(_PROVIDER_MODELS["huggingface"]) == 8
```

**Do write:**
```python
# behavior: does the catalog plumbing work at all?
assert "gemini" in _PROVIDER_MODELS
assert len(_PROVIDER_MODELS["gemini"]) >= 1

# behavior: does migration bump the user's version to current latest?
assert raw["_config_version"] == DEFAULT_CONFIG["_config_version"]

# invariant: no plan-only model leaks into the legacy list
assert not (set(moonshot_models) & coding_plan_only_models)

# invariant: every model in the catalog has a context-length entry
for m in _PROVIDER_MODELS["huggingface"]:
    assert m.lower() in DEFAULT_CONTEXT_LENGTHS_LOWER
```

The rule: if the test reads like a snapshot of current data, delete it. If it reads like a contract about how two pieces of data must relate, keep it.