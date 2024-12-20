# VIEW CAR TRANSIT

## Autores

Nombre: Ramiro\
Apellidos:Difonti Domé\
Curso: Administración y Diseño de Bases de datos\
E-mail: alu0101425030@ull.edu.es

Nombre: Ruymán\
Apellidos: García Martín\
Curso: Administración y Diseño de Bases de datos\
E-mail: alu0101408866@ull.edu.es

Nombre: Marcos\
Apellidos: Medinilla Hérnandez\
Curso: Administración y Diseño de Bases de datos\
E-mail: alu0101211206@ull.edu.es

## Diagrama Entidad Relacion

![Modelo ER_ViewCarTransit drawio](https://github.com/user-attachments/assets/483e8a93-5a9b-4eb7-b3fb-4f6405d00a6a)

## Diagrama Relacional

![Modelo relacional_ViewCarTransit drawio](https://github.com/user-attachments/assets/5805ae1f-d4f9-48d2-8701-c7546002b846)

## Ejecución del Script

Para ejecutar el script de la base de datos puede:

### Acceder a la terminal de linux y ejecutar el siguiente comando:

```bash
alumno@ull:~$ psql -U <user> -d <database> -f viewcartransit.sql
```

Donde:
- <user> es tu usuario en PostgreSQL
- <database> es alguna base de datos en tu sistema, ya que automáticamente se crea y conecta a la base de datos. Nosotros utilizamos viewcartransit.
Un ejemplo de ejecución podría ser:

```bash
alumno@ull:~$ psql -U ramirodifonti -d postgres -f viewcartransit.sql
```

### Acceder a la terminal de psql y ejecuta el siguiente comando:

```bash
postgres=# \i /[path]
```

## Ejecución de la API en flask

Para ejecutar la API y usar/operar con la base de datos, puede ejecutar alguno de los siguientes comandos:

```bash
alumno@ull:~$ flask app.py run
```

```bash
alumno@ull:~$ flask --app app.py run --host 0.0.0.0 --port 8080
```

## Licencia
[LICENSE](./LICENSE)
