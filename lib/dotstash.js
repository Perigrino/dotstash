const fs = require("fs");
const path = require("path");
const os = require("os");
const crypto = require("crypto");

// The stash lives at ~/.dotstash by default
const STASH_DIR = path.join(os.homedir(), ".dotstash");
const CONFIG_FILE = path.join(STASH_DIR, "dotstash.json");

// ── Helpers ────────────────────────────────────────────────

function ensureStashDir() {
  if (!fs.existsSync(STASH_DIR)) {
    fs.mkdirSync(STASH_DIR, { recursive: true });
    console.log(`  📁 Created stash directory: ${STASH_DIR}`);
  }
}

function loadConfig() {
  ensureStashDir();
  if (!fs.existsSync(CONFIG_FILE)) {
    return { dotfiles: {}, created: new Date().toISOString(), version: 2 };
  }
  const config = JSON.parse(fs.readFileSync(CONFIG_FILE, "utf-8"));
  // Migrate v1 configs
  if (!config.version) config.version = 2;
  return config;
}

function saveConfig(config) {
  ensureStashDir();
  config.version = 2;
  fs.writeFileSync(CONFIG_FILE, JSON.stringify(config, null, 2));
}

/**
 * Create a unique stash key from the source path.
 * Avoids basename collisions: ~/.zshrc and ~/.config/nvim/init.vim
 * get unique names like "home-zshrc" and "home-config-nvim-init.vim"
 */
function stashKey(sourcePath) {
  const home = os.homedir();
  let relative = sourcePath.startsWith(home)
    ? sourcePath.slice(home.length + 1)
    : sourcePath;
  // Replace path separators with dashes, strip leading dots
  return relative.replace(/\//g, "-").replace(/^\.+/, "") || "root";
}

/**
 * Compute a simple content hash for drift detection.
 */
function contentHash(filePath) {
  if (!fs.existsSync(filePath)) return null;
  const data = fs.readFileSync(filePath);
  return crypto.createHash("sha256").update(data).digest("hex").slice(0, 16);
}

/**
 * Check if a file has drifted from its stashed version.
 * Returns { drifted: boolean, reason: string }
 */
function checkDrift(entry) {
  const targetExists = fs.existsSync(entry.source);
  const stashedExists = fs.existsSync(entry.stashed);

  if (!stashedExists) {
    return { drifted: true, reason: "stashed copy is missing" };
  }

  if (!targetExists) {
    return { drifted: false, reason: "target does not exist yet" };
  }

  // If target is already a symlink to our stash, no drift
  const stat = fs.lstatSync(entry.source);
  if (stat.isSymbolicLink()) {
    const linkTarget = fs.readlinkSync(entry.source);
    if (path.resolve(linkTarget) === path.resolve(entry.stashed)) {
      return { drifted: false, reason: "already linked" };
    }
  }

  // Compare content hashes
  const currentHash = contentHash(entry.source);
  const stashedHash = contentHash(entry.stashed);

  if (currentHash !== stashedHash) {
    return {
      drifted: true,
      reason: "file has been modified since last stash",
      currentHash,
      stashedHash,
    };
  }

  return { drifted: false, reason: "content is identical" };
}

// ── Core Commands ──────────────────────────────────────────

/**
 * Stash: copy a dotfile from home into the stash
 * Uses namespaced paths to avoid basename collisions.
 */
function stash(sourcePath) {
  const home = os.homedir();
  const fullPath = path.isAbsolute(sourcePath)
    ? sourcePath
    : path.join(home, sourcePath);

  // Validate source exists
  if (!fs.existsSync(fullPath)) {
    console.error(`  ❌ Source not found: ${fullPath}`);
    return false;
  }

  const key = stashKey(fullPath);
  const basename = path.basename(fullPath);
  const isDir = fs.statSync(fullPath).isDirectory();

  // Create namespaced stash path
  const stashedPath = path.join(STASH_DIR, key);

  // Ensure parent dirs exist for nested paths
  const stashedParent = path.dirname(stashedPath);
  if (!fs.existsSync(stashedParent)) {
    fs.mkdirSync(stashedParent, { recursive: true });
  }

  // Remove existing stashed copy if present
  if (fs.existsSync(stashedPath)) {
    fs.rmSync(stashedPath, { recursive: true });
  }

  // Copy file or directory into stash
  if (isDir) {
    fs.cpSync(fullPath, stashedPath, { recursive: true });
  } else {
    fs.copyFileSync(fullPath, stashedPath);
  }

  // Update config
  const config = loadConfig();
  config.dotfiles[key] = {
    source: fullPath,
    stashed: stashedPath,
    basename: basename,
    stashedAt: new Date().toISOString(),
    lastSyncedAt: new Date().toISOString(),
    isDirectory: isDir,
    hash: contentHash(fullPath),
  };
  saveConfig(config);

  console.log(`  ✅ Stashed: ${basename}`);
  console.log(`     ${fullPath} → ${stashedPath}`);
  return true;
}

/**
 * Link: create a symlink from the stash back into home
 * SAFETY: Refuses to overwrite modified files unless --force is passed.
 */
/**
 * Find an entry by key, basename, or source path.
 */
function findEntry(config, name) {
  // Direct key match
  if (config.dotfiles[name]) return { key: name, entry: config.dotfiles[name] };
  
  // Basename match
  for (const [key, entry] of Object.entries(config.dotfiles)) {
    if (entry.basename === name || entry.basename === "." + name) {
      return { key, entry };
    }
  }
  
  // Source path match
  const home = os.homedir();
  const fullPath = path.isAbsolute(name) ? name : path.join(home, name);
  for (const [key, entry] of Object.entries(config.dotfiles)) {
    if (entry.source === fullPath) return { key, entry };
  }
  
  return null;
}

function link(name, force = false) {
  const config = loadConfig();
  const found = findEntry(config, name);
  
  if (!found) {
    console.error(`  ❌ "${name}" is not tracked by Dotstash.`);
    console.error(`     Run "dotstash list" to see tracked files.`);
    return false;
  }
  
  const { key, entry } = found;

  const targetPath = entry.source;
  const stashedPath = entry.stashed;

  if (!fs.existsSync(stashedPath)) {
    console.error(`  ❌ Stashed file missing: ${stashedPath}`);
    return false;
  }

  // SAFETY CHECK: Detect drift before overwriting
  if (fs.existsSync(targetPath) && !fs.lstatSync(targetPath).isSymbolicLink()) {
    const drift = checkDrift(entry);

    if (drift.drifted) {
      if (!force) {
        console.error(`  ⚠️  REFUSED: ${entry.basename} has been modified since last stash.`);
        console.error(`     ${drift.reason}`);
        console.error(``);
        console.error(`     Options:`);
        console.error(`       1. Re-stash the current version:  dotstash add ${entry.source}`);
        console.error(`       2. Force overwrite with stashed:  dotstash link ${name} --force`);
        console.error(`       3. View differences:              dotstash diff ${name}`);
        return false;
      } else {
        console.log(`  ⚠️  Force mode: overwriting modified file.`);
      }
    }
  }

  // Remove existing file/dir at target if present
  if (fs.existsSync(targetPath)) {
    const stat = fs.lstatSync(targetPath);
    if (stat.isSymbolicLink()) {
      fs.unlinkSync(targetPath);
    } else if (stat.isDirectory()) {
      fs.rmSync(targetPath, { recursive: true });
    } else {
      fs.unlinkSync(targetPath);
    }
  }

  // Create symlink
  fs.symlinkSync(stashedPath, targetPath);

  // Update last synced time
  entry.lastSyncedAt = new Date().toISOString();
  entry.hash = contentHash(stashedPath);
  config.dotfiles[key] = entry;
  saveConfig(config);

  console.log(`  🔗 Linked: ${targetPath} → ${stashedPath}`);
  return true;
}

/**
 * Link All: symlink all tracked dotfiles
 */
function linkAll(force = false) {
  const config = loadConfig();
  const names = Object.keys(config.dotfiles);

  if (names.length === 0) {
    console.log('  📭 No dotfiles tracked yet. Use "dotstash add <file>" first.');
    return;
  }

  console.log(`  🔗 Linking ${names.length} dotfile(s)...\n`);
  let successCount = 0;
  let refusedCount = 0;

  for (const name of names) {
    const result = link(name, force);
    if (result) successCount++;
    else refusedCount++;
  }

  console.log(`\n  ✨ Done! ${successCount}/${names.length} linked successfully.`);
  if (refusedCount > 0) {
    console.log(`  ⚠️  ${refusedCount} file(s) refused (drift detected). Use --force to override.`);
  }
}

/**
 * Diff: show differences between stashed and live versions
 */
function diff(name) {
  const { execSync } = require("child_process");
  const config = loadConfig();
  const found = findEntry(config, name);

  if (!found) {
    console.error(`  ❌ "${name}" is not tracked by Dotstash.`);
    return false;
  }
  
  const { entry } = found;

  if (!fs.existsSync(entry.stashed)) {
    console.error(`  ❌ Stashed file missing: ${entry.stashed}`);
    return false;
  }

  if (!fs.existsSync(entry.source)) {
    console.log(`  ℹ️  Target file does not exist yet.`);
    console.log(`     Stashed version: ${entry.stashed}`);
    return true;
  }

  // Check if it's a symlink
  if (fs.lstatSync(entry.source).isSymbolicLink()) {
    console.log(`  ℹ️  Target is already symlinked to stash.`);
    return true;
  }

  // Run diff
  try {
    const result = execSync(
      `diff --color=always "${entry.stashed}" "${entry.source}" || true`,
      { encoding: "utf-8", stdio: ["pipe", "pipe", "pipe"] }
    );

    if (result.trim() === "") {
      console.log(`  ✅ ${entry.basename} — files are identical`);
    } else {
      console.log(`  📊 Diff for ${entry.basename}:\n`);
      console.log(`  --- stashed (${entry.stashed})`);
      console.log(`  +++ live    (${entry.source})\n`);
      console.log(result);
    }
    return true;
  } catch (error) {
    console.error(`  ❌ Diff failed: ${error.message}`);
    return false;
  }
}

/**
 * List: show all stashed dotfiles
 */
function list() {
  const config = loadConfig();
  const entries = Object.entries(config.dotfiles);

  if (entries.length === 0) {
    console.log("  📭 No dotfiles stashed yet.");
    console.log('     Run "dotstash add <file>" to get started.');
    return;
  }

  console.log(`  📦 Stashed dotfiles (${entries.length}):\n`);

  for (const [key, info] of entries) {
    const exists = fs.existsSync(info.stashed);
    const icon = exists ? "✅" : "⚠️ ";
    const linked =
      fs.existsSync(info.source) && fs.lstatSync(info.source).isSymbolicLink();
    const linkBadge = linked ? " 🔗" : "";

    console.log(`    ${icon} ${info.basename}${linkBadge}`);
    console.log(`       Source:  ${info.source}`);
    console.log(`       Stashed: ${info.stashed}`);
    console.log(`       Type:    ${info.isDirectory ? "directory" : "file"}`);
    console.log(`       Added:   ${info.stashedAt}`);
    console.log("");
  }
}

/**
 * Remove: untrack a dotfile (optionally delete from stash)
 */
function remove(name, deleteFromStash = false) {
  const config = loadConfig();
  const found = findEntry(config, name);

  if (!found) {
    console.error(`  ❌ "${name}" is not tracked by Dotstash.`);
    return false;
  }
  
  const { key, entry } = found;

  // Optionally remove the stashed copy
  if (deleteFromStash && fs.existsSync(entry.stashed)) {
    if (entry.isDirectory) {
      fs.rmSync(entry.stashed, { recursive: true });
    } else {
      fs.unlinkSync(entry.stashed);
    }
    console.log(`  🗑️  Deleted from stash: ${entry.stashed}`);
  }

  // Untrack it
  delete config.dotfiles[key];
  saveConfig(config);

  console.log(`  ✅ Untracked: ${entry.basename}`);
  return true;
}

/**
 * Status: show which dotfiles need attention
 */
function status() {
  const config = loadConfig();
  const entries = Object.entries(config.dotfiles);

  if (entries.length === 0) {
    console.log('  📭 Nothing tracked. Start with "dotstash add <file>".');
    return;
  }

  console.log("  📊 Dotstash Status:\n");

  let needsAttention = 0;

  for (const [key, info] of entries) {
    const stashedExists = fs.existsSync(info.stashed);
    const targetExists = fs.existsSync(info.source);
    const isLinked =
      targetExists && fs.lstatSync(info.source).isSymbolicLink();

    if (!stashedExists) {
      console.log(`  ⚠️  ${info.basename} — stashed copy is missing!`);
      needsAttention++;
    } else if (!targetExists) {
      console.log(`  ⚠️  ${info.basename} — missing from home directory`);
      needsAttention++;
    } else if (!isLinked) {
      const drift = checkDrift(info);
      if (drift.drifted) {
        console.log(`  🔴 ${info.basename} — MODIFIED since last stash (drift!)`);
      } else {
        console.log(`  ⚡ ${info.basename} — exists but is NOT symlinked`);
      }
      needsAttention++;
    } else {
      console.log(`  ✅ ${info.basename} — linked and up to date`);
    }
  }

  console.log("");
  if (needsAttention === 0) {
    console.log("  ✨ Everything looks good!");
  } else {
    console.log(`  ℹ️  ${needsAttention} item(s) need attention.`);
  }
}

module.exports.findEntry = findEntry;
module.exports = {
  stash,
  link,
  linkAll,
  list,
  remove,
  status,
  diff,
  checkDrift,
  contentHash,
  stashKey,
  STASH_DIR,
  CONFIG_FILE,
};

/**
 * Export: bundle all stashed dotfiles into a tarball
 */
function exportStash() {
  const { execSync } = require("child_process");
  const timestamp = new Date().toISOString().replace(/:/g, "-");
  const exportName = `dotstash-export-${timestamp}.tar.gz`;
  const exportPath = `${os.homedir()}/Desktop/${exportName}`;

  try {
    execSync(`tar -czf "${exportPath}" -C "${STASH_DIR}" .`, {
      stdio: "pipe",
    });
    console.log(`\n  📦 Exported to: ~/Desktop/${exportName}`);
    console.log(
      `     Contains ${Object.keys(loadConfig().dotfiles).length} dotfile(s)\n`
    );
    return exportPath;
  } catch (error) {
    console.error(`  ❌ Export failed: ${error.message}`);
    return null;
  }
}

/**
 * Import: extract a tarball into the stash
 */
function importStash(archivePath) {
  const { execSync } = require("child_process");

  if (!fs.existsSync(archivePath)) {
    console.error(`  ❌ Archive not found: ${archivePath}`);
    return false;
  }

  const tempDir = path.join(
    os.tmpdir(),
    `dotstash-import-${Date.now()}`
  );

  try {
    // Create temp dir and extract
    fs.mkdirSync(tempDir, { recursive: true });
    execSync(`tar -xzf "${archivePath}" -C "${tempDir}"`, { stdio: "pipe" });

    // Read extracted files
    const files = fs
      .readdirSync(tempDir)
      .filter((f) => f !== "dotstash.json");

    let imported = 0;
    for (const file of files) {
      const srcPath = path.join(tempDir, file);
      const dstPath = path.join(STASH_DIR, file);

      // Remove existing if present
      if (fs.existsSync(dstPath)) {
        fs.rmSync(dstPath, { recursive: true });
      }

      fs.cpSync(srcPath, dstPath);
      imported++;
    }

    // Clean up
    fs.rmSync(tempDir, { recursive: true });

    // Reload config
    const config = loadConfig();
    for (const file of files) {
      const fullPath = path.join(STASH_DIR, file);
      const isDir = fs.statSync(fullPath).isDirectory();
      config.dotfiles[file] = {
        source: path.join(os.homedir(), file),
        stashed: fullPath,
        basename: file,
        stashedAt: new Date().toISOString(),
        lastSyncedAt: new Date().toISOString(),
        isDirectory: isDir,
        hash: contentHash(fullPath),
      };
    }
    saveConfig(config);

    console.log(`\n  📥 Imported ${imported} file(s) from archive\n`);
    return true;
  } catch (error) {
    console.error(`  ❌ Import failed: ${error.message}`);
    try {
      fs.rmSync(tempDir, { recursive: true });
    } catch {}
    return false;
  }
}

module.exports.exportStash = exportStash;
module.exports.importStash = importStash;
