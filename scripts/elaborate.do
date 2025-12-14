# ===========================
# QuestaSim Elaborate Script
# ===========================
onerror {quit -code 1}
# --- הגדרת משתנים ---
variable SIM_LAB ../sim

# --- קריאת שם הטסט שנבחר ---
set fp [open "$SIM_LAB/.current_test" r]
set TEST_NAME [gets $fp]
close $fp

puts "\n--- INFO: Elaborating testbench: $TEST_NAME ---\n"

# --- מיפוי הספריות ---
vmap work $SIM_LAB/work 
vmap design_work $SIM_LAB/design_work

# Initialize error count
set error_count 0

# --- יצירת snapshot אופטימלי ---
set status [catch {vopt +cover +acc=npr -L design_work -o ${TEST_NAME}_opt work.tb_top} msg]
if {$status} {
    puts "Error elaborating with vopt: $msg"
    incr error_count
}

# Check total errors
if {$error_count > 0} {
    puts "\n*** ELABORATION FAILED - Found $error_count error(s) ***\n"
    quit -code 1
}

# Exit successfully
quit -f