# Playbook: How to Iterate OpenSCAD Designs

*Status: Draft*

## Objective
Provide a repeatable local workflow to iterate OpenSCAD (`.scad`) prototypes, generate preview images and STL exports, and snapshot numbered design revisions with their parameter sets.

## Prerequisites
* OpenSCAD installed locally (Windows).
* Either:
  * `openscad` available on `PATH`, or
  * provide the full path to `openscad.exe` via `-OpenScadPath` (recommended; avoids PATH edits).
* Run commands from the repository root: `c:\Users\CJ\Documents\GitHub\DIY-Weather-Satellite-Uplink`.

## Step-by-Step Instructions

This repo follows an explicit iteration loop:

1. **Create a new revision folder (checkpoint)**
   * Start each chunk of work by snapshotting a new revision folder so you have a stable baseline to compare against.
   * Command (example):
     * `powershell -ExecutionPolicy Bypass -File scripts/scad_new_revision.ps1 -Design helical -BaseConfig cad/designs/helical/configs/rev_0003.json -OpenScadPath "C:\Program Files (x86)\OpenSCAD\openscad.exe"`
   * Expected:
     * A new folder like `cad/revisions/helical/rev_0002/`
     * `cad/revisions/helical/rev_0002/params.json`
     * `cad/revisions/helical/rev_0002/<part>.stl` and `<part>.png` (if OpenSCAD is available)

2. **Implement the specified design changes**
   * Edit `.scad` modules under `cad/designs/<design>/src/` (or configs under `cad/designs/<design>/configs/`) according to the requested change.

3. **Loop: build artifacts -> ask for feedback -> revise**
   1) Build outputs (scratch build to `cad/out/<design>/`):
      * `powershell -ExecutionPolicy Bypass -File scripts/scad_build.ps1 -Design helical -Config cad/designs/helical/configs/rev_0003.json -OpenScadPath "C:\Program Files (x86)\OpenSCAD\openscad.exe"`
   2) Ask the user to test/inspect results and provide feedback.
   3) Apply feedback and repeat Step 3 until the user is satisfied.

4. **Finalize and commit**
   * Follow `playbooks/how_to_commit_and_push_changes.md`:
     * review `git status -sb`
     * review diffs
     * propose commit message
     * commit only after explicit approval

## Notes
* Parameter files live in `cad/designs/<design>/configs/` (e.g., `cad/designs/helical/configs/rev_0003.json`).
* Configs should include a numeric `part_id` (Windows `-D` string quoting is fragile). The human-readable `part` field is optional/for convenience.
* Scratch outputs go into `cad/out/<design>/` (ignored by git).
* Revision outputs go into `cad/revisions/<design>/rev_000N/` (ignored by git); only `.scad` source and `cad/designs/<design>/configs/*.json` are committed.

## Verification
* Run a scratch build and confirm both `.stl` and `.png` are produced in `cad/out/<design>/`.
* Create a new revision snapshot and confirm a new revision folder contains `params.json`, `.stl`, and `.png`.

## Lifecycle Compliance
Prompt -> Plan (based on a known playbook) -> Request approval -> Execute -> Plan/playbook update -> Docs update -> Verification.

If inside a git repo:
* Review `git status -sb` and diffs.
* Suggest a commit message.
* Commit after completion (per `playbooks/how_to_commit_and_push_changes.md`).
