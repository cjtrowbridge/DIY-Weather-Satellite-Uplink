// Entry point for scripted exports.
// Usage:
//   openscad -o out.stl cad/src/main.scad -D part=\"feed_mount\" -D post_od=45 ...

include <lib/defaults.scad>;
include <parts/feed_mount.scad>;

_part = is_undef(part) ? "feed_mount" : part;

if (_part == "feed_mount") {
  feed_mount();
} else {
  assert(false, str("Unknown part: ", _part));
}

