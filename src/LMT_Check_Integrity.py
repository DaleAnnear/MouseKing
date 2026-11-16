"""Check the physical integrity of an existing LiveMouseTracker SQLite database."""

import sqlite3
import sys
import os

def check_integrity(database_path):
    """Print the outcome and return whether SQLite reported an intact database.

    Exit with status 1 if the path is invalid or SQLite cannot complete the
    check. A completed check can return False with a FAIL marker.
    """
    print(f"Processing base: {database_path}", file=sys.stdout)
    connection = None

    if not os.path.exists(database_path) or not database_path.endswith(".sqlite"):
        print(f"Database file does not exist: {database_path}", file=sys.stdout)
        sys.exit(1)

    print(f"Database file located: {database_path}", file=sys.stdout)

    try:
        # mode=rw requires an existing file, even if it disappears after the path check.
        print(f"Attempting connection to database: {database_path}", file=sys.stdout)
        connection = sqlite3.connect(f"file:{database_path}?mode=rw", uri=True)
        cursor = connection.cursor()
        print(f"Connection successfully made to database: {database_path}", file=sys.stdout)

        # SQLite returns "ok" for an intact database or rows describing corruption.
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
    # The workflow reads the OK or FAIL marker from stdout after a completed check.
    check_integrity(database_path)
    sys.exit(0)
