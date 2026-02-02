include <../lib/util.scad>;

// Slip-over fit + clearance prototype.
// Coordinate convention:
//   z=0 is the plastic tube tip (treated as the focus datum for this iteration).
//   Part spans z=[-sleeve_total_len/2, +sleeve_total_len/2].
//   The tube slips in from the bottom and stops at z=0 (internal shoulder).

module fit_sleeve() {
  sleeve_r = sleeve_total_len / 2;
  id = tube_od + sleeve_clearance;
  od = max(sleeve_outer_d, id + 2 * sleeve_wall);

  difference() {
    // Outer body
    translate([0, 0, -sleeve_r]) cylinder(d = od, h = sleeve_total_len, $fn = 128);

    // Inner bore open from bottom up to z=0 (shoulder at focus datum)
    translate([0, 0, -sleeve_insert_depth]) cylinder(d = id, h = sleeve_insert_depth + 0.01, $fn = 128);

    // Small lead-in chamfer (approximated as a cone) at the very bottom for easier insertion
    translate([0, 0, -sleeve_r - 0.01])
      cylinder(d1 = id + 2.0, d2 = id, h = 2.0, $fn = 96);
  }
}

