from flask import Flask, render_template, request, redirect, url_for
from sqlalchemy import create_engine, text
import os

app = Flask(__name__)

# Build the database URL from environment variables
DB_URL = (
    f"postgresql://{os.getenv('DB_USER', 'postgres')}:{os.getenv('DB_PASSWORD', 'postgres')}"
    f"@{os.getenv('DB_HOST', 'localhost')}:{os.getenv('DB_PORT', '5432')}/{os.getenv('DB_NAME', 'mydb')}"
)

# Create SQLAlchemy engine with connection pooling and auto-reconnect
engine = create_engine(DB_URL, pool_pre_ping=True)

@app.route('/')
def index():
    with engine.connect() as conn:
        result = conn.execute(text("SELECT * FROM students ORDER BY id ASC;"))
        students = result.fetchall()
    return render_template('index.html', students=students)

@app.route('/create', methods=['GET', 'POST'])
def create():
    if request.method == 'POST':
        name = request.form['name']
        age = request.form['age']
        phone = request.form['phone']
        with engine.begin() as conn:
            conn.execute(
                text("INSERT INTO students (name, age, phone) VALUES (:name, :age, :phone)"),
                {"name": name, "age": age, "phone": phone}
            )
        return redirect(url_for('index'))
    return render_template('form.html', action="Create", student={})

@app.route('/edit/<int:student_id>', methods=['GET', 'POST'])
def edit(student_id):
    if request.method == 'POST':
        name = request.form['name']
        age = request.form['age']
        phone = request.form['phone']
        with engine.begin() as conn:
            conn.execute(
                text("UPDATE students SET name = :name, age = :age, phone = :phone WHERE id = :id"),
                {"name": name, "age": age, "phone": phone, "id": student_id}
            )
        return redirect(url_for('index'))
    with engine.connect() as conn:
        result = conn.execute(text("SELECT * FROM students WHERE id = :id"), {"id": student_id})
        student = result.fetchone()
    return render_template('form.html', action="Edit", student=student)

@app.route('/delete/<int:student_id>')
def delete(student_id):
    with engine.begin() as conn:
        conn.execute(text("DELETE FROM students WHERE id = :id"), {"id": student_id})
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=5000)
