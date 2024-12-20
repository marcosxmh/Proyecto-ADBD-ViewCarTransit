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
        cur.execute('SELECT id_empresa, empresa.nombre, tipo_empresa, empresa.telefono, empresa.correo_contacto, sede.nombre, empresa.id_sede \
                     FROM EMPRESA empresa \
                     JOIN SEDE sede ON empresa.id_sede = sede.id_sede')
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

@app.route('/vehiculos', methods=['GET', 'POST'])
def vehiculos():
    try:
        # Conectar con la base de datos
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
            
            try:
                if tipo == "furgoneta":
                    porton_lateral = request.form['porton']
                    if porton_lateral == "si":
                        porton_lateral = True
                    else:
                        porton_lateral = False
                    cur.execute(
                        'INSERT INTO FURGONETA (matricula, modelo, color, estado, id_sede, id_taller, porton_lateral) '
                        'VALUES (%s, %s, %s, %s, %s, %s, %s)',
                        (matricula, modelo, color, estado, id_sede, id_taller, porton_lateral)
                    )
                else:
                    trailer = request.form['trailer']
                    if trailer == "si":
                        trailer = True
                    else:
                        trailer = False
                    cur.execute(
                        'INSERT INTO CAMION (matricula, modelo, color, estado, id_sede, id_taller, tiene_trailer) '
                        'VALUES (%s, %s, %s, %s, %s, %s, %s)',
                        (matricula, modelo, color, estado, id_sede, id_taller, trailer)
                    )
                conn.commit()
                return redirect(url_for('vehiculos'))
            
            except DatabaseError as e:
                conn.rollback()
                abort(500)

        # Consultar todos los vehículos
        cur.execute('SELECT v.matricula, v.modelo, v.color, v.estado, s.nombre, v.id_sede, t.nombre, v.id_taller, v.porton_lateral \
                    FROM furgoneta v \
                    JOIN TALLER t ON v.id_taller = t.id_taller \
                    JOIN SEDE s ON v.id_sede = s.id_sede')
        furgonetas = cur.fetchall()
        cur.execute('SELECT v.matricula, v.modelo, v.color, v.estado, s.nombre, v.id_sede, t.nombre, v.id_taller, v.tiene_trailer \
                    FROM camion v \
                    JOIN TALLER t ON v.id_taller = t.id_taller \
                    JOIN SEDE s ON v.id_sede = s.id_sede')
        camiones = cur.fetchall()
        cur.close()
        conn.close()
        if not vehiculos:
            abort(404)

        return render_template('vehiculos.html', furgonetas=furgonetas, camiones=camiones), 200  # OK

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
    try:
        # Conectar con la base de datos
        conn = get_db_connection()
        cur = conn.cursor()

        if request.method == 'POST':
            dni = request.form['dni']
            nombre = request.form['nombre']
            apellidos = request.form['apellidos']
            licencia = request.form['licencia']
            try:
                cur.execute(
                    'INSERT INTO conductor (dni, nombre, apellidos, licencia) VALUES (%s, %s, %s, %s)',
                    (dni, nombre, apellidos, licencia)
                )
                conn.commit()
                return redirect(url_for('conductores'))
            except DatabaseError as e:
                conn.rollback()
                abort(500)

        # Consultar todos los vehículos
        cur.execute('SELECT * FROM conductor')
        conductores = cur.fetchall()
        cur.close()
        conn.close()
        if not conductores:
            abort(404)

        return render_template('conductores.html', conductores=conductores), 200  # OK

    except DatabaseError as e:
        abort(500)

    finally:
        # Asegurarse de cerrar la conexión a la base de datos
        if cur:
            cur.close()
        if conn:
            conn.close()

@app.route('/paquetes', methods=['GET', 'POST'])
def paquetes():
    try:
        # Conectar con la base de datos
        conn = get_db_connection()
        cur = conn.cursor()

        if request.method == 'POST':
            descripcion = request.form['descripcion']
            peso = request.form['peso']
            empresas = request.form['empresa']
            try:
                cur.execute(
                    'INSERT INTO paquete (descripcion, peso, id_empresa) '
                    'VALUES (%s, %s, %s)',
                    (descripcion, peso, empresas)
                )
                conn.commit()
                return redirect(url_for('paquetes'))
            except DatabaseError as e:
                conn.rollback()
                abort(500)

        # Consultar todos los vehículos
        cur.execute('SELECT p.id_paquete, p.descripcion, p.peso, e.nombre, p.id_empresa \
                    FROM paquete p \
                    JOIN empresa e ON p.id_empresa = e.id_empresa')
        paquetes = cur.fetchall()
        cur.close()
        conn.close()
        if not paquetes:
            abort(404)

        return render_template('paquetes.html', paquetes=paquetes), 200  # OK

    except DatabaseError as e:
        abort(500)

    finally:
        # Asegurarse de cerrar la conexión a la base de datos
        if cur:
            cur.close()
        if conn:
            conn.close()

@app.route('/envia/<int:id_empresa>', methods=['GET', 'POST'])
def manage_envia(id_empresa):
    try:
        # Conectar con la base de datos
        conn = get_db_connection()
        cur = conn.cursor()

        if request.method == 'POST':
            matricula = request.form['matricula']
            id_paquete = request.form['id_paquete']
            destino = request.form['destino']
            fecha = request.form['fecha']
            cur.execute('SELECT e.matricula, e.destino, e.fecha \
            FROM envia e \
            WHERE e.id_paquete = %s', (id_paquete,))
            current_data = cur.fetchone()

            # Si algún campo está vacío o es NULL, mantener el valor actual
            if not matricula:
                matricula = current_data[0]
            if not destino:
                destino = current_data[1]
            if not fecha:
                fecha = current_data[2]

            cur.execute(
                'UPDATE ENVIA \
                    SET matricula = %s, destino = %s, fecha = %s \
                    WHERE id_paquete = %s',
                (matricula, destino, fecha, id_paquete,)
            )
            try:
                # Obtener los valores actuales del paquete
                cur.execute('SELECT e.matricula, e.destino, e.fecha \
                            FROM envia e \
                            WHERE e.id_paquete = %s', (id_paquete,))
                current_data = cur.fetchone()

                # Si algún campo está vacío o es NULL, mantener el valor actual
                if not matricula:
                    matricula = current_data[0]
                if not destino:
                    destino = current_data[1]
                if not fecha:
                    fecha = current_data[2]

                cur.execute(
                    'UPDATE ENVIA \
                     SET matricula = %s, destino = %s, fecha = %s \
                     WHERE id_paquete = %s',
                    (matricula, destino, fecha, id_paquete,)
                )
                conn.commit()
                return redirect(url_for('manage_envia', id_empresa=id_empresa))
            except DatabaseError as e:
                conn.rollback()
                abort(500)

        # Consultar todos los vehículos
        cur.execute('SELECT e.matricula, e.id_paquete, e.destino, e.fecha \
                    FROM envia e \
                    WHERE e.id_empresa = %s', (id_empresa,))
        paquetes = cur.fetchall()
        cur.close()
        conn.close()
        if not paquetes:
            abort(404)

        return render_template('envia.html', paquetes=paquetes), 200
    
    except DatabaseError as e:
        abort(500)

    finally:
        # Asegurarse de cerrar la conexión a la base de datos
        if cur:
            cur.close()
        if conn:
            conn.close()        

# Endpoint para listar todas las empresas
@app.route('/mostrar_empresas', methods=['GET'])
def mostrar_empresas():
    conn = get_db_connection()
    cur = conn.cursor()
    
    # Obtener todas las empresas
    cur.execute('SELECT id_empresa, nombre FROM EMPRESA')
    empresas = cur.fetchall()
    
    cur.close()
    conn.close()

    # Renderizar la plantilla con las empresas
    return render_template('empresas_list.html', empresas=empresas)

@app.route('/delete_vehiculo', methods=('GET', 'POST'))
def delete_vehiculo():
    try:
        # Conectar con la base de datos
        conn = get_db_connection()
        cur = conn.cursor()

        if request.method == 'POST':
            matricula = request.form['matricula']
            tipo = request.form['tipo_vehiculo']
            try:
                if tipo == "furgoneta":
                    cur.execute(
                        'DELETE FROM FURGONETA WHERE matricula = %s',
                        (matricula,)
                    )
                else:
                    cur.execute(
                        'DELETE FROM CAMION WHERE matricula = %s',
                        (matricula,)
                    )
                conn.commit()
                return redirect(url_for('delete_vehiculo'))
            
            except DatabaseError as e:
                conn.rollback()
                abort(500)

        # Consultar todos los vehículos
        cur.execute('SELECT v.matricula, v.modelo, v.color, v.estado, s.nombre, v.id_sede, t.nombre, v.id_taller, v.porton_lateral \
                    FROM furgoneta v \
                    JOIN TALLER t ON v.id_taller = t.id_taller \
                    JOIN SEDE s ON v.id_sede = s.id_sede')
        furgonetas = cur.fetchall()
        cur.execute('SELECT v.matricula, v.modelo, v.color, v.estado, s.nombre, v.id_sede, t.nombre, v.id_taller, v.tiene_trailer \
                    FROM camion v \
                    JOIN TALLER t ON v.id_taller = t.id_taller \
                    JOIN SEDE s ON v.id_sede = s.id_sede')
        camiones = cur.fetchall()
        cur.close()
        conn.close()
        if not vehiculos:
            abort(404)

        return render_template('delete_vehiculo.html', furgonetas=furgonetas, camiones=camiones), 200  # OK

    except DatabaseError as e:
        abort(500)

    finally:
        # Asegurarse de cerrar la conexión a la base de datos
        if cur:
            cur.close()
        if conn:
            conn.close()














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
