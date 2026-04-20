import sqlite3
import sys
import os

def check_integrity(database_path):
    print(f"Processing base: {database_path}", file=sys.stdout)
    connection = None

    # Kill the script if the file is missing or not a sqlite file
    if not os.path.exists(database_path) or not database_path.endswith(".sqlite"):
        print(f"Database file does not exist: {database_path}", file=sys.stdout)
        sys.exit(1)

    print(f"Database file located: {database_path}", file=sys.stdout)

    try:
        # Open in read/write mode only; do not create a new DB if missing
        print(f"Attempting connection to database: {database_path}", file=sys.stdout)
        connection = sqlite3.connect(f"file:{database_path}?mode=rw", uri=True)
        cursor = connection.cursor()
        print(f"Connection successfully made to database: {database_path}", file=sys.stdout)

        # Execute the integrity check command
        cursor.execute("PRAGMA integrity_check;")
        result = cursor.fetchone()

        if result and result[0] == "ok":
            print("Integrity check passed: OK", file=sys.stdout)
            return True
        else:
            msg = result[0] if result else "No result returned"
            print(f"Integrity check failed: {msg}", file=sys.stdout)
            print("Integrity check passed: FAIL", file=sys.stdout)
            return False

    except sqlite3.Error as e:
        print(f"An error occurred while connecting/checking: {e}", file=sys.stdout)
        print("Integrity check passed: ERROR", file=sys.stdout)
        sys.exit(1)

    finally:
        if connection is not None:
            connection.close()

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python check_integrity.py <path_to_sqlite_db>", file=sys.stdout)
        sys.exit(1)

    database_path = sys.argv[1]
    check_integrity(database_path)
    sys.exit(0)