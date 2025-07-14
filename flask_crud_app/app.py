from flask import Flask, render_template, request, redirect, url_for
import psycopg2
import os
from tenacity import retry, wait_fixed, stop_after_attempt, before_sleep_log, retry_if_exception_type
import logging

# Setup logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

@retry(
    wait=wait_fixed(2),
    stop=stop_after_attempt(50),
    before_sleep=before_sleep_log(logger, logging.WARNING),
    retry=retry_if_exception_type((psycopg2.OperationalError, psycopg2.InterfaceError))
)
def query_with_fetch(query, params=None):
    conn = psycopg2.connect(
        dbname=os.getenv("DB_NAME", "mydb"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "postgres"),
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432")
    )
    try:
        with conn.cursor() as cur:
            cur.execute(query, params)
            result = cur.fetchall()
            conn.commit()
            return result
    finally:
        conn.close()

@retry(
    wait=wait_fixed(2),
    stop=stop_after_attempt(50),
    before_sleep=before_sleep_log(logger, logging.WARNING),
    retry=retry_if_exception_type((psycopg2.OperationalError, psycopg2.InterfaceError))
)
def query_no_fetch(query, params=None):
    conn = psycopg2.connect(
        dbname=os.getenv("DB_NAME", "mydb"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "postgres"),
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432")
    )
    try:
        with conn.cursor() as cur:
            cur.execute(query, params)
            conn.commit()
    finally:
        conn.close()


@app.route('/')
def index():
    students = query_with_fetch("SELECT * FROM students ORDER BY id ASC;")
    return render_template('index.html', students=students)

@app.route('/create', methods=['GET', 'POST'])
def create():
    if request.method == 'POST':
        name = request.form['name']
        age = request.form['age']
        phone = request.form['phone']
        query_no_fetch("INSERT INTO students (name, age, phone) VALUES (%s, %s, %s);", (name, age, phone))
        return redirect(url_for('index'))
    return render_template('form.html', action="Create", student={})

@app.route('/edit/<int:student_id>', methods=['GET', 'POST'])
def edit(student_id):
    if request.method == 'POST':
        name = request.form['name']
        age = request.form['age']
        phone = request.form['phone']
        query_no_fetch(
            "UPDATE students SET name = %s, age = %s, phone = %s WHERE id = %s;",
            (name, age, phone, student_id)
        )
        return redirect(url_for('index'))
    student = query_with_fetch("SELECT * FROM students WHERE id = %s;", (student_id,))[0]
    return render_template('form.html', action="Edit", student=student)

@app.route('/delete/<int:student_id>')
def delete(student_id):
    query_no_fetch("DELETE FROM students WHERE id = %s;", (student_id,))
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000)
