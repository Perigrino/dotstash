#!/usr/bin/env node

const { Command } = require("commander");
const path = require("path");
const {
  stash,
  link,
  linkAll,
  list,
  remove,
  status,
  diff,
  exportStash,
  importStash,
} = require("../lib/dotstash");

const program = new Command();

program
  .name("dotstash")
  .description("📦 Dotstash — a smart dotfiles manager")
  .version("2.0.0");

// ── add ──────────────────────────────────────────
program
  .command("add <file>")
  .description("Stash a dotfile from your home directory")
  .action((file) => {
    console.log("\n  📦 Stashing dotfile...\n");
    stash(file);
  });

// ── list ─────────────────────────────────────────
program
  .command("list")
  .alias("ls")
  .description("List all stashed dotfiles")
  .action(() => {
    console.log("");
    list();
  });

// ── link ─────────────────────────────────────────
program
  .command("link [name]")
  .description("Symlink a stashed dotfile (or all if no name given)")
  .option("-f, --force", "Overwrite modified files (dangerous!)")
  .action((name, options) => {
    console.log("\n  🔗 Creating symlinks...\n");
    if (name) {
      link(name, options.force);
    } else {
      linkAll(options.force);
    }
  });

// ── diff ─────────────────────────────────────────
program
  .command("diff <name>")
  .description("Show differences between stashed and live versions")
  .action((name) => {
    console.log("");
    diff(name);
  });

// ── remove ───────────────────────────────────────
program
  .command("remove <name>")
  .alias("rm")
  .description("Untrack a dotfile")
  .option("-d, --delete", "Also delete the stashed copy")
  .action((name, options) => {
    console.log("");
    remove(name, options.delete);
  });

// ── status ───────────────────────────────────────
program
  .command("status")
  .alias("st")
  .description("Check the health of your stashed dotfiles")
  .action(() => {
    console.log("");
    status();
  });

// ── export ─────────────────────────────────────
program
  .command("export")
  .description("Export all stashed dotfiles to a tarball on Desktop")
  .action(() => {
    console.log("");
    exportStash();
  });

// ── import ─────────────────────────────────────
program
  .command("import <archive>")
  .description("Import dotfiles from a tarball")
  .action((archive) => {
    console.log("");
    importStash(archive);
  });

// ── Parse ────────────────────────────────────────
program.parse();
