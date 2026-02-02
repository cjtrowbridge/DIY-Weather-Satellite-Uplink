# Playbook: How to Iterate OpenSCAD Designs

*Status: Draft*

## Objective
Provide a repeatable local workflow to iterate OpenSCAD (`.scad`) prototypes, generate preview images and STL exports, and snapshot numbered design revisions with their parameter sets.

## Prerequisites
* OpenSCAD installed locally (Windows).
* `openscad` available on `PATH` (so `openscad --version` works from PowerShell).
* Run commands from the repository root: `c:\Users\CJ\Documents\GitHub\DIY-Weather-Satellite-Uplink`.

## Step-by-Step Instructions

1. **Pick or create a parameter set**
   * Parameter files live in `cad/configs/`.
   * Example: `cad/configs/rev_0001.json`.

2. **Build to scratch output (`cad/out/`)**
   * Command:
     * `powershell -ExecutionPolicy Bypass -File scripts/scad_build.ps1 -Config cad/configs/rev_0001.json -PartName feed_mount -OutDir cad/out`
   * Expected:
     * `cad/out/feed_mount.stl`
     * `cad/out/feed_mount.png`
   * If it fails:
     * Run `openscad --version` to confirm OpenSCAD is installed and on `PATH`.
     * Ensure your config JSON is valid.

3. **Create a new revision snapshot (`cad/revisions/rev_000N/`)**
   * Command:
     * `powershell -ExecutionPolicy Bypass -File scripts/scad_new_revision.ps1 -BaseConfig cad/configs/rev_0001.json -PartName feed_mount`
   * Expected:
     * A new folder like `cad/revisions/rev_0002/`
     * `cad/revisions/rev_0002/params.json`
     * `cad/revisions/rev_0002/feed_mount.stl`
     * `cad/revisions/rev_0002/feed_mount.png`

4. **Iterate**
   * Edit `.scad` modules under `cad/src/`.
   * Update a config JSON under `cad/configs/`.
   * Re-run the build (Step 2) until it looks right.
   * Snapshot a new revision (Step 3) when you want a stable checkpoint.

## Verification
* Run a scratch build (Step 2) and confirm both `.stl` and `.png` are produced in `cad/out/`.
* Run `scripts/scad_new_revision.ps1` (Step 3) and confirm a new revision folder contains `params.json`, `.stl`, and `.png`.

## Lifecycle Compliance
Prompt -> Plan (based on a known playbook) -> Request approval -> Execute -> Plan/playbook update -> Docs update -> Verification.

If inside a git repo:
* Review `git status -sb` and diffs.
* Suggest a commit message.
* Commit after completion (per `playbooks/how_to_commit_and_push_changes.md`).
