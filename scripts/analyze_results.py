import sys
import os
import re
from collections import Counter

# --- הגדרת צבעים לטרמינל ---
class Colors:
    HEADER = '\033[95m'
    OKGREEN = '\033[92m'
    WARNING = '\033[93m'
    FAIL = '\033[91m'
    ENDC = '\033[0m'
    BOLD = '\033[1m'

def clean_ansi(text):
    ansi_escape = re.compile(r'\x1B(?:[@-Z\\-_]|\[[0-?]*[ -/]*[@-~])')
    return ansi_escape.sub('', text)

def analyze_log(log_file_path):
    if not os.path.exists(log_file_path):
        print(f"Error: Log file not found at {log_file_path}")
        return

    report_file_path = os.path.join(os.path.dirname(log_file_path), "summary_report.txt")
    report_lines = []

    def log(msg, color=""):
        print(f"{color}{msg}{Colors.ENDC}")
        report_lines.append(clean_ansi(msg))

    matches = 0
    mismatches = 0
    errors = 0
    assertion_fails = 0
    
    error_details = []
    mismatch_details = []

    log(f"\n--- Parsing Log File: {os.path.basename(log_file_path)} ---", Colors.HEADER)

    # שימוש ב-encoding utf-8 ו-errors='ignore' למניעת קריסות בקריאה
    with open(log_file_path, 'r', encoding='utf-8', errors='ignore') as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            
            if "MATCH!" in line:
                matches += 1
            elif "MISMATCH!" in line:
                mismatches += 1
                mismatch_details.append(f"[Line {line_num}] {line}")
            elif "** Error" in line or "Error:" in line:
                errors += 1
                error_details.append(f"[Line {line_num}] {line}")
                if "SVA" in line or "Assertion" in line:
                    assertion_fails += 1

    log("-" * 60)
    log("SIMULATION SUMMARY", Colors.BOLD)
    log("-" * 60)
    
    log(f"Total Transactions (PASS):   {matches}", Colors.OKGREEN)
    
    if mismatches > 0:
        log(f"Scoreboard Mismatches:       {mismatches}", Colors.FAIL)
    else:
        log(f"Scoreboard Mismatches:       0", Colors.OKGREEN)
        
    if errors > 0:
        log(f"Total Errors:                {errors}", Colors.FAIL)
        log(f"   -> Protocol/SVA Fails:    {assertion_fails}", Colors.FAIL)
    else:
        log(f"Total Errors:                0", Colors.OKGREEN)

    log("-" * 60)

    # --- לוגיקת החלטה (PASS/FAIL) ---
    if mismatches > 0 or errors > 0:
        log("\n=== FAILURE DETAILS ===", Colors.FAIL)
        
        if mismatch_details:
            log("\n--- Scoreboard Mismatches ---", Colors.WARNING)
            for msg in mismatch_details[:20]: 
                log(f"  {msg}")
                
        if error_details:
            log("\n--- System/Protocol Errors (Unique) ---", Colors.WARNING)
            
            # 1. ניקוי מספרי שורות כדי לזהות שגיאות זהות
            clean_errors = [re.sub(r'\[Line \d+\] ', '', msg) for msg in error_details]
            # 2. ספירה
            error_counts = Counter(clean_errors)
            
            # 3. הדפסה
            for msg, count in error_counts.items():
                log(f"  [x{count}] {msg}")
                
        log(f"\nStatus: FAILED [X]", Colors.FAIL)
        final_status = "FAILED"
    
    else:
        # זה הבלוק שהיה חסר לך!
        log(f"\nStatus: PASSED [V]", Colors.OKGREEN)
        final_status = "PASSED"

    # --- שמירה לקובץ ---
    try:
        with open(report_file_path, 'w', encoding='utf-8') as f:
            f.write("\n".join(report_lines))
        print(f"\nFull report saved to: {report_file_path}")
    except Exception as e:
        print(f"Could not save report file: {e}")

    # יציאה עם קוד מתאים (0 להצלחה, 1 לכישלון)
    sys.exit(1 if final_status == "FAILED" else 0)

if __name__ == "__main__":
    if len(sys.argv) > 1:
        analyze_log(sys.argv[1])
    else:
        # ברירת מחדל לדיבאג
        default_log = os.path.join(os.path.dirname(__file__), "..", "sim", "tb_top_timer.log")
        analyze_log(default_log)