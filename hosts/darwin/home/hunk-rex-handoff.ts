/**
 * Rex handoff: press ctrl+g in Hunk to send the review notes you wrote as one
 * prompt to a Rex pane. The prompt is staged, not submitted, so you can add
 * context before pressing enter.
 *
 * Inert unless the review was launched with REX_AGENT_BLOCK set, so ordinary
 * `hunk diff` sessions behave exactly as before.
 *
 *   REX_AGENT_BLOCK="$REX_BLOCK" hunk --extension ~/.config/hunk/extensions/rex-handoff.ts diff
 */
import { spawn } from "node:child_process";
import { appendFileSync, existsSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import type {
  ExtensionReviewSnapshot,
  ExtensionReviewSnapshotNote,
  HunkExtensionAPI,
} from "hunkdiff/extension";

const LOG = join(homedir(), ".cache", "hunk-rex-handoff.log");
const SEND_KEY = "ctrl+g";

function log(line: string) {
  try {
    appendFileSync(LOG, `${new Date().toISOString()} ${line}\n`);
  } catch {
    // Logging is best-effort; never break the review over it.
  }
}

// Rex spawns panes with the login shell environment, which may not include
// the app bundle's CLI. Prefer an explicit path, then PATH, then the usual
// macOS install location.
function rexBinary(): string {
  const explicit = process.env.REX_BIN?.trim();
  if (explicit) return explicit;
  const app = join(
    homedir(),
    "Library/Application Support/com.superlogical.rex/RexServer/Versions/Current/Rex Server.app/Contents/MacOS/rex",
  );
  return existsSync(app) ? app : "rex";
}

function sendText(session: string, block: string, text: string): Promise<boolean> {
  return new Promise((resolve) => {
    const child = spawn(rexBinary(), ["send", "-s", session, "-b", block, text], {
      stdio: ["ignore", "ignore", "pipe"],
    });
    let stderr = "";
    child.stderr?.on("data", (chunk) => {
      stderr += String(chunk);
    });
    child.on("error", (error) => {
      log(`rex send failed to start: ${error.message}`);
      resolve(false);
    });
    child.on("close", (code) => {
      if (code !== 0) log(`rex send exited ${code}: ${stderr.trim()}`);
      resolve(code === 0);
    });
  });
}

function pathsById(snapshot: ExtensionReviewSnapshot): Map<string, string> {
  return new Map(snapshot.files.map((file) => [file.fileKey, file.path]));
}

function anchorOf(note: ExtensionReviewSnapshotNote): string {
  const range = note.anchor.newRange ?? note.anchor.oldRange;
  if (range) {
    return range[1] > range[0] ? `${range[0]}-${range[1]}` : String(range[0]);
  }
  return note.anchor.preferred?.line === undefined ? "" : String(note.anchor.preferred.line);
}

function formatNote(note: ExtensionReviewSnapshotNote, path: string | undefined): string {
  const at = anchorOf(note);
  const where = `${path ?? note.fileKey}${at === "" ? "" : `:${at}`}`;
  const body = note.summary.replace(/\s+/g, " ").trim();
  return `- ${where} — ${body}`;
}

export default function rexHandoff(hunk: HunkExtensionAPI) {
  const session = process.env.REX_SESSION;
  const block = process.env.REX_AGENT_BLOCK;
  if (!session || !block) return;

  const sent = new Set<string>();
  let queued = 0;

  const sendReview = async (ctx: {
    review: { snapshot(): ExtensionReviewSnapshot | null };
    notify(message: string): void;
  }) => {
    const snapshot = ctx.review.snapshot();
    if (!snapshot) {
      ctx.notify("The current review is unavailable");
      return;
    }

    const paths = pathsById(snapshot);
    const notes = snapshot.notes.filter((note) => note.source === "user" && !sent.has(note.id));
    if (notes.length === 0) {
      ctx.notify("No unsent review notes");
      return;
    }

    const text = ["Hunk review notes:", ...notes.map((note) => formatNote(note, paths.get(note.fileKey)))].join(
      "\n",
    );

    log(`sending ${notes.length} note(s) to ${session} ${block}`);
    const ok = await sendText(session, block, text);
    if (!ok) {
      ctx.notify("Could not reach the agent pane; see ~/.cache/hunk-rex-handoff.log");
      return;
    }

    for (const note of notes) sent.add(note.id);
    queued = 0;
    ctx.notify(`Sent ${notes.length} note${notes.length === 1 ? "" : "s"} to the agent`);
  };

  hunk.registerCommand(
    { id: "send-review", title: "Send review notes to the agent", key: SEND_KEY },
    (ctx) => sendReview(ctx),
  );

  hunk.on("note_created", (_event, ctx) => {
    queued += 1;
    ctx.notify(`${queued} review note${queued === 1 ? "" : "s"} queued — ${SEND_KEY} sends to the agent`);
  });
}
