/*******************************************************************************
 * Units!  Internally we define 1 OpenSCAD Unit = 1 mm.
 * These convenience functions let us work in inches, etc.
 */

function mm(n) = n;
function inch(n) = mm(25.4 * n);


/*******************************************************************************
 * Common Parameters
 */

/*
 * Height of cross-bracing beneath reservoir floor.  Taller braces are stronger.
 * However, brace height is deducted from maximum system height!
 */
brace_height = inch(1);

wood_thickness = inch(0.25);
plastic_thickness = inch(0.125);

reservoir_depth = inch(6);

hook_margin = wood_thickness * 2;

exterior_height = inch(23);
exterior_width = inch(23);
exterior_depth = inch(23);

interior_width = exterior_width - 2 * (hook_margin + wood_thickness);
interior_depth = exterior_depth - 2 * (hook_margin + wood_thickness);
interior_height = exterior_height - brace_height;

pad_thickness = inch(6);
pad_width = interior_width;
pad_height = inch(12);
pad_margin = inch(1);

soak_pipe_clearance = inch(2);

fan_spacing = inch(3);

duct_diameter = inch(4);


/*******************************************************************************
 * Braces
 *
 * A basic brace looks like this:
 *
 * ,---------------------- length --------------------------.
 * +-------------------+ +----------------------------------+ \
 * | +-+               | | <-- a cutout                 +-+ |  | height
 * | | |               +-+                              | | |  |
 * +-+ +------------------------------------------------+ +-+ /
 *
 * In addition to the two end-notches (always present), there are some number
 * of cutouts for other panels (one shown above).  They point the opposite way
 * from the end-notches.  The position of each cutout is given from the brace
 * center.
 */

module brace(length, cutout_centers) {
  center = length / 2;

  translate([-length/2, 0]) difference() {
    square([length, brace_height]);

    for (x = [hook_margin, length - hook_margin - wood_thickness]) {
      translate([x, 0]) square([wood_thickness, brace_height - hook_margin]);
    }

    for (x = cutout_centers) {
      translate([center + x - wood_thickness / 2, hook_margin]) {
        square([wood_thickness, brace_height - hook_margin]);
      }
    }
  }
}

lateral_brace_positions = [ -exterior_depth / 6, exterior_depth / 6];
longitudinal_brace_positions = [ -exterior_depth / 6, exterior_depth / 6];

module longitudinal_brace() {
  translate([0, brace_height]) scale([1, -1])
    brace(exterior_depth, lateral_brace_positions);
}

module mock_longitudinal_brace() {
  linear_extrude(height = wood_thickness, convexity = 10, center = true)
    longitudinal_brace();
}

module lateral_brace() {
  brace(exterior_width, longitudinal_brace_positions);
}

module mock_lateral_brace() {
  linear_extrude(height = wood_thickness, convexity = 10, center = true)
    lateral_brace();
}


/*******************************************************************************
 * Longitudinal (side) panels
 *
 * The panels look roughly like this (not to scale):
 *
 * +-+ +--+ +------+ +----------+
 * | | |  | |      | |          | <-- hang panel cutouts
 * | +-+  +-+      +-+          |
 * |                            |
 * |                            |
 * | +-+                    +-+ |
 * | | | <- brace cutout -> | | |
 * | +-+                    +-+ |
 * +--------------*-------------+
 */

pad_hanger_offsets = [
  -interior_depth/2 + plastic_thickness + plastic_thickness/2,
  -interior_depth/2 + plastic_thickness + plastic_thickness + pad_thickness
];

fan_panel_offsets = [
  interior_depth / 6 - fan_spacing/2,
  interior_depth / 6 + fan_spacing/2,
];

module longitudinal_panel() {
  difference() {
    translate([-exterior_depth / 2, 0])
        square([exterior_depth, exterior_height]);
    
    for (x = lateral_brace_positions) {
      translate([x - wood_thickness/2, hook_margin])
          square([wood_thickness, brace_height]);
    }

    for (x = [-1, 1]) {
      translate([x * (exterior_depth/2 - hook_margin - wood_thickness/2),
                 exterior_height - hook_margin])
        translate([-wood_thickness/2, 0])
          square([wood_thickness, hook_margin]);
    }
    for (x = pad_hanger_offsets) {
      translate([x, exterior_height - hook_margin])
        translate([-plastic_thickness/2, 0])
          square([plastic_thickness, hook_margin]);
    }
    for (x = fan_panel_offsets) {
      translate([x, exterior_height - hook_margin])
        translate([-plastic_thickness/2, 0])
          square([plastic_thickness, hook_margin]);
    }
  }
}

module mock_longitudinal_panel() {
  linear_extrude(height = wood_thickness, convexity = 10, center = true)
      longitudinal_panel();
}


/*******************************************************************************
 * Lateral (front/rear) panels
 *
 * These are hang panels.  The end panels are different.
 *
 * +-------------------------+
 * | +-+                 +-+ |
 * | | |                 | | |
 * +-+ |                 | +-+
 *     |                 |    
 *     | +-+         +-+ |    
 *     | | |         | | |    
 *     +-+ +---------+ +-+    
 */

module lateral_panel() {
  width = exterior_width - 2 * (hook_margin + wood_thickness);

  translate([-width/2, 0]) square([width, exterior_height]);

  for (s = [-1, 1]) scale([s, 1]) {
    translate([width/2, exterior_height - hook_margin])
      square([wood_thickness, hook_margin]);
    translate([width/2 + wood_thickness, exterior_height - hook_margin * 2])
      square([hook_margin, hook_margin * 2]);

  }
}

module interior_lateral_panel() {
  width = exterior_width - 2 * (hook_margin + wood_thickness);

  difference() {
    lateral_panel();
    
    translate([-width/2, 0]) {
      square([width, brace_height + plastic_thickness]);
      translate([0, brace_height + plastic_thickness]) {
        square([plastic_thickness, reservoir_depth]);
        translate([width - plastic_thickness, 0])
          square([plastic_thickness, reservoir_depth]);
      }
    }

    translate([0, brace_height + 3*plastic_thickness + inch(0.5)])
      circle(r = inch(0.5));
  }
}

module pad_opening_template() {
  pad_opening_width = pad_width - 2 * pad_margin;
  pad_opening_height = pad_height - 2 * pad_margin;

  pad_opening_top = interior_height - soak_pipe_clearance;

  translate([-pad_opening_width / 2, pad_opening_top - pad_opening_height])
      square([pad_opening_width, pad_opening_height]);
}

module pad_hanger() {
  difference() {
    interior_lateral_panel();
    pad_opening_template();
  }
}

module front_panel() {
  difference() {
    lateral_panel();
    pad_opening_template();
  }
}

module rear_panel() {
  difference() {
    lateral_panel();

    translate([0, exterior_height - inch(2) - duct_diameter/2])
        circle(r = duct_diameter / 2);
  }
}

module fan_panel_4in() {
  difference() {
    interior_lateral_panel();

    translate([0, exterior_height - inch(4)])
        circle(r = inch(2));
  }
}

module mock_pad_hanger() {
  color([0, 0, 1, 0.5])
  linear_extrude(height = plastic_thickness, convexity = 10, center = true)
    pad_hanger(); 
}

module mock_fan_panel_4in() {
  color([0, 0, 1, 0.5])
  linear_extrude(height = plastic_thickness, convexity = 10, center = true)
    fan_panel_4in();
}

module mock_front_panel() {
  linear_extrude(height = wood_thickness, convexity = 10, center = true)
    front_panel(); 
}

module mock_rear_panel() {
  linear_extrude(height = wood_thickness, convexity = 10, center = true)
    rear_panel(); 
}

/*******************************************************************************
 * Reservoir!
 */

module reservoir_floor() {
  square([interior_width, interior_depth], center = true);
}

module reservoir_longitudinal_panel() {
  translate([-interior_depth/2, 0]) square([interior_depth, reservoir_depth]);
}

module reservoir_lateral_panel() {
  width = interior_width - (2 * plastic_thickness);
  translate([-width/2, 0]) square([width, reservoir_depth]);
}

module mock_reservoir_floor() {
  color([0, 0, 1, 0.5])
  linear_extrude(height = plastic_thickness, convexity = 10, center = true)
      reservoir_floor();
}

module mock_reservoir_longitudinal_panel() {
  color([0, 0, 1, 0.5])
  linear_extrude(height = plastic_thickness, convexity = 10, center = true)
      reservoir_longitudinal_panel();
}

module mock_reservoir_lateral_panel() {
  color([0, 0, 1, 0.5])
  linear_extrude(height = plastic_thickness, convexity = 10, center = true)
      reservoir_lateral_panel();
}

module mock_reservoir() {
  mock_reservoir_floor();
  for (x = [-1, 1]) {
    translate([x * (interior_width/2 - plastic_thickness/2), 0, 0])
      rotate([90, 0, 90]) mock_reservoir_longitudinal_panel();
  }
  for (y = [-1, 1]) {
    translate([0, y * (interior_depth/2 - plastic_thickness/2), 0])
      rotate([90, 0, 0]) mock_reservoir_lateral_panel();
  }
}


/*******************************************************************************
 * Lid - two parts.  The rear part is intended to be sealed and covers the
 * positive pressure zone at the rear of the enclosure.  The front part is
 * hinged.
 */

rear_lid_depth = exterior_depth / 2
               - fan_panel_offsets[0]
               + plastic_thickness/2;
module rear_lid() {
  translate([-exterior_width/2, 0])
    square([exterior_width, rear_lid_depth]);
}

module front_lid() {
  depth = exterior_depth - rear_lid_depth;
  translate([-exterior_width/2, 0])
      square([exterior_width, depth]);
}

module mock_rear_lid() {
  linear_extrude(height = wood_thickness, convexity = 10, center = true)
    rear_lid();
}

module mock_front_lid() {
  linear_extrude(height = wood_thickness, convexity = 10, center = true)
    front_lid();
}


/*******************************************************************************
 * All parts for cutting
 */
margin = inch(1);

module wood_cutting_layout() {
  longitudinal_panel();
  translate([0, -brace_height - margin])
    longitudinal_brace();

  translate([-exterior_depth - margin, 0]) {
    longitudinal_panel();
    translate([0, -brace_height - margin])
      longitudinal_brace();
  }
  
  translate([0, exterior_height + margin]) {
    front_panel();
    translate([0, exterior_height + margin]) lateral_brace();
  }

  translate([-exterior_depth - margin, exterior_height + margin]) {
    rear_panel();
    translate([0, exterior_height + margin]) lateral_brace();
  }
}

module plastic_cutting_layout() {
  pad_hanger();
  translate([0, exterior_height + margin]) {
    fan_panel_4in();
  }

  translate([-interior_width - margin - hook_margin*2, 0]) {
    pad_hanger();
    translate([0, exterior_height + margin]) {
      fan_panel_4in();
    }
  }


  translate([interior_width + margin, interior_depth/2]) {
    reservoir_floor();

    translate([0, interior_depth/2 + margin]) {
      reservoir_lateral_panel();
      translate([0, reservoir_depth + margin]) {
        reservoir_lateral_panel();
      }
    }

    translate([interior_width / 2 + margin, 0]) {
      rotate(270) reservoir_longitudinal_panel();
      translate([reservoir_depth + margin, 0]) {
        rotate(270) reservoir_longitudinal_panel();
      }
    }
  }
}


/*******************************************************************************
 * Assembly 3D mock
 */

module mock_braces() {
  for (x = longitudinal_brace_positions) {
    translate([x, 0, 0]) rotate([90, 0, 90]) mock_longitudinal_brace();
  }
  for (y = longitudinal_brace_positions) {
    translate([0, y, 0])
      rotate([0, 0, 90])
      rotate([90, 0, 90]) mock_lateral_brace();
  }
}

module mock_box() {
  longitudinal_panel_offset = exterior_width/2 - hook_margin - wood_thickness/2;
  lateral_panel_offset = exterior_depth/2 - hook_margin - wood_thickness/2;

  mock_braces();

  for (x = [-1, 1]) {
    translate([x * longitudinal_panel_offset, 0])
      rotate([90, 0, 90]) mock_longitudinal_panel();
  }

  translate([0, -lateral_panel_offset])
    rotate([90, 0, 0]) mock_front_panel();
  translate([0, lateral_panel_offset])
    rotate([90, 0, 0]) mock_rear_panel();

  translate([0, 0, brace_height + plastic_thickness]) mock_reservoir();

  for (x = pad_hanger_offsets) {
    translate([0, x, 0]) rotate([90, 0, 0]) mock_pad_hanger();
  }
  for (x = fan_panel_offsets) {
    translate([0, x, 0]) rotate([90, 0, 0]) mock_fan_panel_4in();
  }

  translate([0,
             fan_panel_offsets[0] - plastic_thickness / 2,
             exterior_height + wood_thickness/2])
      mock_rear_lid();

  translate([0,
             fan_panel_offsets[0] - plastic_thickness / 2,
             exterior_height + wood_thickness / 2])
  rotate([150, 0, 0])
  mock_front_lid();
}

//wood_cutting_layout();
//plastic_cutting_layout();
mock_box();