from flask import Flask, render_template, request, jsonify
from models import db, Sede, Empresa, Paquete, Vehiculo, Conductor, Conduce, Envia, Contrata
from sqlalchemy.exc import SQLAlchemyError

app = Flask(__name__)
app.config.from_object('database_config')  # Configuración de PostgreSQL
db.init_app(app)

@app.route('/')
def index():
    return render_template('index.html')

@app.route('/view-data', methods=['GET'])
def view_data_page():
    return render_template('view_data.html')

@app.route('/add-data', methods=['GET'])
def add_data_page():
    return render_template('add_data.html')

@app.route('/modify-data', methods=['GET'])
def modify_data_page():
    return render_template('modify_data.html')

@app.route('/delete-data', methods=['GET'])
def delete_data_page():
    return render_template('delete_data.html')

@app.route('/select-company', methods=['GET'])
def select_company_page():
    return render_template('select_company.html')

@app.route('/view-company/<int:company_id>', methods=['GET'])
def view_company_details(company_id):
    try:
        company = Empresa.query.get(company_id)
        if not company:
            return jsonify({'error': 'Empresa no encontrada'}), 404

        # Obtener relaciones relacionadas con la empresa
        sedes = Sede.query.all()
        vehiculos = Vehiculo.query.join(Contrata).filter(Contrata.id_empresa == company_id).all()
        paquetes = Paquete.query.join(Envia).filter(Envia.id_empresa == company_id).all()
        conductores = Conductor.query.join(Conduce).join(Vehiculo).join(Contrata).filter(Contrata.id_empresa == company_id).all()

        return render_template('company_details.html', company=company.serialize(), sedes=sedes, vehiculos=[v.serialize() for v in vehiculos], paquetes=[p.serialize() for p in paquetes], conductores=[c.serialize() for c in conductores])
    except SQLAlchemyError as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    app.run(debug=True)
