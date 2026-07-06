#!/usr/bin/env python3
"""
Company Salary Management System - Database Deployment Script
Connect to openGauss and execute all SQL files in order.
"""
import pg8000.native
import os
import re
import sys
import io

# Force UTF-8 output
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# Connection config
HOST = 'localhost'
PORT = 5432
USER = 'gaussdb'
PASSWORD = 'Sunflower@2233'
DBNAME = 'TongyhMIS08'
ADMIN_DB = 'postgres'

BASE_DIR = os.path.dirname(os.path.abspath(__file__))

SQL_FILES = [
    '02_tables.sql',
    '03_indexes.sql',
    '04_views.sql',
    '05_triggers.sql',
    '06_procedures.sql',
    '07_test_data.sql',
]

def split_sql(content):
    """Split SQL text into individual statements, handling $$ blocks"""
    statements = []
    buf = []
    in_dollar = False
    dollar_tag = None

    i = 0
    while i < len(content):
        if not in_dollar:
            m = re.match(r'(\$\w*\$)', content[i:])
            if m:
                dollar_tag = m.group(1)
                in_dollar = True
                buf.append(content[i])
                i += 1
                continue

            if content[i] == ';':
                stmt = ''.join(buf).strip()
                if stmt:
                    statements.append(stmt)
                buf = []
                i += 1
                continue
        else:
            if content[i:i+len(dollar_tag)] == dollar_tag:
                in_dollar = False
                dollar_tag = None

        buf.append(content[i])
        i += 1

    stmt = ''.join(buf).strip()
    if stmt and not stmt.startswith('--') and not stmt.startswith('\\'):
        statements.append(stmt)

    return statements

def clean_sql(content):
    """Remove psql meta-commands"""
    lines = []
    for line in content.split('\n'):
        stripped = line.strip()
        if stripped.startswith('\\echo') or stripped.startswith('\\i '):
            continue
        lines.append(line)
    return '\n'.join(lines)

def run_file(conn, filepath):
    """Execute a single SQL file"""
    filename = os.path.basename(filepath)
    print(f'\n{"="*60}')
    print(f'>> Executing: {filename}')
    print(f'{"="*60}')

    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    content = clean_sql(content)
    statements = split_sql(content)

    ok = 0
    fail = 0
    for i, stmt in enumerate(statements):
        stmt = stmt.strip()
        if not stmt:
            continue
        try:
            conn.run(stmt)
            ok += 1
        except Exception as e:
            err_msg = str(e)
            # Ignore "already exists" errors
            if 'already exists' in err_msg.lower():
                ok += 1
                continue
            fail += 1
            preview = stmt[:120].replace('\n', ' ')
            print(f'  FAIL #{i+1}: {preview}...')
            print(f'         {err_msg[:200]}')

    print(f'  Result: {ok} OK, {fail} FAIL')
    return fail == 0

def main():
    print('=' * 60)
    print('  Company Salary Management System - DB Deploy')
    print(f'  openGauss @ {HOST}:{PORT}')
    print(f'  Target DB: {DBNAME}')
    print('=' * 60)

    # Step 1: Create database
    print(f'\n>> Connecting to {ADMIN_DB} to create {DBNAME}...')
    try:
        admin_conn = pg8000.native.Connection(
            host=HOST, port=PORT, user=USER,
            password=PASSWORD, database=ADMIN_DB
        )
        # Kill existing connections
        admin_conn.run(f"""
            SELECT pg_terminate_backend(pg_stat_activity.pid)
            FROM pg_stat_activity
            WHERE pg_stat_activity.datname = '{DBNAME}'
              AND pid <> pg_backend_pid();
        """)
        try:
            admin_conn.run(f'CREATE DATABASE "{DBNAME}" ENCODING = \'UTF8\';')
            print(f'  Database {DBNAME} created.')
        except Exception as e:
            if 'already exists' in str(e):
                print(f'  Database {DBNAME} already exists, skipping.')
            else:
                print(f'  Warning: {e}')
        admin_conn.close()
    except Exception as e:
        print(f'  FAILED to connect: {e}')
        sys.exit(1)

    # Step 2: Connect and deploy
    print(f'\n>> Connecting to {DBNAME}...')
    try:
        conn = pg8000.native.Connection(
            host=HOST, port=PORT, user=USER,
            password=PASSWORD, database=DBNAME
        )
        db_name = conn.run("SELECT current_database();")[0][0]
        print(f'  Connected: {db_name}')
    except Exception as e:
        print(f'  FAILED to connect to {DBNAME}: {e}')
        sys.exit(1)

    all_ok = True
    for sql_file in SQL_FILES:
        filepath = os.path.join(BASE_DIR, sql_file)
        if not os.path.exists(filepath):
            print(f'  WARN: file not found: {filepath}')
            all_ok = False
            continue
        if not run_file(conn, filepath):
            all_ok = False

    conn.close()

    print(f'\n{"="*60}')
    if all_ok:
        print('  ALL DONE - Database deployed successfully!')
    else:
        print('  DONE with some errors - check log above')
    print('=' * 60)

if __name__ == '__main__':
    main()
