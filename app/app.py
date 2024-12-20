from flask import Flask, render_template, request, redirect, url_for, jsonify
import psycopg2

# Configuración inicial
app = Flask(__name__)

# Conexión a la base de datos
def get_db_connection():
    return psycopg2.connect(
        host='localhost',
        database='viewcartransit',
        user='postgres',
        password='1234'
    )

# Rutas para la API
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/empresas', methods=['GET', 'POST'])
def empresas():
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == 'POST':
        nombre = request.form['nombre']
        direccion = request.form['direccion']
        telefono = request.form['telefono']

        cur.execute(
            'INSERT INTO empresa (nombre, direccion, telefono) VALUES (%s, %s, %s)',
            (nombre, direccion, telefono)
        )
        conn.commit()
        return redirect(url_for('empresas'))

    cur.execute('SELECT * FROM empresa')
    empresas = cur.fetchall()
    cur.close()
    conn.close()

    return render_template('empresas.html', empresas=empresas)

@app.route('/empresas/<int:empresa_id>', methods=['GET', 'PUT', 'DELETE'])
def empresa_detalle(empresa_id):
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == 'PUT':
        datos = request.get_json()
        cur.execute(
            'UPDATE empresa SET nombre = %s, direccion = %s, telefono = %s WHERE id = %s',
            (datos['nombre'], datos['direccion'], datos['telefono'], empresa_id)
        )
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'mensaje': 'Empresa actualizada'}), 200

    elif request.method == 'DELETE':
        cur.execute('DELETE FROM empresa WHERE id = %s', (empresa_id,))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'mensaje': 'Empresa eliminada'}), 200

    cur.execute('SELECT * FROM empresa WHERE id = %s', (empresa_id,))
    empresa = cur.fetchone()
    cur.close()
    conn.close()

    return jsonify(empresa)


@app.route('/vehiculos', methods=['GET', 'POST'])
def vehiculos():
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == 'POST':
        matricula = request.form['matricula']
        modelo = request.form['modelo']
        color = request.form['color']
        estado = request.form['estado']
        id_sede = request.form['id_sede']
        id_taller = request.form['id_taller']
        
        cur.execute(
            'INSERT INTO vehiculo (matricula, modelo, color, estado, id_sede, id_taller) '
            'VALUES (%s, %s, %s, %s, %s, %s)',
            (matricula, modelo, color, estado, id_sede, id_taller)
        )
        conn.commit()
        return redirect(url_for('vehiculos'))

    cur.execute('SELECT * FROM vehiculo')
    vehiculos = cur.fetchall()
    cur.close()
    conn.close()

    return render_template('vehiculos.html', vehiculos=vehiculos)

@app.route('/vehiculos/<string:matricula>', methods=['GET', 'PUT', 'DELETE'])
def vehiculo_detalle(matricula):
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == 'PUT':
        datos = request.get_json()
        cur.execute(
            'UPDATE vehiculo SET modelo = %s, color = %s, estado = %s, id_sede = %s, id_taller = %s '
            'WHERE matricula = %s',
            (datos['modelo'], datos['color'], datos['estado'], datos['id_sede'], datos['id_taller'], matricula)
        )
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'mensaje': 'Vehículo actualizado'}), 200

    elif request.method == 'DELETE':
        cur.execute('DELETE FROM vehiculo WHERE matricula = %s', (matricula,))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'mensaje': 'Vehículo eliminado'}), 200

    cur.execute('SELECT * FROM vehiculo WHERE matricula = %s', (matricula,))
    vehiculo = cur.fetchone()
    cur.close()
    conn.close()

    return jsonify(vehiculo)

# Inicio de la aplicación
if __name__ == '__main__':
    app.run(debug=True)
