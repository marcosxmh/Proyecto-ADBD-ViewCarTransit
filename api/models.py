from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Sede(db.Model):
    __tablename__ = 'sede'
    id_sede = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(50))
    direccion = db.Column(db.String(100))
    localidad = db.Column(db.String(50))
    calle = db.Column(db.String(50))
    numero = db.Column(db.String(10))
    telefono = db.Column(db.String(20))
    correo_contacto = db.Column(db.String(50))

    def serialize(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}

class Empresa(db.Model):
    __tablename__ = 'empresa'
    id_empresa = db.Column(db.Integer, primary_key=True)
    nombre = db.Column(db.String(50))
    tipo_empresa = db.Column(db.String(50))
    telefono = db.Column(db.String(20))
    correo_contacto = db.Column(db.String(50))

    def serialize(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}

class Paquete(db.Model):
    __tablename__ = 'paquete'
    id_paquete = db.Column(db.Integer, primary_key=True)
    descripcion = db.Column(db.String(255))
    peso = db.Column(db.Numeric(10, 2))

    def serialize(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}

class Vehiculo(db.Model):
    __tablename__ = 'vehiculo'
    matricula = db.Column(db.String(20), primary_key=True)
    modelo = db.Column(db.String(50))
    color = db.Column(db.String(20))
    estado = db.Column(db.String(20))

    def serialize(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}

class Conductor(db.Model):
    __tablename__ = 'conductor'
    dni = db.Column(db.String(20), primary_key=True)
    nombre = db.Column(db.String(50))
    apellido = db.Column(db.String(50))
    licencia = db.Column(db.String(50))

    def serialize(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}

class Conduce(db.Model):
    __tablename__ = 'conduce'
    dni = db.Column(db.String(20), db.ForeignKey('conductor.dni'), primary_key=True)
    matricula = db.Column(db.String(20), db.ForeignKey('vehiculo.matricula'), primary_key=True)

    def serialize(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}

class Envia(db.Model):
    __tablename__ = 'envia'
    id_empresa = db.Column(db.Integer, db.ForeignKey('empresa.id_empresa'), primary_key=True)
    id_paquete = db.Column(db.Integer, db.ForeignKey('paquete.id_paquete'), primary_key=True)
    destino = db.Column(db.String(100))
    fecha = db.Column(db.Date)

    def serialize(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}

class Contrata(db.Model):
    __tablename__ = 'contrata'
    id_empresa = db.Column(db.Integer, db.ForeignKey('empresa.id_empresa'), primary_key=True)
    matricula = db.Column(db.String(20), db.ForeignKey('vehiculo.matricula'), primary_key=True)
    fecha_ini = db.Column(db.Date)
    fecha_fin = db.Column(db.Date)

    def serialize(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}
