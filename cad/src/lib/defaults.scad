// Project defaults (all dimensions in mm)

// Part selector (set via -D part_id=0/1/2...)
// NOTE: OpenSCAD CLI `-D` string quoting on Windows is fragile; use numeric ids.
part_id = 0; // 0=feed_mount, 1=fit_sleeve

// Known / assumed dish + packaging values
dish_diameter = 330;          // 13 in approx.
focus_length = 114;           // 4.5 in approx.
radome_headroom = 38;         // ~1.5 in nominal assumption (1–2 in range)

// Mechanical assumptions for first iteration (adjust as measured)
tube_od = 33;                 // plastic tube OD (measured)
tube_length = 33;             // metal post top -> tube tip (measured)

// Legacy / optional: clamp to metal post/tube (used by feed_mount prototype)
post_od = 45;                 // metal post/tube OD guess; adjustable clamp target
post_clearance = 0.8;         // extra clearance inside clamp

// Clamp geometry
clamp_wall = 4;
clamp_height = 25;
clamp_gap = 3;                // slit width for clamp
clamp_boss_d = 10;            // screw boss diameter
clamp_screw_d = 3.5;          // M3 clearance
clamp_screw_head_d = 7;       // button head clearance
clamp_screw_head_h = 3;

// Cable routing
cable_hole_d = 8;             // enough for a small SMA pigtail/coax
fillet_r = 0;                 // placeholder (OpenSCAD fillets are non-trivial; keep 0 by default)

// Fit-sleeve prototype (no grooves)
sleeve_total_len = 66;        // tube tip/focus at mid-plane (±33 mm)
sleeve_insert_depth = 33;     // open bore depth from bottom to mid-plane
sleeve_wall = 3;
sleeve_clearance = 0.4;       // starting slip-fit clearance
sleeve_outer_d = 60;          // packaging check; > tube_od to approximate future former
