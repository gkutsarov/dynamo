from flask import Flask, render_template, request, redirect, url_for
import psycopg2
import os

app = Flask(__name__)

# PostgreSQL connection config (adjust accordingly)
conn = psycopg2.connect(
    dbname=os.getenv("DB_NAME", "mydb"),
    user=os.getenv("DB_USER", "postgres"),
    password=os.getenv("DB_PASSWORD", "postgres"),
    host=os.getenv("DB_HOST", "localhost"),
    port=os.getenv("DB_PORT", "5432")
)
cur = conn.cursor()

@app.route('/')
def index():
    cur.execute("SELECT * FROM students ORDER BY id ASC;")
    students = cur.fetchall()
    return render_template('index.html', students=students)

@app.route('/create', methods=['GET', 'POST'])
def create():
    if request.method == 'POST':
        name = request.form['name']
        age = request.form['age']
        phone = request.form['phone']
        cur.execute("INSERT INTO students (name, age, phone) VALUES (%s, %s, %s);", (name, age, phone))
        conn.commit()
        return redirect(url_for('index'))
    return render_template('form.html', action="Create", student={})

@app.route('/edit/<int:student_id>', methods=['GET', 'POST'])
def edit(student_id):
    if request.method == 'POST':
        name = request.form['name']
        age = request.form['age']
        phone = request.form['phone']
        cur.execute("UPDATE students SET name = %s, age = %s, phone = %s WHERE id = %s;",
                    (name, age, phone, student_id))
        conn.commit()
        return redirect(url_for('index'))
    cur.execute("SELECT * FROM students WHERE id = %s;", (student_id,))
    student = cur.fetchone()
    return render_template('form.html', action="Edit", student=student)

@app.route('/delete/<int:student_id>')
def delete(student_id):
    cur.execute("DELETE FROM students WHERE id = %s;", (student_id,))
    conn.commit()
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000)
