include <../lib/util.scad>;

// 3-element yagi mount (printable backplane + mount stub).
//
// Coordinate convention:
//   z=0 is the focus datum (original plastic tube tip).
//   Mount seat plane is at z=-mount_seat_to_focus.
//
// Element placement (along +z):
//   director (front):   z = -element_spacing
//   driven (dipole):    z = 0
//   reflector (rear):   z = +element_spacing
//
// Elements are solid copper wire/rod; this part provides grooves only.
// The driven element groove includes a center cutout (dipole_gap) to help keep
// the two halves separated at the feedpoint and to provide clearance for a pigtail exit.

module yagi_mount() {
  seat_z = -mount_seat_to_focus;
  stub_top_z = seat_z + mount_stub_len;

  director_z = -element_spacing;
  driven_z = 0;
  reflector_z = element_spacing;

  difference() {
    union() {
      // Short 33mm OD stub near the mount seat plane.
      translate([0, 0, seat_z]) cylinder(d = mount_stub_od, h = mount_stub_len, $fn = 128);

      // Square backplane/boom starting at the top of the stub.
      translate([-card_size / 2, -card_thickness / 2, stub_top_z])
        cube([card_size, card_thickness, card_size], center = false);
    }

    // Cable/pigtail path down into the metal shaft (axial).
    translate([0, 0, seat_z - 1])
      cylinder(d = cable_hole_d, h = mount_seat_to_focus + 2, $fn = 96);

    // Grooves for elements (cut from the top face).
    for (zpos = [director_z, driven_z, reflector_z]) {
      translate([0, card_thickness / 2 - groove_depth / 2, zpos])
        cube([card_size + 2, groove_depth, groove_w], center = true);
    }

    // Driven element center cutout: makes space for coax exit and dipole separation.
    translate([0, 0, driven_z])
      cube([dipole_gap, card_thickness + 2, groove_w + 2], center = true);
  }
}

