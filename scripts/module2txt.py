import os
import shutil

def safe_convert_to_txt():
    # --- חלק חדש: שינוי מיקום העבודה למיקום הסקריפט ---
    # משיג את הנתיב המלא של הקובץ הזה (הסקריפט עצמו)
    script_path = os.path.abspath(__file__)
    # מחלץ את התיקייה שבה הסקריפט נמצא
    script_dir = os.path.dirname(script_path)
    # משנה את תיקיית העבודה הנוכחית לתיקייה של הסקריפט
    os.chdir(script_dir)
    
    print(f"Working directory set to: {script_dir}")
    # ----------------------------------------------------

    # כעת base_path הוא בוודאות התיקייה שבה הסקריפט נמצא
    base_path = script_dir
    project_root = os.path.dirname(base_path)
    
    # רשימת התיקיות לסריקה (design ו-verification בלבד)
    source_folders = [
        os.path.join(project_root, "design"),
        os.path.join(project_root, "verification")
    ]
    
    # נתיב תיקיית היעד
    dest_folder = os.path.join(project_root, "docs", "sv_as_txt")

    # יצירת תיקיית היעד
    if not os.path.exists(dest_folder):
        os.makedirs(dest_folder)
        print(f"Created destination folder: {dest_folder}")

    files_converted = 0
    
    for folder in source_folders:
        if not os.path.exists(folder):
            print(f"Skipping (not found): {folder}")
            continue
            
        # סריקה רקורסיבית
        for root, dirs, files in os.walk(folder):
            for file in files:
                source_file_path = os.path.join(root, file)
                
                # הסרת הסיומת המקורית והוספת .txt
                filename_without_ext = os.path.splitext(file)[0]
                new_filename = f"{filename_without_ext}.txt"
                
                dest_file_path = os.path.join(dest_folder, new_filename)
                
                try:
                    # העתקה בטוחה (יוצר/דורס ביעד, לא נוגע במקור)
                    shutil.copy2(source_file_path, dest_file_path)
                    print(f"Copied: {file}  >>>  {new_filename}")
                    files_converted += 1
                except Exception as e:
                    print(f"Error with file {file}: {e}")

    print("-" * 30)
    print(f"Done. {files_converted} files copied to 'docs/all_scripts_txt'.")

if __name__ == "__main__":
    safe_convert_to_txt()