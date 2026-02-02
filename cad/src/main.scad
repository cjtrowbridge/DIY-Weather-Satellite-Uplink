// Entry point for scripted exports.
// Usage:
//   openscad -o out.stl cad/src/main.scad -D part_id=0 -D post_od=45 ...

include <lib/defaults.scad>;
include <parts/feed_mount.scad>;
include <parts/fit_sleeve.scad>;

_part_id = is_undef(part_id) ? 0 : part_id;

if (_part_id == 0) {
  feed_mount();
} else if (_part_id == 1) {
  fit_sleeve();
} else {
  assert(false, str("Unknown part_id: ", _part_id));
}
