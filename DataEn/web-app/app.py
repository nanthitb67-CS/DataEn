import os
import time

from flask import Flask, render_template, request
import psycopg2

app = Flask(__name__)


def get_connection():
    return psycopg2.connect(
        host=os.getenv("DB_HOST", "localhost"),
        port=int(os.getenv("DB_PORT", 5432)),
        database=os.getenv("DB_NAME", "labdb"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "password123"),
    )


def wait_for_db(retries=30, delay=2):
    for _ in range(retries):
        try:
            conn = get_connection()
            conn.close()
            return
        except psycopg2.OperationalError:
            time.sleep(delay)
    raise RuntimeError("Cannot connect to PostgreSQL")


@app.route("/", methods=["GET", "POST"])
def index():
    employees = []
    department_stats = []
    department = ""
    action = request.form.get("action", "department")
    error = None

    if request.method == "POST" and action == "department":
        department = request.form.get("department", "").strip()

    try:
        conn = get_connection()
        cur = conn.cursor()

        if request.method == "POST" and action == "department" and department:
            cur.execute(
                """
                SELECT first_name, last_name, department, salary, hire_date
                FROM employees
                WHERE department ILIKE %s
                ORDER BY last_name, first_name
                """,
                (department,),
            )
            employees = cur.fetchall()
        elif request.method == "POST" and action == "department":
            cur.execute(
                """
                SELECT first_name, last_name, department, salary, hire_date
                FROM employees
                ORDER BY department, last_name, first_name
                """
            )
            employees = cur.fetchall()
        elif request.method == "POST" and action == "department_stats":
            cur.execute(
                """
                SELECT department, COUNT(*) AS employee_count,
                       AVG(salary) AS average_salary,
                       MAX(salary) AS highest_salary,
                       MIN(salary) AS lowest_salary
                FROM employees
                GROUP BY department
                ORDER BY department
                """
            )
            department_stats = cur.fetchall()
        elif request.method == "POST" and action == "above_department_average":
            cur.execute(
                """
                SELECT first_name, last_name, department, salary, hire_date,
                       (
                           SELECT AVG(e2.salary)
                           FROM employees e2
                           WHERE e2.department = e.department
                       ) AS department_average
                FROM employees e
                WHERE e.salary > (
                    SELECT AVG(e2.salary)
                    FROM employees e2
                    WHERE e2.department = e.department
                )
                ORDER BY department, salary DESC, last_name, first_name
                """
            )
            employees = cur.fetchall()

        cur.close()
        conn.close()
    except psycopg2.Error as exc:
        error = str(exc)

    return render_template(
        "index.html",
        employees=employees,
        department_stats=department_stats,
        department=department,
        action=action,
        error=error,
    )


if __name__ == "__main__":
    wait_for_db()
    app.run(host="0.0.0.0", port=5000, debug=True)
