import os
import sys
import argparse
import shutil
from pathlib import Path

# שינוי התיקייה הנוכחית ל-scripts
os.chdir(os.path.dirname(os.path.abspath(__file__)))

# --- פונקציה להרצת פקודות shell עם בדיקת הצלחה ---
def run_command(command, step_name):
    print(f"\n--- INFO: Starting Step: {step_name} ---")
    print(f"Executing: {command}")
    return_code = os.system(command)
    if return_code != 0:
        print(f"\n--- ERROR: Step '{step_name}' failed! ---")
        sys.exit(1)

# --- פונקציה לסריקה ובחירת טסט ---
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

# --- Main script execution ---
try:
    ROOT_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    DESIGN_LAB = os.path.join(ROOT_DIR, "design")
    VERIFICATION_LAB = os.path.join(ROOT_DIR, "verification")
    SIM_LAB = os.path.join(ROOT_DIR, "sim")
    SCRIPTS = os.path.join(ROOT_DIR, "scripts")
    CURRENT_TEST_FILE = os.path.join(SIM_LAB, ".current_test")

    # --- בדיקת רישוי ---
    salt_server = os.environ.get("SALT_LICENSE_SERVER")
    if salt_server:
        print(f"SALT_LICENSE_SERVER = {salt_server}")
    else:
        print("\n--- WARNING: SALT_LICENSE_SERVER is not set! ---")

    # --- פרסינג ארגומנטים ---
    parser = argparse.ArgumentParser(description="Run QuestaSim simulation")
    parser.add_argument('--gui', action='store_true', help="Run simulation in GUI mode.")
    parser.add_argument('--seed', type=int, default=1, help="Random seed.")
    parser.add_argument('--test', type=str, help="Testbench name (tb_xxx).")
    args = parser.parse_args()

    # --- בחירת טסט ---
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

    # --- שמירת הבחירה לקובץ ---
    with open(CURRENT_TEST_FILE, "w") as f:
        f.write(args.test.strip())

    print(f"\n--- INFO: Selected Testbench: {args.test} ---")

    # --- ניקוי קבצים קודמים ---
    print("\n--- INFO: Cleaning previous run ---")
    cleanup_dirs = [os.path.join(SIM_LAB, "work"),
                    os.path.join(SIM_LAB, "design_work")]
    cleanup_files = [os.path.join(SIM_LAB, f"{args.test}.log"),
                     os.path.join(SIM_LAB, f"{args.test}.wlf")]

    for d in cleanup_dirs:
        if os.path.exists(d):
            print(f"Deleting directory: {d}")
            shutil.rmtree(d)

    for f in cleanup_files:
        if os.path.exists(f):
            print(f"Deleting file: {f}")
            os.remove(f)

    # --- קומפילציה ---
    CMD_COMPILE = f'vsim -c -do "{os.path.join(SCRIPTS, "compile.do")}"'
    run_command(CMD_COMPILE, "Compile")

    # --- אילבורציה ---
    CMD_ELABORATE = f'vsim -c -do "{os.path.join(SCRIPTS, "elaborate.do")}"'
    run_command(CMD_ELABORATE, "Elaborate")

    # --- סימולציה (הקטע המתוקן) ---
    log_file = os.path.join(SIM_LAB, f"{args.test}.log")
    wlf_file = os.path.join(SIM_LAB, f"{args.test}.wlf")
    ucdb_file = os.path.join(SIM_LAB, f"{args.test}.ucdb")
    top_module = args.test + "_opt"

    # *** התיקון הקריטי: יצירת משתנה חדש עם נתיבים בפורמט Tcl/Linux ***
    # זה פותר את בעיית ה-'\t' ב-Windows.
    tcl_ucdb_file = ucdb_file.replace(os.sep, '/') 

    # --- תוספת: הגדרת נתיב לקובץ הגדרות הגלים ---
    WAVE_FORMAT_DO = os.path.join(SCRIPTS, "wave_format.do")
    tcl_wave_format_do = WAVE_FORMAT_DO.replace(os.sep, '/')
    
    cmd = f'vsim {top_module} -coverage -voptargs=+acc -sv_seed {args.seed} -L design_work '
    
    # --- הגדרת פקודות TCL משותפות (Run ו-Coverage) ---
    tcl_commands_base = f'run -all; coverage save {tcl_ucdb_file};'


    if args.gui:
        # --- לוגיקה לטעינת גלים מותנית ---
        if os.path.exists(WAVE_FORMAT_DO):
            # אם הקובץ קיים, טוענים אותו.
            tcl_wave_command = f'do {tcl_wave_format_do};'
            print(f"INFO: Loading custom wave format from {WAVE_FORMAT_DO}")
        else:
            # אם חסר, מוסיפים גלים באופן גנרי ומדפיסים אזהרה
            tcl_wave_command = f'add wave -r /*;'
            print(f"WARNING: Wave format file not found at {WAVE_FORMAT_DO}. Adding all waves generically.")

        # בנית הפקודה המלאה למצב GUI
        tcl_full_command = tcl_wave_command + tcl_commands_base
        cmd += f'-gui -do "{tcl_full_command}"'
        
    else:
        # מצב Non-GUI נשאר ללא שינוי (רק מוסיפים quit -f)
        cmd += f'-c -logfile {log_file} -wlf {wlf_file} -do "{tcl_commands_base} quit -f"'

    run_command(cmd, "Simulate")

    print(f"\n--- INFO: All steps completed successfully. Check {log_file} for results. ---")

except Exception as e:
    print(f"--- ERROR: {e} ---")
    sys.exit(1)