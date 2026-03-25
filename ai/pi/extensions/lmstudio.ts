/**
 * LM Studio Provider Extension for pi
 *
 * Connects pi to LM Studio's local OpenAI-compatible API.
 * Works with both LM Studio (GUI) and lmstudio-server (headless).
 *
 * Setup:
 *   1. Start LM Studio and load a model (or run `lms server start`)
 *   2. The API defaults to http://localhost:1234/v1
 *   3. Use `/model` in pi to select an lmstudio model
 *
 * Environment variables:
 *   LMSTUDIO_BASE_URL  - Override API endpoint (default: http://localhost:1234/v1)
 *   LMSTUDIO_API_KEY   - API key if required (default: "lm-studio" — LM Studio ignores this)
 *
 * Usage:
 *   # Auto-discovered from ~/.pi/agent/extensions/lmstudio/
 *   pi
 *
 *   # Or test directly
 *   pi -e ~/.pi/agent/extensions/lmstudio
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const DEFAULT_BASE_URL = "http://localhost:1234/v1";
const DEFAULT_API_KEY = "lm-studio"; // LM Studio doesn't require a real key

interface LMStudioModel {
  id: string;
  object: string;
  owned_by: string;
}

interface LMStudioModelsResponse {
  data: LMStudioModel[];
}

async function fetchLoadedModels(baseUrl: string): Promise<LMStudioModel[]> {
  try {
    const response = await fetch(`${baseUrl}/models`);
    if (!response.ok) return [];
    const data = (await response.json()) as LMStudioModelsResponse;
    return data.data || [];
  } catch {
    return [];
  }
}

function makeDisplayName(modelId: string): string {
  // Turn "lmstudio-community/Meta-Llama-3.1-8B-Instruct-GGUF" into "Meta Llama 3.1 8B Instruct"
  const basename = modelId.includes("/") ? modelId.split("/").pop()! : modelId;
  return basename
    .replace(/-GGUF$/i, "")
    .replace(/[-_]/g, " ")
    .trim();
}

export default function (pi: ExtensionAPI) {
  const baseUrl = process.env.LMSTUDIO_BASE_URL || DEFAULT_BASE_URL;
  const apiKey = process.env.LMSTUDIO_API_KEY || DEFAULT_API_KEY;

  // Register a command to discover and register currently loaded models
  pi.registerCommand("lmstudio", {
    description: "Discover models from LM Studio and register them as providers",
    handler: async (args, ctx) => {
      const url = args?.trim() || baseUrl;
      ctx.ui.notify(`Connecting to LM Studio at ${url}...`, "info");

      const models = await fetchLoadedModels(url);
      if (models.length === 0) {
        ctx.ui.notify(
          "No models found. Is LM Studio running with a model loaded?",
          "error"
        );
        return;
      }

      const modelConfigs = models.map((m) => ({
        id: m.id,
        name: `${makeDisplayName(m.id)} (LM Studio)`,
        reasoning: false, // Most local models don't support extended thinking
        input: ["text"] as ("text" | "image")[],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 }, // Local = free
        contextWindow: 32768, // Conservative default; override per model below
        maxTokens: 4096,
        compat: {
          supportsDeveloperRole: false, // Use "system" role
          maxTokensField: "max_tokens" as const,
        },
      }));

      pi.registerProvider("lmstudio", {
        baseUrl: url,
        apiKey,
        api: "openai-completions",
        models: modelConfigs,
      });

      const names = models.map((m) => m.id).join(", ");
      ctx.ui.notify(
        `Registered ${models.length} model(s): ${names}\nUse /model to select one.`,
        "success"
      );
    },
  });

  // Register a refresh command
  pi.registerCommand("lmstudio-refresh", {
    description: "Refresh the list of loaded LM Studio models",
    handler: async (_args, ctx) => {
      const models = await fetchLoadedModels(baseUrl);
      if (models.length === 0) {
        ctx.ui.notify(
          "No models found. Is LM Studio running with a model loaded?",
          "error"
        );
        return;
      }

      const modelConfigs = models.map((m) => ({
        id: m.id,
        name: `${makeDisplayName(m.id)} (LM Studio)`,
        reasoning: false,
        input: ["text"] as ("text" | "image")[],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 32768,
        maxTokens: 4096,
        compat: {
          supportsDeveloperRole: false,
          maxTokensField: "max_tokens" as const,
        },
      }));

      pi.registerProvider("lmstudio", {
        baseUrl,
        apiKey,
        api: "openai-completions",
        models: modelConfigs,
      });

      ctx.ui.notify(
        `Refreshed: ${models.length} model(s) available. Use /model to select.`,
        "success"
      );
    },
  });

  // Auto-discover on startup
  pi.on("session_start", async (_event, ctx) => {
    const models = await fetchLoadedModels(baseUrl);
    if (models.length > 0) {
      const modelConfigs = models.map((m) => ({
        id: m.id,
        name: `${makeDisplayName(m.id)} (LM Studio)`,
        reasoning: false,
        input: ["text"] as ("text" | "image")[],
        cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
        contextWindow: 32768,
        maxTokens: 4096,
        compat: {
          supportsDeveloperRole: false,
          maxTokensField: "max_tokens" as const,
        },
      }));

      pi.registerProvider("lmstudio", {
        baseUrl,
        apiKey,
        api: "openai-completions",
        models: modelConfigs,
      });

      const names = models.map((m) => m.id).join(", ");
      ctx.ui.notify(`LM Studio: ${models.length} model(s) loaded (${names})`, "info");
    }
  });
}
