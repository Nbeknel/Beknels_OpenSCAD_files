/*[How to use this calibration tool]*/
/*
This program uses Slic3r flow math to approximate the layer print time of square slices, therefore it's best to use this to calibrate filament profiles in Slic3r or its derivatives.

How to prepare your slicer:
I. Print settings:
    1. Set the number of top and bottom solid layers to 0.
    2. Disable the setting "Extra perimeters if needed:"
    3. Set fill pattern to a zig-zag-like pattern ((aligned) rectilinear, monotonic).
    4. Set fill density to 100%.
II. Filament settings:
    5. Disable the setting "Enable auto cooling".
    6. Set your minimum fan speed to the value of "max_fan_speed" when calibrating for "slowdown_below_layer_time" or to the value of "min_fan_speed" when calibrating for "fan_below_layer_time".

What to do here:
Transfer your slicer parameter values to the corresponding parameter under the "Customizer" tab.
"Time" parameters define how the calibration will proceed.
"Program parameters" affect the inner workings of this tool.
How to callibrate the dilation parameter:
    1. Set dilation to 1.000.
    2. Render the model (F6).
    3. Export the resulting model (F7).
    4. Find the ratio between the slicer print time and the time calculated by this tool (slicer / openscad), if your slicer compensates for custom gcodes, subtract them from the slicer print time.
    5. Set dilation to this new value.
    6. If you deem it necessary, iterate over steps 1-5 however much you like. Keep in mind, new dilation is the product of current/old dilatation and the ratio of print times.

How to calculate "OpenSCAD_print_time":
    Under console you'll find a sequence of "ECHO: %f1, %f2, %f3", where %f1 is the segment number from bottom to top. The total calculated print time is calculated as the sum of (layers_per_segment * %f2 + %f3) for al segments.
    E.g.: layers_per_segment = 10,
        ECHO: 1, 10, 9.88012
        ECHO: 2, 9.11362, 8.8164
        ECHO: 3, 8.03068, 7.75042
        ECHO: 4, 7.0716, 6.80701
        ECHO: 5, 5.90847, 5.81443
        ECHO: 6, 5, 4.77318
        ECHO: 7, 3.92449, 3.8362
        ECHO: 8, 3.0694, 2.87583
        ECHO: 9, 2, 1.92376
        ECHO: 10, 1, 0.864268
    will result in a total print time of 10m 4.52s.
    For a quicker estimation, calculate
        (layers_per_segment + 1) * number_of_segments * (first_segment_layer_time + final_segment_layer_time) / 2.
    
When importing the model into your slicer, DO NOT rotate it. If you want to rotate it, change the "fill angle" value in both your slicer and this calibration tool.

How to analyse printed test models:
    The best layer time will be that of the smallest segment with the cleanest edges (no or practically no curling at the corners) and the cleanest seams.
    When calibrating for "slowdown_below_layer_time":
        If all segments have clean edges and clean seams, consider decreasing the value of "max_fan_speed".
        If no segments have clean edges or clean seams, consider increasing the value of "max_fan_speed" if possible, or increasing layer time even more.
    When calibrating for "fan_below_layer_time":
        If all segments have clean edges and clean seams, consider decreasing the value of "min_fan_speed" if possible, or decreasing layer time.
        If no segments have clean edges or clean seams, consider decreasing layer time (will increase filament usage), or increasing "min_fan_speed".
*/
// By ticking this box you agree to the terms and conditions :-)
AGREE = false; // Ticking this doesn't do anything. Or does it?? *Vsauce music intensifies*

/*[Extruder]*/

nozzle_diameter = 0.40; // [0.2, 0.25, 0.3, 0.4, 0.5, 0.6, 0.8, 1, 1.2, 1.4, 1.8]


/*[Layers and perimeters]*/

// Non-positive values are mapped to 0.5 * [nozzle diameter]. Values smaller than 0.25 * [nozzle diameter] are mapped to 0.25 * [nozzle diameter]. Values greater than 0.75 * [nozzle diameter] are mapped to 0.75 * [nozzle diameter]. 
layer_height = 0.2; // 0.01

// Values undergo the same mapping as values for [layer height].
initial_layer_height = 0.2; // 0.01

// I don't know what a reasonable upper limit would be. Keep in mind that with too many perimeters some segments from the top dissapear.
perimeters = 3; // [0:1:50]


/*[Speed]*/

// Non-positive values are mapped to 100mm/s.
default_speed = 100; // 0.1

// Non-positive values are mapped to [default speed].
perimeter_speed = 0; // 0.1

// Non-positive values are mapped to [default speed].
small_perimeter_speed = 0; // 0.1

// Non-positive values are mapped to [default speed].
external_perimeter_speed = 0; // 0.1

// Non-positive values are mapped to [default speed].
infill_speed = 0; //0.1


/*[Acceleration]*/

// Non-positive values are mapped to 1000mm/s^2.
default_acceleration = 1000; // [0:1:30000]

// Non-positive values are mapped to [default acceleration].
perimeter_acceleration = 0; // [0:1:30000]

// Non-positive values are mapped to [default acceleration].
external_perimeter_acceleration = 0; // [0:1:30000]

// Non-positive values are mapped to [default acceleration].
infill_acceleration = 0; // [0:1:30000]


/*[Extrusion width]*/

// Non-positive values are mapped to 1.125 * [nozzle diameter];. Values smaller than 0.6 * [nozzle diameter] are mapped to 0.6 * [nozzle diameter]. Values greater than 2 * [nozzle diameter] are mapped to 2 * [nozzle diameter].
default_extrusion_width = 0; // 0.01

// Non-positive values are mapped to [default extrusion width]. Values smaller than 0.6 * [nozzle diameter] are mapped to 0.6 * [nozzle diameter]. Values greater than 2 * [nozzle diameter] are mapped to 2 * [nozzle diameter].
perimeter_extrusion_width = 0; // 0.01

// Values undergo the same mapping as values for [perimeter extrusion width].
external_perimeter_extrusion_width = 0; // 0.01

// Values undergo the same mapping as values for [perimeter extrusion width].
infill_extrusion_width = 0; // 0.01


/*[Infill]*/

// Let's have some fun! As long as the difference between this value and the slicer value is an integer multiple of 90, you're good to go. :)
fill_angle = 765; // 0.1

// This is just a toggle for which of the following two values to use when calculating [infill overlap]. Most people use percentages, but if you happen to be one of those fre... someone who uses an absolute distance, I present you the option to do so.
infill_overlap_is_in_percentages = true;

infill_overlap_percentage = 25; // [0:0.1:50]

// Negative values are mapped to 0. Values greater than 0.5 * [perimeter extrusion width] are mapped to 0.5 * [perimeter extrusion width].
infill_overlap_mm = 0.1;  //0.0001


/*[Time]*/

// Values smaller than 2 are mapped to 2.
number_of_segments = 10; // 1

// Non-positive values are mapped to 0.1s.
final_segment_layer_time = 1; // 0.1

// Values not greater than [final segment layer time] are mapped to [final segment layer time] + 0.1 * ([number of segments] - 1).
first_segment_layer_time = 10; // 0.1

// Values smaller than 2 are mapped to 2.
layers_per_segment = 10; // 1

/*[Program parameters]*/

// Defines the number of iterations when calculating the side length of a square given a layer time goal.
number_of_iterations = 64; // [1:1:256]

// Since this program uses an approximation of the slicer behaviour, the time calculated by this program and the time calculated by an actual slicer might differ. To calculate this value find the average over all layers of the following expression: [current_dilation] * [slicer_layer_time] / [openscad_layer_time]
dilation = 1.0; // 0.001


/*[Hidden]*/
//Parameter manipulation/processing and defining additional/hardcoded variables.

//** Layers and perimeters **//
l_h = layer_height <= 0 ? 0.5 * nozzle_diameter :
    (layer_height < 0.25 * nozzle_diameter ? 0.25 * nozzle_diameter :
        (layer_height > 0.75 * nozzle_diameter ? 0.75 * nozzle_diameter : layer_height));

i_l_h = initial_layer_height <= 0 ? 0.5 * nozzle_diameter :
    (initial_layer_height < 0.25 * nozzle_diameter ? 0.25 * nozzle_diameter :
        (initial_layer_height > 0.75 * nozzle_diameter ? 0.75 * nozzle_diameter : initial_layer_height));

//** Speed **//
v_d = default_speed > 0 ? default_speed : 100;

v_p = perimeter_speed > 0 ? perimeter_speed : v_d;

v_sp = small_perimeter_speed > 0 ? small_perimeter_speed : v_d;

v_ep = external_perimeter_speed > 0 ? external_perimeter_speed : v_d;

v_i = infill_speed > 0 ? infill_speed : v_d;

//** acceleration **//
a_d = default_acceleration > 0 ? default_acceleration : 1000;

a_p = perimeter_acceleration > 0 ? perimeter_acceleration : a_d;

a_ep = external_perimeter_acceleration > 0 ? external_perimeter_acceleration : a_d;

a_i = infill_acceleration > 0 ? infill_acceleration : a_d;

//** Extrusion width **//
w_d = default_extrusion_width > 0
    ? (default_extrusion_width < 0.6 * nozzle_diameter
        ? 0.6 * nozzle_diameter
        : (default_extrusion_width > 2 * nozzle_diameter
            ? 2 * nozzle_diameter
            : default_extrusion_width
        )
    )
    : 1.125 * nozzle_diameter;

w_p = perimeter_extrusion_width > 0
    ? (perimeter_extrusion_width < 0.6 * nozzle_diameter
        ? 0.6 * nozzle_diameter
        : (perimeter_extrusion_width > 2 * nozzle_diameter
            ? 2 * nozzle_diameter
            : perimeter_extrusion_width
        )
    )
    : w_d;

w_ep = external_perimeter_extrusion_width > 0
    ? (external_perimeter_extrusion_width < 0.6 * nozzle_diameter
        ? 0.6 * nozzle_diameter
        : (external_perimeter_extrusion_width > 2 * nozzle_diameter
            ? 2 * nozzle_diameter
            : external_perimeter_extrusion_width
        )
    )
    : w_d;

w_i = infill_extrusion_width > 0
    ? (infill_extrusion_width < 0.6 * nozzle_diameter
        ? 0.6 * nozzle_diameter
        : (infill_extrusion_width > 2 * nozzle_diameter
            ? 2 * nozzle_diameter
            : infill_extrusion_width
        )
    )
    : w_d;

// Inner most perimeter
w_ip = perimeters > 1 ? w_p : w_ep;

//** Infill **//
i_o = infill_overlap_is_in_percentages
    ? 0.01 * infill_overlap_percentage * w_ip
    : (infill_overlap_mm < 0
        ? 0
        : (infill_overlap_mm > 0.5 * w_ip ? 0.5 * w_ip : infill_overlap_mm));

//** Time **//
n_o_s = max(2, number_of_segments);

fin_slt = max(0.1, final_segment_layer_time);

fir_slt = first_segment_layer_time > fin_slt ? first_segment_layer_time : fin_slt + 0.1 * (n_o_s - 1);

lps = max(2, layers_per_segment);

//** Additional **//

// Google Slic3r flow math.
// Holy hell!
perimeter_overlap = (1 - 0.25 * PI) * l_h;

// A radius smaller than or equal to 6.5mm sounds rather weird when we're working with squares, not circles.
small_perimeter_length = 13 * PI;

// Variables needed for initial approximation of the width of squares
a = 1 / (w_i * v_i);

b = perimeters > 0 ? 4 * (1 / v_ep + (perimeters - 1) / v_p) : 0;


//** Functions **//

// Returns the sum of the values in an array.
function sum(array) =
    len(array) == 1
        ? array[0]
        : array[0] + sum([for (i = [1:len(array)-1]) array[i]]);

/*
   Calculates the time it would take to traverse a distance of [length], where initial and final velocities are 0, target velocity is [speed] and given acceleration [acceleration].
   Using following formulas:
        v = a * t,
        d = 1/2 * a * t^2,
   we reach target velocity at t = v / a,
   substituting t in the second formula we get the distance the nozzle traverses when accelerating:
        d = 1/2 * a * (v / a)^2 = 1/2 * v^2 / a.
   Given we need to accelerate and decelerate, the minimum length to reach the target velocity becomes
        l = 2 * d = v^2 / a.
   The cumulative time it takes to accelerate untill target velocity and to decelerate to standstill is
        2 * v / a.
   For lengths smaller than l we only use the formula
        d = 1/2 * a * t^2
   which gives
        t = sqrt(2 * d / a).
   For half the length we accelerate, for the other we decelerate, which gives
        t = 2 * sqrt(d / a).
*/
function line_time(length, speed, acceleration) =
    let (
        l = speed ^ 2 / acceleration
    )
    length >= l
        ? (length - l) / speed + 2 * speed / acceleration
        : length > 0
            ? 2 * sqrt(length / acceleration)
            : 0;

function actual_time(square_width) =
    let(
        is_small_perimeter_ep = 4 * (square_width - w_ep) <= small_perimeter_length,
        
        t_ep = perimeters > 0
            ? 4 * line_time(square_width - w_ep, is_small_perimeter_ep ? v_sp : v_ep, is_small_perimeter_ep ? a_p : a_ep)
            : 0,
        w1 = perimeters > 0 ? square_width - w_ep : square_width,
        
        t_p_arr = perimeters > 1
            ? [for (i = [1:1:perimeters - 1])
                let(
                    w = w1 - i * (w_p - perimeter_overlap),
                    is_small_perimeter_p = 4 * w <= small_perimeter_length
                )
                w > 0
                    ? 4 * line_time(w, is_small_perimeter_p ? v_sp : v_p, a_p)
                    : 0]
            : [0],
            
        t_p = sum(t_p_arr),
            
        w2 = perimeters > 1
            ? w1 - (perimeters - 1) * w_p + (perimeters - 2) *  perimeter_overlap + 2 * i_o
            : perimeters == 1
                ? w1 + 2 * i_o
                : square_width,
        
        n = floor((w2 - perimeter_overlap) / (w_i - perimeter_overlap)),
        
        t_i = n > 0
            ? n * line_time(w2 - w_i, v_i, a_i) + (n - 1) * line_time(w_i - perimeter_overlap, v_i, a_i)
            : 0
    )
    dilation * (t_ep + t_p + t_i);

function get_square_width(time, depth) =
    depth == 0
        ? let(c = -time) 0.5 * (sqrt(b ^ 2 - 4 * a * c) - b) / a
        : let(
            w = get_square_width(time, depth - 1),
            t = actual_time(w)
            )
            0.5 * (1 + time / t) * w;

//** Modules **//

module tower(){
    height = lps * l_h;
    rotate([0,0,fill_angle])
    for (n = [0:1:n_o_s-1]) {
        time = fir_slt - n * (fir_slt - fin_slt) / (n_o_s - 1);
        square_width = get_square_width(time, number_of_iterations);
        echo(n+1, actual_time(square_width), actual_time(square_width - 0.8 * nozzle_diameter));
        
        h = n == 0 ? i_l_h : l_h;
        
        translate([0,0, n * (height + l_h) + 0.5 * i_l_h])
        cube([square_width - 0.8 * nozzle_diameter, square_width - 0.8 * nozzle_diameter, h], center=true);
        
        translate([0,0, (n + 0.5) * (height + l_h) + 0.5 * i_l_h])
        cube([square_width, square_width, height], center=true);
    }
}

tower();