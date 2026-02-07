// Project defaults (all dimensions in mm)

// Part selector (set via -D part_id=0/1/2...)
// NOTE: OpenSCAD CLI `-D` string quoting on Windows is fragile; use numeric ids.
part_id = 0; // 0=yagi_mount

// Mechanical datum convention:
//   z=0 is the original plastic tube tip (focus reference).
//   The mount seat plane (metal post top) is at z=-mount_seat_to_focus.
mount_seat_to_focus = 33;

// Mount interface near the seat plane (fits the dish mount where the old 33mm tube lived).
mount_stub_od = 33;
mount_stub_len = 6;

// Cable routing (SMA pigtail down the metal shaft)
cable_hole_d = 8;

// Backplane/boom ("card") geometry
card_size = 60;        // square in X and Z
card_thickness = 6;    // thickness along Y

// Yagi geometry (center-to-center spacing along dish axis)
element_spacing = 22;  // director <-> driven <-> reflector spacing

// Element material and retention
groove_w = 3;          // groove width along Z (user requested 3mm)
groove_depth = 2;      // groove depth from the top face
dipole_gap = 6;        // cutout at the driven element center for feedpoint separation

// Element lengths (for documentation; copper elements are not printed)
director_len = 66;
driven_len = 83;
reflector_len = 87;

