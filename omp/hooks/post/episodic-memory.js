import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { join } from "node:path";

// Wrapper from ~/dotfiles/bin; it selects a Node that better-sqlite3 supports.
const cli = join(homedir(), ".local", "bin", "episodic-memory");

function startSync() {
  return new Promise((resolve, reject) => {
    const child = spawn(cli, ["sync", "--background"], { stdio: "ignore" });
    child.once("error", reject);
    child.once("close", (code) => {
      if (code === 0) resolve();
      else reject(new Error(`Episodic Memory sync launcher exited ${code}`));
    });
  });
}

export default function episodicMemoryHook(pi) {
  const syncMainSession = async (_event, ctx) => {
    if (ctx.agent.kind === "main") await startSync();
  };

  pi.on("session_start", syncMainSession);
  pi.on("session_shutdown", syncMainSession);
}
