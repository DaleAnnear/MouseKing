import sqlite3
import sys
import os

def check_integrity(database_path):
    print(f"Processing base: {database_path}", file=sys.stdout)
    try:
         # Check if the database file exists
        if not os.path.exists(database_path) or not database_path.endswith(".sqlite"):
            print(f"Database file does not exist: {database_path}", file=sys.stdout)
            return False
        else:
            print(f"Database file located: {database_path}", file=sys.stdout)
        
        # Connect to the SQLite database
        print(f"Attempting connection to database: {database_path}", file=sys.stdout)
        connection = sqlite3.connect(database_path)
        cursor = connection.cursor()
        print(f"Connection successfuly made to database: {database_path}", file=sys.stdout)

        # Execute the integrity check command
        cursor.execute("PRAGMA integrity_check;")
        result = cursor.fetchone()

        # Check and print the result
        if result[0] == 'ok':
            print("Integrity check passed: OK", file=sys.stdout)
            return True
        else:
            print(f"Integrity check failed: {result[0]}", file=sys.stdout)
            print("Integrity check passed: FAIL", file=sys.stdout)
            return False

    except sqlite3.Error as e:
        print(f"An error occurred: {e}", file=sys.stdout)
        print("Integrity check passed: ERROR", file=sys.stdout)
        return False

    finally:
        # Close the connection if it was successfully opened
        try:
            connection.close()
        except NameError:
            pass

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python check_integrity.py <path_to_sqlite_db>", file=sys.stdout)
        sys.exit(1)

    database_path = sys.argv[1]
    check_integrity(database_path)
    sys.exit(0)