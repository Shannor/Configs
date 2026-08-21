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
 *   LMSTUDIO_BASE_URL    - Override local API endpoint (default: http://localhost:1234/v1)
 *   LMSTUDIO_REMOTE_URL  - Remote server API endpoint (e.g., http://homeserver.local:1234/v1)
 *   LMSTUDIO_API_KEY     - API key if required (default: "lm-studio" — LM Studio ignores this)
 *
 * Models keep their natural LM Studio IDs (org/model) and are registered
 * under the "lmstudio" provider. Reference them as:
 *   lmstudio/deepseek/deepseek-r1-0528-qwen3-8b
 *   lmstudio/google/gemma-3-4b
 *   lmstudio/nvidia/nemotron-3-nano-4b
 *   lmstudio/qwen/qwen3.5-9b
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";

const DEFAULT_BASE_URL = "http://localhost:1234/v1";
const DEFAULT_REMOTE_URL = "http://homeserver.local:1234/v1";
const DEFAULT_API_KEY = "lm-studio";

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
  const basename = modelId.includes("/") ? modelId.split("/").pop()! : modelId;
  return basename
    .replace(/-GGUF$/i, "")
    .replace(/[-_]/g, " ")
    .trim();
}

/**
 * Known LM Studio models — registered synchronously so pi can resolve them
 * before any async operations complete. Add new models here as you download them.
 */
const KNOWN_MODELS = [
  "deepseek/deepseek-r1-0528-qwen3-8b",
  "google/gemma-3-4b",
  "nvidia/nemotron-3-nano-4b",
  "qwen/qwen3.5-9b",
];

function makeModelConfig(lmsId: string, label = "LM Studio") {
  return {
    id: lmsId,
    name: `${makeDisplayName(lmsId)} (${label})`,
    reasoning: false,
    input: ["text"] as ("text" | "image")[],
    cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0 },
    contextWindow: 32768,
    maxTokens: 8192,
    compat: {
      supportsDeveloperRole: false,
      maxTokensField: "max_tokens" as const,
    },
  };
}

function registerLmstudio(
  pi: ExtensionAPI,
  baseUrl: string,
  apiKey: string,
  lmsIds: string[],
  providerName = "lmstudio",
  label = "LM Studio"
) {
  pi.registerProvider(providerName, {
    baseUrl,
    apiKey,
    api: "openai-completions",
    models: lmsIds.map((id) => makeModelConfig(id, label)),
  });
}

export default function (pi: ExtensionAPI) {
  const baseUrl = process.env.LMSTUDIO_BASE_URL || DEFAULT_BASE_URL;
  const apiKey = process.env.LMSTUDIO_API_KEY || DEFAULT_API_KEY;

  // Register known models SYNCHRONOUSLY so they exist before --model validation
  registerLmstudio(pi, baseUrl, apiKey, KNOWN_MODELS);

  // On session start, refresh from LM Studio to pick up any newly loaded models
  pi.on("session_start", async (_event, ctx) => {
    // Discover local models
    const models = await fetchLoadedModels(baseUrl);
    if (models.length > 0) {
      const lmsIds = models
        .filter((m) => !m.id.startsWith("text-embedding") && m.id.includes("/"))
        .map((m) => m.id);
      registerLmstudio(pi, baseUrl, apiKey, lmsIds);

      const names = lmsIds.map((id) => `lmstudio/${id}`).join(", ");
      ctx.ui.notify(`LM Studio (local): ${lmsIds.length} model(s) available (${names})`, "info");
    }

    // Discover remote models
    const remoteUrl = process.env.LMSTUDIO_REMOTE_URL || DEFAULT_REMOTE_URL;
    const remoteModels = await fetchLoadedModels(remoteUrl);
    if (remoteModels.length > 0) {
      const remoteLmsIds = remoteModels
        .filter((m) => !m.id.startsWith("text-embedding") && m.id.includes("/"))
        .map((m) => m.id);
      registerLmstudio(pi, remoteUrl, apiKey, remoteLmsIds, "lmstudio-remote", "Remote");

      const names = remoteLmsIds.map((id) => `lmstudio-remote/${id}`).join(", ");
      ctx.ui.notify(`LM Studio (remote): ${remoteLmsIds.length} model(s) available (${names})`, "info");
    }
  });

  // Manual discovery command
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

      const lmsIds = models
        .filter((m) => !m.id.startsWith("text-embedding") && m.id.includes("/"))
        .map((m) => m.id);
      registerLmstudio(pi, url, apiKey, lmsIds);

      const names = lmsIds.map((id) => `lmstudio/${id}`).join(", ");
      ctx.ui.notify(
        `Registered ${lmsIds.length} model(s): ${names}\nUse /model to select one.`,
        "success"
      );
    },
  });

  // Remote server command
  pi.registerCommand("lmstudio-remote", {
    description:
      "Connect to a remote LM Studio server (default: homeserver.local:1234)",
    handler: async (args, ctx) => {
      const remoteUrl =
        args?.trim() ||
        process.env.LMSTUDIO_REMOTE_URL ||
        DEFAULT_REMOTE_URL;
      ctx.ui.notify(`Connecting to remote LM Studio at ${remoteUrl}...`, "info");

      const models = await fetchLoadedModels(remoteUrl);
      if (models.length === 0) {
        ctx.ui.notify(
          `No models found at ${remoteUrl}. Is LM Studio running on the remote server with a model loaded?\nMake sure the server is started with: lms server start --bind 0.0.0.0`,
          "error"
        );
        return;
      }

      const lmsIds = models
        .filter((m) => !m.id.startsWith("text-embedding") && m.id.includes("/"))
        .map((m) => m.id);
      registerLmstudio(pi, remoteUrl, apiKey, lmsIds, "lmstudio-remote", "Remote");

      const names = lmsIds.map((id) => `lmstudio-remote/${id}`).join(", ");
      ctx.ui.notify(
        `Remote: ${lmsIds.length} model(s) registered: ${names}\nUse /model to select one.`,
        "success"
      );
    },
  });

  // Refresh command (local + remote)
  pi.registerCommand("lmstudio-refresh", {
    description: "Refresh the list of loaded LM Studio models (local and remote)",
    handler: async (_args, ctx) => {
      const results: string[] = [];

      // Refresh local
      const localModels = await fetchLoadedModels(baseUrl);
      if (localModels.length > 0) {
        const lmsIds = localModels
          .filter((m) => !m.id.startsWith("text-embedding") && m.id.includes("/"))
          .map((m) => m.id);
        registerLmstudio(pi, baseUrl, apiKey, lmsIds);
        results.push(`Local: ${lmsIds.length} model(s)`);
      }

      // Refresh remote
      const remoteUrl = process.env.LMSTUDIO_REMOTE_URL || DEFAULT_REMOTE_URL;
      const remoteModels = await fetchLoadedModels(remoteUrl);
      if (remoteModels.length > 0) {
        const lmsIds = remoteModels
          .filter((m) => !m.id.startsWith("text-embedding") && m.id.includes("/"))
          .map((m) => m.id);
        registerLmstudio(pi, remoteUrl, apiKey, lmsIds, "lmstudio-remote", "Remote");
        results.push(`Remote: ${lmsIds.length} model(s)`);
      }

      if (results.length === 0) {
        ctx.ui.notify(
          "No models found on local or remote servers.",
          "error"
        );
        return;
      }

      ctx.ui.notify(
        `Refreshed: ${results.join(", ")}. Use /model to select.`,
        "success"
      );
    },
  });
}
