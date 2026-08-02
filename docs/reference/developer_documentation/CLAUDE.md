# Claude AI Integration and Usage Guide

<!-- PROJECTS_MEMORY_AGENT_ALIGNMENT_BEGIN -->

## Projects-Level Agent Alignment (Workspace Memory)

**Purpose:** ensure any agent/LLM (Codex, Copilot, Claude Code, Qwen, GLM, etc.) starts aligned with the same workspace memory + project context.

### Step 0 (first time in this folder)
Generate the per-project context pack:
```bash
/Users/pranay/Projects/agent-start
```

### Step 1 (per shell)
Load the shared defaults for this project session:
```bash
source Docs/context/agent-start/STEP1_ENV.sh
# Or (no file read) print exports and eval:
/Users/pranay/Projects/agent-start --print-step1 --skip-index
```

### Step 2 (generate aligned context pack)
```bash
/Users/pranay/Projects/agent-start
```

Outputs:
- Canonical project-local pack:
  - `Docs/context/agent-start/SESSION_CONTEXT.md`
  - `Docs/context/agent-start/AGENT_KICKOFF_PROMPT.txt`
  - `Docs/context/agent-start/STEP1_ENV.sh`
- Compatibility mirrors when present:
  - `.agent/SESSION_CONTEXT.md`
  - `.agent/AGENT_KICKOFF_PROMPT.txt`
  - `.agent/STEP1_ENV.sh`
  - `frontend/docs/context/agent-start/*`

### Automation (already configured)
- Terminal auto-loads `Docs/context/agent-start/STEP1_ENV.sh` when you `cd` into a project under `/Users/pranay/Projects` (zsh hook).
- VS Code/Antigravity can run `agent-start --skip-index` on folder open via `.vscode/tasks.json`.

### How agents should use this
- Provide the canonical `Docs/context/agent-start/AGENT_KICKOFF_PROMPT.txt` and `Docs/context/agent-start/SESSION_CONTEXT.md` as the first context for the agent.
- If sources conflict, the agent must cite concrete file paths and ask before proceeding.
- If the canonical context pack is missing or stale, run `/Users/pranay/Projects/agent-start --skip-index` before planning changes.
- Treat `.agent/` files as compatibility mirrors only.
- Do not start implementation until `Docs/context/agent-start/AGENT_KICKOFF_PROMPT.txt` and `Docs/context/agent-start/SESSION_CONTEXT.md` are loaded.

### Mandatory agent operating mandate
- Begin every substantial task by refreshing ground truth: read the applicable instruction stack, repo-local `AGENTS.md`/`CLAUDE.md`, and any Qwen, Codex, Copilot, or other agent-specific instruction files relevant to the repo.
- Check the current codebase, docs, worklogs, and project status before planning or coding. Parallel agents may have changed files, decisions, or docs since the last session.
- Treat drift as normal: before editing and again before finalizing, re-check the files and docs you rely on, then adapt rather than assuming older context still holds.
- Use relevant skills and workflow guidance after checking the configured skill locations. Do not default to one toolset when a better domain skill exists.
- Think from first principles and optimize for long-term, scalable, architecturally sound solutions. Existing code is evidence, not a boundary; if current implementation no longer fits the product reality or architecture, propose or implement the proper path.
- Avoid building duplicate or parallel systems. Extend canonical routes, pipelines, validation, docs, and tools unless the project explicitly calls for a new replacement path.
- Git safety: read-only git inspection is allowed; no destructive commands, staging, commits, pushes, resets, or checkouts without explicit permission in the current conversation.
- Research online when facts may be current, external, or uncertain; cite sources when research affects decisions.
- Test changes, verify for regressions, and document findings, decisions, open questions, and follow-up work in durable project artifacts.

### Mandatory commit gate
Install or refresh the managed repo-local git hooks. They resolve the repo's effective hook path, block commit creation in `prepare-commit-msg` until the current full `motto_v3.md` has a fresh attestation, then enforce objective diff checks plus commit trailers in `pre-commit` and `commit-msg`:
```bash
python3 /Users/pranay/Projects/workspace_memory/scripts/install_git_precommit_agent_hook.py
```

Refresh the current repo's motto attestation before committing:
```bash
python3 /Users/pranay/Projects/workspace_memory/scripts/attest_motto.py --repo "$PWD"
```

### Shared Idea Pad Protocol (Required)
- Canonical file: `/Users/pranay/Projects/idea_pad/IDEA_PAD.md`
- Raw capture file: `/Users/pranay/Projects/idea_pad/IDEA_DUMP.md`
- Do not create per-model primary copies of the idea pad.
- Do not overwrite the whole file; use append/update workflow with validation.
- Capture rough ideas in `IDEA_DUMP.md`, then promote high-signal items into `IDEA_PAD.md`.
- Before edits:
```bash
python3 /Users/pranay/Projects/idea_pad/scripts/idea_pad_tool.py validate
```
- Add new ideas safely:
```bash
python3 /Users/pranay/Projects/idea_pad/scripts/idea_pad_tool.py add --title "<title>" --owner "<agent>" --type build
```
- After updates, refresh shared memory index:
```bash
cd /Users/pranay/Projects
./projects-memory index
```

<!-- PROJECTS_MEMORY_AGENT_ALIGNMENT_END -->

This document outlines the integration of Claude AI (Anthropic) within the ReLoop, specifically its role as a tertiary model in the multi-model AI strategy. It covers the rationale, API interaction, and considerations for its use.

## Role in Multi-Model AI Strategy

Claude AI serves as the **Tertiary Model** in our AI/ML pipeline. Its primary functions are:

1.  **Fallback Mechanism**: To be invoked if both the Primary (Gemini) and Secondary (OpenAI GPT-4V) models fail or return unsatisfactory results.
2.  **Specialized Analysis**: To be used for particularly complex or ambiguous items where its nuanced understanding and detailed reasoning might provide superior classification or explanation.
3.  **Comparative Benchmarking**: Its responses can be used periodically to benchmark against other models and identify areas where Claude might excel, potentially informing future adjustments to the model orchestration logic.

## Rationale for Choosing Claude

-   **Strong Analytical Reasoning**: Claude models are known for their strong reasoning capabilities, which can be beneficial for waste items that require understanding context or subtle visual cues.
-   **Different Model Architecture**: Provides diversity from Gemini and OpenAI, reducing the chance of all models failing on the same type of input due to shared architectural biases.
-   **Handling of Uncertainty**: Claude models can be good at expressing uncertainty or providing detailed explanations when a definitive classification is difficult, which is valuable for user education.
-   **Long Context Windows** (though less critical for single image classification): Useful if we expand to multi-image analysis or textual context accompanying images.

## API Interaction

Interaction with Claude will be via its official API. The `AiService` in the app will encapsulate the logic for calling Claude.

### Key API Parameters (Conceptual)

-   **Model**: Specify the Claude model version (e.g., `claude-3-opus-20240229`, `claude-3-sonnet-20240229`, `claude-3-haiku-20240307`). We'll likely start with Sonnet for a balance of capability and cost, or Haiku for speed if latency is critical in its tertiary role.
-   **Prompt**: A carefully crafted prompt will be sent, including:
    -   The image data (base64 encoded).
    -   System message defining Claude's role (e.g., "You are a waste classification expert. Analyze this image and classify the primary waste item.").
    -   Instructions on the desired output format (e.g., JSON with fields for `itemName`, `category`, `disposalMethod`, `reasoning`).
-   **Max Tokens**: To control the length and cost of the response.
-   **Temperature**: To control the creativity/determinism of the response (likely a low temperature for classification).

### Example Request Structure (Conceptual Python)

```python
import anthropic

client = anthropic.Anthropic(api_key="YOUR_ANTHROPIC_API_KEY")

response = client.messages.create(
    model="claude-3-sonnet-20240229",
    max_tokens=1024,
    messages=[
        {
            "role": "user",
            "content": [
                {
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": "image/jpeg", # or image/png
                        "data": "BASE64_ENCODED_IMAGE_DATA"
                    }
                },
                {
                    "type": "text",
                    "text": "Classify the primary waste item in this image. Provide its name, category (e.g., Wet Waste, Dry Recyclable, E-Waste, Hazardous), and a brief disposal instruction. Explain your reasoning."
                }
            ]
        }
    ]
)

print(response.content)
```

### Response Parsing

The `AiService` will parse Claude's JSON (or structured text) response to extract the classification details and map them to the app's internal `WasteClassification` model.

## Considerations for Claude Integration

-   **API Costs**: Claude API calls have associated costs. Its use as a tertiary model helps manage this, but budget monitoring is essential.
-   **Latency**: API call latency will be a factor. The model orchestration logic should consider this, especially if Claude is invoked after timeouts from primary/secondary models.
-   **Prompt Engineering**: Effective prompting is crucial to get accurate and consistently formatted responses from Claude. This will require iteration.
-   **Error Handling**: Robust error handling for API failures, rate limits, and unexpected response formats.
-   **Model Versioning**: Keep track of Claude model versions used and manage updates as new versions are released.
-   **Rate Limits**: Be aware of and manage API rate limits.

## When is Claude Invoked?

The `ModelOrchestrationLayer` (defined in `multi_model_ai_strategy.md` and implemented in `AiService`) will decide when to call Claude. This typically happens if:

1.  Gemini (Primary) and OpenAI (Secondary) both fail to provide a response (due to errors, timeouts, etc.).
2.  Gemini and OpenAI provide low-confidence scores, and the item is deemed complex enough to warrant a third opinion.
3.  A specific user setting or A/B test routes the request to Claude for evaluation purposes.

## Future Potential

-   **Detailed Explanations**: Leverage Claude's strong textual generation for more in-depth educational content related to a classified item.
-   **Conversational Interface**: If the app incorporates a chatbot for waste-related queries, Claude could be a strong candidate to power it.
-   **Complex Scenario Analysis**: For users uploading images of mixed waste or asking complex disposal questions, Claude's reasoning could be beneficial.

By integrating Claude as a tertiary option, the ReLoop enhances its AI pipeline's resilience, accuracy for complex cases, and adaptability.