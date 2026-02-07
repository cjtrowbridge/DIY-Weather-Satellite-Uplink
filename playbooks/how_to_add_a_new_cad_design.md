# Playbook: How to Add a New CAD Design

*Status: Draft*

## Objective
Add a new OpenSCAD design under `cad/designs/<design>/` with its own source tree and configs, while preserving the project's shared focus datum conventions and keeping documentation consistent.

## Prerequisites
* OpenSCAD installed locally (Windows).
* Either:
  * `openscad` available on `PATH`, or
  * provide the full path to `openscad.exe` via `-OpenScadPath`.
* Run commands from the repository root: `c:\Users\CJ\Documents\GitHub\DIY-Weather-Satellite-Uplink`.

## Step-by-Step Instructions

1. **Choose a design name**
   * Pick a short, descriptive folder name for `<design>` (e.g., `helical`, `yagi`).

2. **Preserve the shared mechanical datum**
   * All designs should use the same coordinate convention:
     * `z=0` is the **focus datum** (original plastic tube tip position).
     * The **mount seat plane** (metal post top) is at `z=-mount_seat_to_focus` (default `33mm`).
   * Any new design should explicitly document this in its `defaults.scad` and/or part modules.

3. **Create the design folder layout**
   * Create:
     * `cad/designs/<design>/src/main.scad`
     * `cad/designs/<design>/src/lib/defaults.scad`
     * `cad/designs/<design>/src/parts/<part>.scad`
     * `cad/designs/<design>/configs/rev_0001.json`
   * Keep `main.scad` as the scripted export entrypoint that selects a part via numeric `part_id`.

4. **Add at least one config**
   * Create `cad/designs/<design>/configs/rev_0001.json` with:
     * `part_id` (numeric) and an optional `part` string (used for output naming).
     * Any parameters needed by the design's `defaults.scad` / part modules.
   * Prefer numeric `part_id` (Windows `-D` string quoting is fragile).

5. **Update documentation**
   * Update `README.md`:
     * Add/adjust the OpenSCAD folder layout (multi-design structure).
     * Add the new design description and its invariants (especially the focus datum).
     * Add example build commands for the new design.
   * If the workflow changed, update `playbooks/how_to_iterate_openscad_designs.md`.
   * If you added/removed playbooks, update `AGENTS.md` playbook index.

6. **Verify**
   * Run a DryRun build (does not require OpenSCAD):
     * `powershell -ExecutionPolicy Bypass -File scripts/scad_build.ps1 -Design <design> -Config cad/designs/<design>/configs/rev_0001.json -DryRun`

7. **Finalize**
   * Follow `playbooks/how_to_commit_and_push_changes.md`:
     * review `git status -sb`
     * review diffs
     * propose commit message
     * commit only after explicit approval

## Verification
* `scripts/scad_build.ps1 -DryRun` resolves `MainScad` and prints both intended OpenSCAD commands without error.
* `README.md` and relevant playbooks reflect the new design and folder layout.

## Lifecycle Compliance
Prompt -> Plan (based on a known playbook) -> Request approval -> Execute -> Plan/playbook update -> Docs update -> Verification.

If inside a git repo:
* Review `git status -sb` and diffs.
* Suggest a commit message.
* Commit after completion.
