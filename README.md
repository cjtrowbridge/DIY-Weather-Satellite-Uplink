# DIY Weather Satellite Uplink: Project Overview
Hacking an old robotic RV satellite dish to access weather data from GOES West

This document describes a retrofit project that converts an RV “in‑motion” dome satellite TV dish (a small robotic parabolic reflector under a plastic radome) into a **GOES HRIT/EMWIN ground station**. The core idea is:

* Replace the Ku‑band TV feed/LNB electronics with a purpose‑built **L‑band receive feed** for **1694.1 MHz HRIT/EMWIN**.
* Put the **LNA + SAW filter** (Nooelec SAWbird GOES) as close to the feed as possible to minimize pre‑LNA coax loss.
* Optionally replace the dish’s original motor controller with an **ESP32** (or keep the existing mechanics and drive them) to automate pointing.
* Use a **Raspberry Pi** (mounted behind the reflector) to host the **RTL‑SDR**, run the demod/decoder, and publish imagery locally.

The end state is a compact, self‑contained receiver package inside the radome:

> **Helical feed → very short SMA jumper → SAWbird GOES (shielded) → coax/SMA → RTL‑SDR → USB → Raspberry Pi**

---

# Background: GOES‑18 “GOES West” and What We’re Receiving

## GOES‑18 operational role

* **GOES‑18** became the operational **GOES‑West** satellite on **Jan 4, 2023**.
* GOES‑West is stationed around **137° W longitude**.

## HRIT/EMWIN vs other GOES downlinks (high level)

GOES satellites distribute data using multiple services. For hobbyist/low‑cost reception, the key one is:

* **HRIT/EMWIN** (High Rate Information Transmission / Emergency Manager’s Weather Information Network)

HRIT/EMWIN is designed to be receivable with modest ground equipment compared to higher‑end services like **GRB** (GOES Rebroadcast). For this project we focus on **HRIT/EMWIN**.

## HRIT/EMWIN RF characteristics (what the antenna must match)

The HRIT/EMWIN L‑band downlink is characterized by:

* **Center frequency:** 1694.1 MHz
* **Data rate:** 400 kbps
* **Symbol rate:** 927 ksps
* **Modulation:** BPSK
* **Polarization:** Linear (vertical offset)

This polarization point matters: the satellite signal is **linearly polarized**, not circular. A helical antenna naturally produces circular polarization in axial mode; however, when you place a helix at the focus of a dish you can (a) accept some mismatch, (b) orient and design for best coupling, and (c) experiment with polarization conversion if needed. In practice, many successful hobbyist HRIT setups use simple feeds (including helices) with strong LNAs and careful mechanical alignment.

## Broadcast format (what the software will decode)

* The HRIT/EMWIN broadcast is formed according to the **HRIT/LRIT standard** and **CCSDS** framing conventions.
* The stream is broadcast as a continuous downlink; the receiver software demodulates BPSK, applies FEC, reconstructs files, then extracts images/products.

---

# System Architecture Summary

## Why the project is viable

At 1.694 GHz, losses in coax before the first amplifier materially hurt SNR. The primary optimization is:

* **Put the first low‑noise gain stage at the feed** (or as close as physically possible).

Your chosen LNA/filter module (Nooelec SAWbird GOES) already provides:

* A **metal enclosure** (shielding)
* Cascaded ultra‑low noise gain stages
* An integrated **SAW filter** centered near the HRIT band

That means the biggest remaining engineering concerns are:

* Mechanical: feed placement at the dish focus
* RF hygiene: cable routing, common‑mode suppression, clean power
* Control: optional repointing automation

---

# The Existing RV Dome Dish System (What It Is)

## Mechanical components

* **Plastic radome** (weather protection; not a Faraday cage)
* **Small parabolic reflector** (≈ 16" class in many RV domes; confirm with measurement)
* **Robotic pointing mechanism**: motors, gears, and position feedback (often via potentiometers)

## RF components (Ku‑band TV)

* A Ku‑band feed/LNB assembly intended for ~10–12 GHz satellite TV.
* One or more coax outputs for RV TV distribution.

## What must change

Everything Ku‑band RF becomes irrelevant for 1.694 GHz:

* Remove the Ku feed/LNB and any internal switching/power injection that served it.
* Keep and reuse: **reflector + mechanical mount points + motorized pointing platform**.

---

# Helical Antenna Design: Geometry, Modes, and Formulas

## Key parameters (pure geometry)

A helical antenna is a wire wound around an imaginary cylinder.

* **D** = helix diameter
* **C** = circumference = πD
* **S** = turn spacing (axial spacing per turn)
* **N** = number of turns
* **L** = total helix length = N·S
* **α** = pitch angle

Pitch angle relationship:

[ \tan(\alpha) = \frac{S}{C} = \frac{S}{\pi D} ]

Wire length per turn (useful for cut length):

[ \ell_{turn} = \sqrt{C^2 + S^2} ]

Total wire length:

[ \ell_{total} = N \cdot \ell_{turn} ]

## Wavelength scaling

For a frequency ( f ):

[ \lambda = \frac{c}{f} ]

For **f = 1.6941 GHz**:

* ( \lambda \approx 0.17696,m = 17.696,cm )

## Two operating regimes

### 1) Normal mode (small helix)

* Diameter and circumference are small relative to (\lambda)
* Pattern is broad; gain is low; behaves like a bent dipole.

### 2) Axial mode (classic satellite helix)

* Radiates along the helix axis
* Produces (near) **circular polarization**
* Provides gain that increases with turns

Axial mode rules of thumb:

* **Circumference:** ( C \approx \lambda )
* **Diameter:** ( D \approx \lambda/\pi )
* **Spacing:** ( S \approx 0.23\lambda;\text{to};0.27\lambda ) (often 0.25λ)
* **Pitch angle:** typically 12°–15°

## Numerical geometry at 1.6941 GHz (axial-mode baseline)

Using (\lambda \approx 17.696,cm):

* ( C \approx 17.696,cm )
* ( D = C/\pi \approx 5.63,cm = 56.3,mm )
* ( S = 0.25\lambda \approx 4.42,cm = 44.2,mm )
* ( \alpha \approx \arctan(0.25) \approx 14.0^\circ )

These are excellent “starting geometry” dimensions for a helix that behaves predictably.

## Number of turns as a feed (beamwidth vs gain)

When used as a **dish feed**, you typically want a wider pattern than a long, high‑gain helix. A short helix (1–3 turns) often works better as a feed.

A commonly used approximation for axial-mode half‑power beamwidth (HPBW):

[ \text{HPBW} \approx \frac{52}{(C/\lambda)\sqrt{N(S/\lambda)}} ;\text{degrees} ]

With (C/\lambda \approx 1) and (S/\lambda \approx 0.25):

[ \text{HPBW} \approx \frac{104}{\sqrt{N}} ]

So:

* N=1 → ~104°
* N=2 → ~74°
* N=3 → ~60°
* N=4 → ~52°

**Practical feed starting point:** **N = 2 turns**

* Height (L = N\cdot S \approx 2 \cdot 44.2,mm = 88.4,mm) (~3.5")

## Ground reference (why “multiple elements” often connect to coax shield)

A helix is an **unbalanced** radiator in most practical builds:

* Coax **center conductor** feeds the helix start
* Coax **shield** bonds to a **ground plane** / reflector / radials

Many compact L‑band helices use **3 radials** (120° apart) instead of a large disk. Those radials are tied to the **coax shield**, and they are often the “extra elements” people notice.

---

# Dish Optics: Focus, Placement, and Why Measurements Matter

To place any feed correctly, you want the feed phase center at the dish’s focal region.

## Focal length from dish diameter and depth

If you measure:

* (D) = dish diameter
* (d) = dish depth (sagitta): distance from rim plane to deepest point

Then the focal length (f) for a parabola is:

[ f = \frac{D^2}{16d} ]

This single measurement lets you:

* compute (f/D)
* estimate required feed beamwidth (illumination)
* place the feed consistently

**Action:** measure dish depth (d) and confirm dish diameter (D).

---

# New RF Receive Pipeline (Target Design)

## Hardware chain

1. **Helical feed** at the dish focus
2. **Very short SMA jumper** (as short as practical)
3. **Nooelec SAWbird GOES** (shielded enclosure)
4. SMA/coax to **RTL‑SDR**
5. **USB** to Raspberry Pi

## Powering the SAWbird

The SAWbird can be powered via:

* bias tee
* micro‑USB
* DC barrel

For low noise, prefer:

* a clean local 5V feed with filtering near the SAWbird, or
* bias tee if your SDR chain supports it cleanly.

## EMI / self-noise control (even with a shielded LNA)

A plastic radome does not block RF. The reflector helps, but you still want hygiene:

* Keep the SAWbird close to the feed; keep Pi farther away.
* Add clamp ferrites on:

  * USB cable
  * any long power lead
  * coax if it runs near digital electronics
* Provide a deliberate local RF ground reference (feed ground plane/radials), not a “floating” coax shield in space.

## Software chain (conceptual)

* SDR capture (IQ)
* BPSK demod + symbol recovery
* FEC decode
* HRIT file reconstruction
* Image/product extraction and publishing

(Exact tool choice is flexible: common approaches include goestools/xrit decoders or general satellite decoders such as SatDump.)

---

# Control System Options (Pointing)

## Option A: keep existing motors, replace controller

* Remove original control PCB.
* Drive motors with an **ESP32 + motor drivers**.
* Read position sensors (potentiometers/encoders).
* Provide a serial/API interface to the Raspberry Pi.

## Option B: direct Pi motor control (simpler but less real-time)

* Pi drives motor drivers directly.
* Pi reads sensors.
* More software complexity in Linux; may be fine if you only occasionally reposition.

## Pointing notes

* HRIT/EMWIN is geostationary: once aimed, the dish can remain fixed.
* Automation mainly helps initial acquisition and re‑acquisition.

---

# Designing the 3D‑Printed Helix Former (Cylinder with Groove)

## Design goals

* Make the helix geometry **repeatable** and resistant to bending/creep.
* Provide mounts for:

  * feedpoint SMA bulkhead (or coax pigtail strain relief)
  * ground radials / ground disk
  * SAWbird GOES enclosure
  * cable routing + ferrite placement
* Fit within the radome with adequate clearance.

## Baseline helix dimensions (from frequency)

Using f = 1.6941 GHz:

* Helix diameter: **D = 56.3 mm**
* Radius: **R = 28.15 mm**
* Spacing per turn: **S = 44.2 mm**
* Turns for dish feed start: **N = 2**
* Helix height: **H = N·S = 88.4 mm**

## Helix centerline parameterization (for CAD)

Let (t) run from (0) to (2\pi N):

[
\begin{aligned}
x(t) &= R\cos(t)\
y(t) &= R\sin(t)\
z(t) &= \frac{S}{2\pi}t
\end{aligned}
]

This curve is the **ideal centerline** of the wire.

## Groove design (printable, “foolproof” winding)

Choose a wire diameter (d_w) (example: 12–14 AWG solid copper, or similar).

Recommended groove geometry:

* Groove width: (w \approx d_w + 0.4\text{ to }0.8,mm)
* Groove depth: (h \approx 0.4\text{ to }0.6,d_w)

Add retention features:

* Small “snap tabs” or tie points every 1/2 turn
* Optional end clamps at start and top

## Former body geometry

* Outer cylinder diameter: slightly larger than helix diameter to allow a groove wall.
* A practical approach:

  * Set cylinder OD to ~60–65 mm
  * Groove centerline radius ~28.15 mm
  * Groove cut into the cylinder wall

## Feedpoint region design

At the base:

* Provide a flat mounting face for:

  * SMA bulkhead connector (preferred for repeatability)
  * or a coax pigtail with strain relief

Electrical intent:

* SMA center pin → helix start
* SMA ground → ground plane / radials

## Ground plane / radials integration

Two common printable-friendly options:

### Option 1: 3 radial slots

* Provide 3 slots spaced 120° around the base.
* Radial length target: **50–60 mm** (roughly 0.28–0.34λ)
* Optional downward angle: 10–30°

### Option 2: ground disk mount

* Provide holes for a circular metal disk (80–120 mm diameter depending on space).
* Bond disk to SMA ground.

## Mounting to the dish assembly

Because the original Ku feed block is removed, the former should include an adapter plate:

* Use the existing bolt pattern from the prior feed assembly.
* Provide:

  * through holes for screws
  * standoffs/spacers to keep the helix away from nearby metal
  * alignment features (tabs/keys) so the assembly can’t rotate inadvertently

**Important clearance guideline:** keep random metal surfaces at least ~20–35 mm away from the helix turns when possible.

## SAWbird GOES mounting

* The SAWbird already has a metal enclosure.
* Design a bracket pocket behind the feed:

  * holds the SAWbird securely
  * keeps the feed → SAWbird SMA jumper extremely short
  * provides a clean cable exit path
  * avoids putting the Raspberry Pi directly adjacent to the feed

## Cable routing and strain relief

Integrate into the print:

* a “quiet zone” channel for RF coax
* a separate “noisy zone” channel for USB/power
* tie points and strain relief for connectors
* optional pockets for clamp ferrites

## Materials and print considerations

* PLA is fine for prototyping, but a radome can heat up.
* Consider PETG/ASA for better thermal tolerance.
* Avoid thin unsupported walls; design for vibration.

## Assembly sequence (recommended)

1. Print former + adapter plate
2. Install SMA bulkhead and ground radials/disk
3. Place wire into groove and secure at start/top
4. Install SAWbird GOES behind the feed
5. Connect short SMA jumper (feed → SAWbird)
6. Route coax to RTL‑SDR; add ferrites
7. Mount RTL‑SDR and Pi farther back
8. Validate with test captures; reposition and refine

---

# Practical Notes and Risk Register

## Dish size vs recommended antenna size

Official guidance for robust HRIT/EMWIN reception often references ~1 m class antennas at low elevations. Your RV dome dish is smaller, so outcomes will depend on:

* your location in the footprint
* elevation angle to GOES‑West
* feed efficiency and alignment
* local RF noise

This project is still worth pursuing because:

* very short pre‑LNA feedline
* filtered low‑noise front end
* controlled mechanics

…but you should expect an iterative process.

## Iteration knobs

* Helix turns: N=1 vs N=2 vs N=3
* Ground radial lengths and angles
* Feed position (± a few mm)
* Cable choke placement

---

# Next Measurements Needed (to finalize the CAD)

## Measurements captured / assumptions (current hardware)

* **Dish diameter (reflector):** **13 in** (approx. 330 mm)
* **Estimated focal length (approx.):** **4.5 in** (approx. 114 mm)
* **Radome headroom (assumed):** **~1–2 in** above the intended feed reference point (we will design to fit within this without requiring an exact measurement for the first iteration)
* **Metal post/tube (assumed):**
  * **Acts as the RF conduit:** internal clearance is assumed to be sufficient to route an SMA pigtail/coax (exact ID not required for the first iteration)
  * **Acts as a mounting reference:** exact OD is treated as a “fit/adjust” variable for the first iteration (design intent is an adjustable clamp/sleeve rather than a tight press-fit)

## Old Ku feed assembly (what’s there today)

The original Ku feed stack appears to be a bonded/glued assembly:

* **Metal post/tube** (lower): structural mount + hollow path down into the mechanism (this will be reused as a conduit)
* **Plastic tube section** (middle): bonded to the metal post/tube
* **Metal reflector/cap** (top): bonded to the plastic tube

## Revised mechanical plan (remove old feed; reuse metal post as conduit)

Goal: remove the Ku-band feed parts entirely, and use the existing metal post/tube only as a protected route for the RF line.

* **Remove** the old plastic tube and metal reflector/cap so the new L-band feed “sees” the dish directly.
* **Reuse** the existing **metal post/tube as an SMA/coax conduit** down into the dome (strain-relieved and kept from rubbing the metal).
* **Mount** the new feed on a 3D-printed bracket/clamp that references the metal post/tube (or nearby structure), and positions the radiating element at the intended focus.

## Still needed before printing a final-fit design

For the first-pass design we are explicitly proceeding with the assumptions above. These items are only needed if/when we want a final-fit, dimension-locked print:

1. **Metal post/tube dimensions (OD + ID):** to make a non-adjustable, tight-fitting mount and to guarantee the SMA routing clearance.
2. **Reference height for feed placement:** to confirm the **114 mm (4.5")** focus assumption (or replace it with a single measured “dish vertex → desired feed center” distance).
3. **Radome clearance (hard number):** to maximize feed performance without risking interference with the dome.
4. **Chosen wire diameter** for the helix (if using a helix feed) to finalize groove width/depth and retention features.

Once these are known, the 3D-printed mount and feed former can be fully specified for a repeatable build.

---

# OpenSCAD Prototyping Pipeline (Local)

This repo uses a simple, local OpenSCAD workflow (no CI) to iterate on the feed + mount geometry and snapshot numbered revisions as the design evolves.

## Folder layout

* `cad/src/` - OpenSCAD source (`main.scad` entrypoint + part modules)
* `cad/configs/` - Parameter sets (JSON) for specific revisions
* `cad/revisions/` - Frozen revision outputs (STL/PNG + `params.json`)
* `cad/out/` - Scratch build outputs (generated; ignored by git)
* `scripts/` - PowerShell helpers for building and creating revisions

## Prerequisites

* OpenSCAD installed locally and `openscad` available on your `PATH`.

## Common commands

* Build a part to scratch output:
  * `powershell -ExecutionPolicy Bypass -File scripts/scad_build.ps1 -Config cad/configs/rev_0001.json -PartName feed_mount -OutDir cad/out`
* Snapshot a new numbered revision (creates `cad/revisions/rev_000N/` and `cad/configs/rev_000N.json`):
  * `powershell -ExecutionPolicy Bypass -File scripts/scad_new_revision.ps1 -BaseConfig cad/configs/rev_0001.json -PartName feed_mount`

See `playbooks/how_to_iterate_openscad_designs.md` for the full workflow.
