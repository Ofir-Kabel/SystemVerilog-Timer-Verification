# ===========================
# QuestaSim Compile Script
# ===========================
onerror {quit -code 1}
# --- הגדרת משתנים ראשיים ---
variable DESIGN_LAB ../design
variable VERIFICATION_LAB ../verification
variable SIM_LAB ../sim
# --- קריאת שם הטסט שנבחר על ידי המשתמש ---
set fp [open "$SIM_LAB/.current_test" r]
set TEST_NAME [gets $fp]
close $fp
puts "\n--- INFO: Compiling design for testbench: $TEST_NAME ---\n"
# --- יצירת ספריות ---
vlib $SIM_LAB/work
vlib $SIM_LAB/design_work
# --- מיפוי הספריות ---
vmap work $SIM_LAB/work
vmap design_work $SIM_LAB/design_work

# Initialize error count
set error_count 0

# --- קומפילציה של החבילה והטסט ---
set status [catch {vlog -sv -work design_work $DESIGN_LAB/design_params_pkg.sv} msg]
if {$status} {
    puts "Error compiling design_params_pkg.sv: $msg"
    incr error_count
}

set status [catch {vlog -sv -work design_work -L design_work $DESIGN_LAB/bus_if.sv} msg]
if {$status} {
    puts "Error compiling bus_if.sv: $msg"
    incr error_count
}

set status [catch {vlog -sv -work design_work -L design_work $DESIGN_LAB/design_pkg.sv} msg]
if {$status} {
    puts "Error compiling design_pkg.sv: $msg"
    incr error_count
}

set status [catch {vlog -sv -work design_work -L design_work $DESIGN_LAB/timer_periph.sv} msg]
if {$status} {
    puts "Error compiling timer_periph.sv: $msg"
    incr error_count
}

set status [catch {vlog -sv -work work -L design_work $VERIFICATION_LAB/${TEST_NAME}.sv} msg]
if {$status} {
    puts "Error compiling ${TEST_NAME}.sv: $msg"
    incr error_count
}

# Check total errors
if {$error_count > 0} {
    puts "\n*** COMPILATION FAILED - Found $error_count error(s) ***\n"
    quit -code 1
}

# Exit successfully
quit -f