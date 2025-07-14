from flask import Flask, render_template, request, redirect, url_for
import psycopg2
import os
from tenacity import retry, wait_fixed, stop_after_attempt, before_sleep_log
import logging

# Set up logging for retry feedback (optional, but useful)
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Retry DB connection up to 30 times (every 2 seconds = 60 seconds max)
@retry(wait=wait_fixed(2), stop=stop_after_attempt(30), before_sleep=before_sleep_log(logger, logging.WARNING))
def get_connection():
    return psycopg2.connect(
        dbname=os.getenv("DB_NAME", "mydb"),
        user=os.getenv("DB_USER", "postgres"),
        password=os.getenv("DB_PASSWORD", "postgres"),
        host=os.getenv("DB_HOST", "localhost"),
        port=os.getenv("DB_PORT", "5432")
    )

@app.route('/')
def index():
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("SELECT * FROM students ORDER BY id ASC;")
        students = cur.fetchall()
        cur.close()
        return render_template('index.html', students=students)
    finally:
        conn.close()

@app.route('/create', methods=['GET', 'POST'])
def create():
    if request.method == 'POST':
        conn = get_connection()
        try:
            cur = conn.cursor()
            name = request.form['name']
            age = request.form['age']
            phone = request.form['phone']
            cur.execute("INSERT INTO students (name, age, phone) VALUES (%s, %s, %s);", (name, age, phone))
            conn.commit()
            cur.close()
            return redirect(url_for('index'))
        finally:
            conn.close()
    return render_template('form.html', action="Create", student={})

@app.route('/edit/<int:student_id>', methods=['GET', 'POST'])
def edit(student_id):
    conn = get_connection()
    try:
        cur = conn.cursor()
        if request.method == 'POST':
            name = request.form['name']
            age = request.form['age']
            phone = request.form['phone']
            cur.execute("UPDATE students SET name = %s, age = %s, phone = %s WHERE id = %s;",
                        (name, age, phone, student_id))
            conn.commit()
            cur.close()
            return redirect(url_for('index'))
        cur.execute("SELECT * FROM students WHERE id = %s;", (student_id,))
        student = cur.fetchone()
        cur.close()
        return render_template('form.html', action="Edit", student=student)
    finally:
        conn.close()

@app.route('/delete/<int:student_id>')
def delete(student_id):
    conn = get_connection()
    try:
        cur = conn.cursor()
        cur.execute("DELETE FROM students WHERE id = %s;", (student_id,))
        conn.commit()
        cur.close()
        return redirect(url_for('index'))
    finally:
        conn.close()

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000)
