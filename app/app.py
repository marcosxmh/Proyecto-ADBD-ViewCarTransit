from flask import Flask, abort, render_template, request, redirect, url_for, jsonify
import psycopg2
from psycopg2 import DatabaseError

# Configuración inicial
app = Flask(__name__)

# Conexión a la base de datos
def get_db_connection():
    return psycopg2.connect(
        host='localhost',
        database='viewcartransit',
        user='postgres',
        password='ramirodifonti'
    )


# Rutas para la API
@app.route('/')
def index():
    return render_template('index.html')

@app.route('/empresas', methods=['GET', 'POST'])
def empresas():
    try:
        # Conectar con la base de datos
        conn = get_db_connection()
        cur = conn.cursor()

        if request.method == 'POST':
            # Capturar los datos del formulario
            nombre = request.form.get('nombre')
            tipo = request.form.get('tipo_empresa')
            telefono = request.form.get('telefono')
            correo = request.form.get('correo_contacto')
            id_sede = request.form.get('id_sede')

            try:
                # Insertar los datos en la tabla EMPRESA
                cur.execute(
                    '''
                    INSERT INTO EMPRESA (nombre, tipo_empresa, telefono, correo_contacto, id_sede)
                    VALUES (%s, %s, %s, %s, %s)
                    ''',
                    (nombre, tipo, telefono, correo, id_sede)
                )
                conn.commit()
                return redirect(url_for('empresas'))
            except DatabaseError as e:
                conn.rollback()
                abort(500)

        # Consultar todas las empresas
        cur.execute('SELECT * FROM EMPRESA')
        empresas = cur.fetchall()

        if not empresas:
            abort(404)

        return render_template('empresas.html', empresas=empresas), 200  # OK

    except DatabaseError as e:
        abort(500)

    finally:
        # Asegurarse de cerrar la conexión a la base de datos
        if cur:
            cur.close()
        if conn:
            conn.close()

@app.route('/conductores', methods=['GET', 'POST'])
def conductores():
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == 'POST':
        nombre = request.form['nombre']
        apellido = request.form['apellido']
        telefono = request.form['telefono']
        id_empresa = request.form['id_empresa']

        cur.execute(
            'INSERT INTO conductor (nombre, apellido, telefono, id_empresa) VALUES (%s, %s, %s, %s)',
            (nombre, apellido, telefono, id_empresa)
        )
        conn.commit()
        return redirect(url_for('conductores'))

    cur.execute('SELECT * FROM conductor')
    conductores = cur.fetchall()
    cur.close()
    conn.close()

    return render_template('conductores.html', conductores=conductores)


@app.route('/paquetes', methods=['GET', 'POST'])
def paquetes():
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == 'POST':
        descripcion = request.form['descripcion']
        peso = request.form['peso']
        empresas = request.form['empresas']

        # Validar campos
        if not descripcion or not destinatario:
            return "Campos obligatorios faltantes", 400

        cur.execute(
            'INSERT INTO paquete (descripcion, peso, empresa) '
            'VALUES (%s, %s, %s, %s, %s)',
            (descripcion, peso, empresas)
        )
        conn.commit()
        return redirect(url_for('paquetes'))

    cur.execute('SELECT * FROM paquete')
    paquetes = cur.fetchall()
    cur.close()
    conn.close()

    return render_template('paquetes.html', paquetes=paquetes)

@app.route('/paquetes/<int:paquete_id>', methods=['GET', 'PUT', 'DELETE'])
def paquete_detalle(paquete_id):
    conn = get_db_connection()
    cur = conn.cursor()

    if request.method == 'PUT':
        datos = request.get_json()
        cur.execute(
            'UPDATE paquete SET descripcion = %s, peso = %s, dimensiones = %s, destinatario = %s, estado = %s '
            'WHERE id = %s',
            (datos['descripcion'], datos['peso'], datos['dimensiones'], datos['destinatario'], datos['estado'], paquete_id)
        )
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'mensaje': 'Paquete actualizado'}), 200

    elif request.method == 'DELETE':
        cur.execute('DELETE FROM paquete WHERE id = %s', (paquete_id,))
        conn.commit()
        cur.close()
        conn.close()
        return jsonify({'mensaje': 'Paquete eliminado'}), 200

    cur.execute('SELECT * FROM paquete WHERE id = %s', (paquete_id,))
    paquete = cur.fetchone()
    cur.close()
    conn.close()

    return jsonify(paquete)



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
        tipo = request.form['tipo_vehiculo']

        if tipo == "furgoneta":
            porton_lateral = request.form['porton']
            cur.execute(
                'INSERT INTO FURGONETA (matricula, modelo, color, estado, id_sede, id_taller, porton_lateral) '
                'VALUES (%s, %s, %s, %s, %s, %s)',
                (matricula, modelo, color, estado, id_sede, id_taller, porton_lateral)
            )
        else:
            trailer = request.form['trailer']
            cur.execute(
                'INSERT INTO CAMION (matricula, modelo, color, estado, id_sede, id_taller, tiene_trailer) '
                'VALUES (%s, %s, %s, %s, %s, %s)',
                (matricula, modelo, color, estado, id_sede, id_taller, trailer)
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

# Errores
@app.errorhandler(400)
def bad_request(error):
    return render_template('error.html', 
                           error_code=400, 
                           error_message="Bad Request", 
                           error_description="The server could not understand the request."), 400

@app.errorhandler(404)
def page_not_found(error):
    return render_template('error.html', 
                           error_code=404, 
                           error_message="Page Not Found", 
                           error_description="The page you are looking for does not exist."), 404

@app.errorhandler(500)
def internal_server_error(error):
    return render_template('error.html', 
                           error_code=500, 
                           error_message="Internal Server Error", 
                           error_description="Something went wrong on our end. Please try again later."), 500

# Inicio de la aplicación
if __name__ == '__main__':
    app.run(debug=True)
