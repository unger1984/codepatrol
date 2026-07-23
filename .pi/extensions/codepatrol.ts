import { mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { homedir } from "node:os";
import { fileURLToPath } from "node:url";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const EXTREMELY_IMPORTANT_MARKER = "<EXTREMELY_IMPORTANT>";
const BOOTSTRAP_MARKER = "codepatrol:using-codepatrol bootstrap for pi";
const OWNERSHIP_MARKER = "x-codepatrol-managed: true";

const extensionDir = dirname(fileURLToPath(import.meta.url));
const packageRoot = resolve(extensionDir, "../..");
const skillsDir = resolve(packageRoot, "skills");
const bootstrapSkillPath = resolve(skillsDir, "using-codepatrol", "SKILL.md");
const ompAgentsSourceDir = resolve(packageRoot, "platforms", "omp-agents");
const ompAgentsTargetDir = resolve(homedir(), ".omp", "agent", "agents");

let cachedBootstrap: string | null | undefined;

export default function codepatrolPiExtension(pi: ExtensionAPI) {
  let injectBootstrap = true;

  pi.on("resources_discover", async () => ({
    skillPaths: [skillsDir],
  }));

  pi.on("session_start", async () => {
    injectBootstrap = true;
    syncManagedAgentsIfNeeded();
  });

  pi.on("session_compact", async () => {
    injectBootstrap = true;
  });

  pi.on("agent_end", async () => {
    injectBootstrap = false;
  });

  pi.on("context", async (event) => {
    if (!injectBootstrap) return;
    if (event.messages.some(messageContainsBootstrap)) return;

    const bootstrap = getBootstrapContent();
    if (!bootstrap) return;

    const bootstrapMessage = {
      role: "user" as const,
      content: [{ type: "text" as const, text: bootstrap }],
      timestamp: Date.now(),
    };

    const insertAt = firstNonCompactionSummaryIndex(event.messages);
    return {
      messages: [
        ...event.messages.slice(0, insertAt),
        bootstrapMessage,
        ...event.messages.slice(insertAt),
      ],
    };
  });
}

function syncManagedAgentsIfNeeded(): void {
  mkdirSync(ompAgentsTargetDir, { recursive: true });
  for (const name of readdirSync(ompAgentsSourceDir)) {
    const source = join(ompAgentsSourceDir, name);
    if (!statSync(source).isFile() || !name.endsWith(".md")) continue;

    const target = join(ompAgentsTargetDir, name);
    const next = `${OWNERSHIP_MARKER}\n${readFileSync(source, "utf8")}`;

    let current = "";
    try {
      current = readFileSync(target, "utf8");
    } catch {
      current = "";
    }

    if (current && !current.includes(OWNERSHIP_MARKER)) continue;
    writeFileSync(target, next);
  }
}

function getBootstrapContent(): string | null {
  if (cachedBootstrap !== undefined) return cachedBootstrap;

  try {
    const skillContent = readFileSync(bootstrapSkillPath, "utf8");
    const body = stripFrontmatter(skillContent);
    cachedBootstrap = `${EXTREMELY_IMPORTANT_MARKER}\n${BOOTSTRAP_MARKER}\n\nYou have CodePatrol.\n\nThe using-codepatrol skill content is included below and is already loaded for this Pi session. Follow it now. Do not try to load using-codepatrol again.\n\n${body}\n</EXTREMELY_IMPORTANT>`;
    return cachedBootstrap;
  } catch {
    cachedBootstrap = null;
    return null;
  }
}

function stripFrontmatter(content: string): string {
  const match = content.match(/^---\n[\s\S]*?\n---\n([\s\S]*)$/);
  return (match ? match[1] : content).trim();
}

function messageContainsBootstrap(message: unknown): boolean {
  if (!message || typeof message !== "object" || !("content" in message)) return false;
  const content = message.content;
  if (typeof content === "string") return content.includes(BOOTSTRAP_MARKER);
  if (!Array.isArray(content)) return false;
  return content.some((part) => {
    if (!part || typeof part !== "object") return false;
    if (!("type" in part) || part.type !== "text") return false;
    if (!("text" in part) || typeof part.text !== "string") return false;
    return part.text.includes(BOOTSTRAP_MARKER);
  });
}

function firstNonCompactionSummaryIndex(messages: unknown[]): number {
  let index = 0;
  while (index < messages.length) {
    const message = messages[index];
    if (!message || typeof message !== "object" || !("role" in message)) break;
    if (message.role !== "compactionSummary") break;
    index += 1;
  }
  return index;
}
