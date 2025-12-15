import os
import sys
import argparse
import shutil
import subprocess

# Change current directory to scripts
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# --- Function to run shell commands with error checking ---
def run_command(command, step_name):
    print(f"\n--- INFO: Starting Step: {step_name} ---")
    print(f"Executing: {command}")
    return_code = os.system(command)
    if return_code != 0:
        print(f"\n--- ERROR: Step '{step_name}' failed! ---")
        sys.exit(1)

# --- Function to choose testbench ---
def choose_testbench(verification_path):
    tb_files = [f[:-3] for f in os.listdir(verification_path)
                if f.startswith("tb_") and f.endswith(".sv")]

    if not tb_files:
        print("\n--- ERROR: No tb_*.sv files found in verification folder! ---")
        sys.exit(1)

    print("\nAvailable Testbenches:")
    for i, tb in enumerate(tb_files, 1):
        print(f"  {i}. {tb}")

    while True:
        try:
            choice = int(input("\nSelect a testbench number: "))
            if 1 <= choice <= len(tb_files):
                return tb_files[choice - 1]
            else:
                print("Invalid choice, try again.")
        except ValueError:
            print("Please enter a number.")

# --- Helper to parse coverage score from text file ---
# --- Helper to parse coverage score from text file ---
def print_coverage_summary(report_path):
    try:
        if not os.path.exists(report_path):
            return
        
        with open(report_path, 'r', encoding='utf-8', errors='ignore') as f: # Added safe encoding
            content = f.read()
            import re
            
            # 1. ננסה לתפוס את השורה המסכמת בסוף הקובץ
            # מחפש: "Total Coverage By Instance ... : 89.28%"
            match = re.search(r'Total Coverage By Instance.*:\s+(\d+\.?\d*)%', content)
            
            # 2. גיבוי: אם לא מוצא, ננסה לתפוס את ה-TOTAL COVERGROUP
            if not match:
                match = re.search(r'TOTAL COVERGROUP COVERAGE:\s+(\d+\.?\d*)%', content)

            if match:
                score = match.group(1)
                
                # הדפסה יפה ומודגשת לטרמינל
                print("\n" + "="*50)
                print(f"   📊 FINAL COVERAGE SCORE: {score}%")
                print("="*50 + "\n")
            else:
                print("\n[INFO] Could not find coverage percentage in report.")

    except Exception as e:
        print(f"[WARNING] Failed to parse coverage score: {e}")

# --- Main script execution ---
try:
    ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    DESIGN_LAB = os.path.join(ROOT_DIR, "design")
    VERIFICATION_LAB = os.path.join(ROOT_DIR, "verification")
    SIM_LAB = os.path.join(ROOT_DIR, "sim")
    SCRIPTS = os.path.join(ROOT_DIR, "scripts")
    CURRENT_TEST_FILE = os.path.join(SIM_LAB, ".current_test")

    # --- License Check ---
    salt_server = os.environ.get("SALT_LICENSE_SERVER")
    if salt_server:
        print(f"SALT_LICENSE_SERVER = {salt_server}")
    else:
        print("\n--- WARNING: SALT_LICENSE_SERVER is not set! ---")

    # --- Argument Parsing ---
    parser = argparse.ArgumentParser(description="Run QuestaSim simulation")
    parser.add_argument('--gui', action='store_true', help="Run simulation in GUI mode.")
    parser.add_argument('--seed', type=int, default=1, help="Random seed.")
    parser.add_argument('--test', type=str, help="Testbench name (tb_xxx).")
    args = parser.parse_args()

    # --- Test Selection ---
    if not args.test:
        if os.path.exists(CURRENT_TEST_FILE):
            with open(CURRENT_TEST_FILE, "r") as f:
                last_test = f.read().strip()
            print(f"\nPrevious test found: {last_test}")
            use_last = input("Use previous test? (y/n): ").strip().lower()
            if use_last == "y":
                args.test = last_test
            else:
                args.test = choose_testbench(VERIFICATION_LAB)
        else:
            args.test = choose_testbench(VERIFICATION_LAB)

    # --- Save Selection ---
    with open(CURRENT_TEST_FILE, "w") as f:
        f.write(args.test.strip())

    print(f"\n--- INFO: Selected Testbench: {args.test} ---")

    # --- Cleanup ---
    print("\n--- INFO: Cleaning previous run ---")
    cleanup_dirs = [os.path.join(SIM_LAB, "work"),
                    os.path.join(SIM_LAB, "design_work")]
    cleanup_files = [os.path.join(SIM_LAB, f"{args.test}.log"),
                     os.path.join(SIM_LAB, f"{args.test}.wlf"),
                     os.path.join(SIM_LAB, f"{args.test}.ucdb"),
                     os.path.join(SIM_LAB, "coverage_report.txt"),
                     os.path.join(SIM_LAB, "summary_report.txt")]

    for d in cleanup_dirs:
        if os.path.exists(d):
            print(f"Deleting directory: {d}")
            shutil.rmtree(d)

    for f in cleanup_files:
        if os.path.exists(f):
            print(f"Deleting file: {f}")
            os.remove(f)

    # --- Compile ---
    CMD_COMPILE = f'vsim -c -do "{os.path.join(SCRIPTS, "compile.do")}"'
    run_command(CMD_COMPILE, "Compile")

    # --- Elaborate ---
    CMD_ELABORATE = f'vsim -c -do "{os.path.join(SCRIPTS, "elaborate.do")}"'
    run_command(CMD_ELABORATE, "Elaborate")

    # --- Simulate ---
    log_file = os.path.join(SIM_LAB, f"{args.test}.log")
    wlf_file = os.path.join(SIM_LAB, f"{args.test}.wlf")
    ucdb_file = os.path.join(SIM_LAB, f"{args.test}.ucdb")
    top_module = args.test + "_opt"

    # Fix paths for TCL (Windows backslash issue)
    tcl_ucdb_file = ucdb_file.replace(os.sep, '/') 

    # Wave format handling
    WAVE_FORMAT_DO = os.path.join(SCRIPTS, "wave_format.do")
    tcl_wave_format_do = WAVE_FORMAT_DO.replace(os.sep, '/')
    
    cmd = f'vsim {top_module} -coverage -voptargs=+acc -sv_seed {args.seed} -L design_work '
    
    # Common TCL commands (Run and Save Coverage)
    tcl_commands_base = f'coverage save -onexit {tcl_ucdb_file}; run -all;'

    if args.gui:
        # GUI Mode Logic
        if os.path.exists(WAVE_FORMAT_DO):
            tcl_wave_command = f'do {tcl_wave_format_do};'
            print(f"INFO: Loading custom wave format from {WAVE_FORMAT_DO}")
        else:
            tcl_wave_command = f'add wave -r /*;'
            print(f"WARNING: Wave format file not found at {WAVE_FORMAT_DO}. Adding all waves generically.")

        tcl_full_command = tcl_wave_command + tcl_commands_base
        cmd += f'-gui -do "{tcl_full_command}"'
        
        # Run Simulation (GUI)
        run_command(cmd, "Simulate (GUI)")
        
    else:
        # Non-GUI Mode Logic
        cmd += f'-c -logfile {log_file} -wlf {wlf_file} -do "{tcl_commands_base} quit -f"'
        
        # Run Simulation (Batch)
        run_command(cmd, "Simulate (Batch)")

        # --- POST SIMULATION ANALYSIS (Only for Batch Mode) ---
        
        # 1. Generate Coverage Report
        print("\n--- INFO: Generating Coverage Report... ---")
        cov_report_file = os.path.join(SIM_LAB, "coverage_report.txt")
        # Use -output instead of -file (deprecated)
        cov_cmd = f"vcover report -details -cvg -output {cov_report_file} {ucdb_file}"
        
        # Run vcover
        subprocess.run(cov_cmd, shell=True)
        
        if os.path.exists(cov_report_file):
            print(f"Coverage report saved to: {cov_report_file}")
            print_coverage_summary(cov_report_file)
        else:
            print("Warning: Failed to generate coverage report file.")

        # 2. Analyze Logs (Success/Fail/Mismatch)
        print("\n--- INFO: Analyzing Log Results... ---")
        analyze_script = os.path.join(SCRIPTS, "analyze_results.py")
        
        if os.path.exists(analyze_script):
            # Run the python analysis script safely
            subprocess.run([sys.executable, analyze_script, log_file])
        else:
            print(f"ERROR: Could not find analysis script at {analyze_script}")

    print(f"\n--- INFO: All steps completed successfully. Check {log_file} for results. ---")

except Exception as e:
    print(f"--- ERROR: {e} ---")
    sys.exit(1)