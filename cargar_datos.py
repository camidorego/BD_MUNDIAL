import psycopg2
import random
from faker import Faker

# IMPORTANTE: asegurarse de que la informacion sea correcta
# establecemos los parametros para conectarmos a la base de datos
conn = psycopg2.connect(
    host="localhost", database="tp_mundial", user="postgres", password="12345"
)

fake = Faker()

# las posiciones que puede tener un jugador
posiciones = ["Arquero", "Defensa", "Delantero"]

# solo hay 80 paises que alguna vez participaron en un mudial de futbol
paises = [
    "Argentina",
    "Brasil",
    "España",
    "Alemania",
    "Italia",
    "Francia",
    "Inglaterra",
    "Uruguay",
    "Holanda",
    "Suecia",
    "Bélgica",
    "Checoslovaquia",
    "Hungría",
    "Yugoslavia",
    "Rusia",
    "Portugal",
    "Croacia",
    "Grecia",
    "Dinamarca",
    "Suiza",
    "Polonia",
    "México",
    "Estados Unidos",
    "Corea del Sur",
    "Turquía",
    "Bulgaria",
    "Austria",
    "Chile",
    "Paraguay",
    "Colombia",
    "Costa Rica",
    "Argelia",
    "Rumania",
    "Escocia",
    "Egipto",
    "Irlanda",
    "Marruecos",
    "Camerún",
    "Nigeria",
    "Japón",
    "Australia",
    "Irán",
    "Arabia Saudita",
    "Senegal",
    "Eslovenia",
    "Sudáfrica",
    "Ucrania",
    "Serbia",
    "Ghana",
    "Costa de Marfil",
    "Túnez",
    "Suecia",
    "Perú",
    "Irlanda del Norte",
    "Panamá",
    "Islandia",
    "Gales",
    "Honduras",
    "Trinidad y Tobago",
    "Ecuador",
    "Camerún",
    "Eslovaquia",
    "Nueva Zelanda",
    "Escocia",
    "Argelia",
    "Bosnia y Herzegovina",
    "Austria",
    "Corea del Norte",
    "Eslovenia",
    "Australia",
    "Polonia",
    "Hungría",
    "Congo",
    "China",
    "Egipto",
    "El Salvador",
    "Finlandia",
    "Senegal",
    "Haiti",
    "Kenya",
    "Salta",
    "Nigeria",
]

letras_nombre_grupo = ["A", "B", "C", "D", "E", "F", "G", "H"]

# creamos un cursor
cursor = conn.cursor()

# se cargan las 6 fases en la tabla Fase
cursor.execute(
    "INSERT INTO fase(nombre_fase) VALUES ('grupos'),('octavos'),('cuartos'),('semifinal'),('final'),('tercer puesto')"
)
total_estadios = 0
# se cargan los paises en la tabla Pais
for i in range(len(paises)):
    nombre = paises[i]
    cantidad_estadios = random.randint(1, 10)
    insert_query = "INSERT INTO pais (nombre, cantidad_estadios) VALUES (%s, %s)"
    data = (nombre, cantidad_estadios)
    cursor.execute(insert_query, data)
    total_estadios += cantidad_estadios
    for j in range(cantidad_estadios):
        ciudad = fake.city()
        capacidad = fake.random_int(min=10000, max=80000)
        nombre_estadio = (
            fake.name()  # nombres reales de estadios reales ya es mucho trabajo xd
        )
        cursor.execute(
            "INSERT INTO estadio (nombre_estadio, id_pais,ciudad,capacidad) VALUES (%s, %s,%s,%s)",
            (nombre_estadio, i + 1, ciudad, capacidad),
        )

# se cargan 50,000 personas de las cuales 40,000 son jugadores, 5,000 son árbitros y 5,000 son entrenadores
for i in range(50000):
    nombre_persona = f"{fake.first_name_male()} {fake.last_name()}"
    ci_persona = fake.random_int(min=1000000, max=9999999)
    fecha_nacimiento = fake.date_of_birth()
    nacionalidad_persona = fake.country()
    cursor.execute(
        "INSERT INTO persona (ci_persona, nombre_persona, fecha_nacimiento, nacionalidad_persona) VALUES (%s, %s, %s, %s)",
        (ci_persona, nombre_persona, fecha_nacimiento, nacionalidad_persona),
    )

    # las personas con id_persona entre 1 y 40,000 son jugadores
    if i < 40000:
        numero = fake.random_int(min=1, max=99)
        id_persona = i + 1
        popularidad = fake.random_int(min=1, max=10)
        cursor.execute(
            "INSERT INTO jugador (id_persona, numero, popularidad) VALUES (%s, %s, %s)",
            (id_persona, numero, popularidad),
        )

    # las personas con id_persona entre 40,000 y 45,000 son entrenadores
    elif i >= 40000 and i < 45000:
        id_persona = i + 1
        periodo_de_entrenador = fake.word()
        cursor.execute(
            "INSERT INTO entrenador (id_persona, periodo_de_entrenador) VALUES (%s, %s)",
            (id_persona, periodo_de_entrenador),
        )

    # las personas con id_persona entre 45,000 y 50,000 son árbitros
    else:
        id_persona = i + 1
        cursor.execute("INSERT INTO arbitro (id_persona) VALUES (%s)", (id_persona,))

cantidad_jugadores = 22
# se cargan 3600 mundiales
for m in range(3600):
    id_pais = fake.random_int(min=1, max=80)
    anho = 1900 + m

    cursor.execute(
        "INSERT INTO mundial (id_pais, anho) VALUES (%s, %s)", (id_pais, anho)
    )

    # se cargan 8 grupos por cada mundial
    for g in range(8):
        nombre_grupo = letras_nombre_grupo[g]
        id_mundial = m + 1

        cursor.execute(
            "INSERT INTO grupo (nombre_grupo, id_mundial) VALUES (%s, %s)",
            (nombre_grupo, id_mundial),
        )
        # se cargan 4 equipos en cada grupo
        for eq in range(4):
            id_pais = fake.random_int(min=1, max=80)
            id_grupo = g + 1 + m * 8

            cursor.execute(
                "INSERT INTO equipo (id_pais, id_grupo) VALUES (%s, %s)",
                (id_pais, id_grupo),
            )
            # a cada equipo se le asigna 1 entrenador
            id_entrenador = fake.random_int(min=1, max=50)
            cursor.execute(
                "INSERT INTO entrenador_x_equipo(id_entrenador, id_equipo) VALUES (%s, %s)",
                (id_entrenador, (eq + 1) + (g * 4) + (m * 32)),
            )
            # a cada equipo se le asignan 11 jugadores
            for j in range(11):
                cursor.execute(
                    "INSERT INTO jugador_x_equipo(id_jugador, id_equipo) VALUES (%s, %s)",
                    (
                        # solo tenemos 40mil jugadores entonces el id_jugador se debe mantener en el rango de 1 y 40mil
                        (j + (eq * 11) + (g * 44) + (m * 352)) % 40000 + 1,
                        (eq + 1) + (g * 4) + (m * 32),
                    ),
                )
        # cada grupo juega 6 partidos
        for p in range(6):
            id_mundial = m + 1
            fecha = fake.date()
            id_estadio = fake.random_int(min=1, max=total_estadios)
            id_arbitro = fake.random_int(min=1, max=50)
            id_fase = 1
            if p < 3:
                id_local = 1 + (4 * g) + (32 * m)
                id_visitante = p + (2 + (4 * g) + (32 * m))
            elif p >= 3 and p < 5:
                id_local = 2 + (4 * g) + (32 * m)
                id_visitante = p - 2 + (2 + (4 * g) + (32 * m))

            else:
                id_local = 3 + (4 * g) + (32 * m)
                id_visitante = 4 + (4 * g) + (32 * m)

            cursor.execute(
                "INSERT INTO partido(id_mundial, id_estadio, id_fase, id_arbitro, id_local, id_visitante, fecha, cantidad_jugadores) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
                (
                    id_mundial,
                    id_estadio,
                    id_fase,
                    id_arbitro,
                    id_local,
                    id_visitante,
                    fecha,
                    cantidad_jugadores,
                ),
            )
            gol_local = 0
            gol_visitante = 0
            # cada partido tiene 22 estadisticas
            for es in range(22):
                if es < 11:
                    id_jugador = ((id_local * 11) - 11 + es) % 40000 + 1

                else:
                    id_jugador = ((id_visitante * 11) - 22 + es) % 40000 + 1

                asistencias = fake.random_int(min=0, max=10)
                tiempo_jugado = fake.date_time()
                posicion = random.choice(posiciones)
                faltas = fake.random_int(min=0, max=10)
                perdida_posesion = fake.random_int(min=0, max=10)
                tarjeta_amarilla = fake.random_int(min=0, max=2)
                tarjeta_roja = fake.random_int(min=0, max=1)
                tiros = fake.random_int(min=0, max=20)
                pases_clave = fake.random_int(min=0, max=10)
                atajadas = fake.random_int(min=0, max=10)
                paradas_penales = fake.random_int(min=0, max=5)
                recuperaciones = fake.random_int(min=0, max=10)
                goles = fake.random_int(min=0, max=5)

                # se suman en las variables para luego determinar el ganador
                if es < 11:
                    gol_local += goles
                else:
                    gol_visitante += goles

                cursor.execute(
                    "INSERT INTO estadistica (id_partido, id_jugador, asistencias, tiempo_jugado, posicion, goles, faltas, perdida_posesion, tarjeta_amarilla, tarjeta_roja, tiros, pases_clave, atajadas, paradas_penales, recuperaciones) \
                VALUES (%s, %s,%s, %s,%s, %s,%s, %s,%s, %s,%s, %s,%s, %s,%s)",
                    (
                        p + 1 + (6 * g) + (m * 64),
                        id_jugador,
                        asistencias,
                        tiempo_jugado,
                        posicion,
                        goles,
                        faltas,
                        perdida_posesion,
                        tarjeta_amarilla,
                        tarjeta_roja,
                        tiros,
                        pases_clave,
                        atajadas,
                        paradas_penales,
                        recuperaciones,
                    ),
                )
            # cuando se generaron las 22 estadisticas se define el ganador y se carga en la tabla resultado
            if gol_local < gol_visitante:
                print("gana visitante")
                cursor.execute(
                    "INSERT INTO resultado (id_partido, id_equipo_ganador) VALUES (%s, %s)",
                    (
                        p + 1 + (6 * g) + (m * 64),
                        id_visitante,
                    ),
                )
            elif gol_local > gol_visitante:
                print("gana local")
                cursor.execute(
                    "INSERT INTO resultado (id_partido, id_equipo_ganador) VALUES (%s, %s)",
                    (
                        p + 1 + (6 * g) + (m * 64),
                        id_local,
                    ),
                )
            # si sale empate no se inserta nada en la tabla resultado y es null en la tabla
            else:
                print("empate:partido grupo ", p + 1 + (6 * g) + (m * 64))

    # cada mundial tiene 16 partidos que no son de grupo
    for otros_part in range(16):
        id_mundial = m + 1
        fecha = fake.date()
        id_estadio = fake.random_int(min=1, max=total_estadios)
        id_arbitro = fake.random_int(min=1, max=50)
        id_local = fake.random_int(min=1, max=(32 + (8 * 4 * m)))
        id_visitante = fake.random_int(min=1, max=(32 + (8 * 4 * m)))

        while id_visitante == id_local:
            id_visitante = fake.random_int(min=1, max=(32 + (8 * 4 * m)))

        # 8 partidos de fase octavos
        if otros_part < 8:
            id_fase = 2
        # 4 partidos de fase cuartos
        elif otros_part >= 8 and otros_part < 12:
            id_fase = 3
        # 2 partidos de fase semifinal
        elif otros_part >= 12 and otros_part < 14:
            id_fase = 4
        # un partido de fase final
        elif otros_part == 14:
            id_fase = 5
        # un partido de fase por el tercer puesto
        else:
            id_fase = 6

        cursor.execute(
            "INSERT INTO partido(id_mundial, id_estadio, id_fase, id_arbitro, id_local, id_visitante, fecha, cantidad_jugadores) VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
            (
                id_mundial,
                id_estadio,
                id_fase,
                id_arbitro,
                id_local,
                id_visitante,
                fecha,
                cantidad_jugadores,
            ),
        )
        gol_local = 0
        gol_visitante = 0
        penal_local = 0
        penal_visitante = 0

        # por cada partido se deben cargar 22 estadísticas
        for est in range(22):
            if est < 11:
                id_jugador = ((id_local * 11) - 11 + est) % 40000 + 1

            else:
                id_jugador = ((id_visitante * 11) - 22 + est) % 40000 + 1
            asistencias = fake.random_int(min=0, max=10)
            tiempo_jugado = fake.date_time()
            posicion = random.choice(posiciones)
            faltas = fake.random_int(min=0, max=10)
            perdida_posesion = fake.random_int(min=0, max=10)
            tarjeta_amarilla = fake.random_int(min=0, max=2)
            tarjeta_roja = fake.random_int(min=0, max=1)
            tiros = fake.random_int(min=0, max=20)
            pases_clave = fake.random_int(min=0, max=10)
            goles = fake.random_int(min=0, max=5)
            atajadas = fake.random_int(min=0, max=10)
            paradas_penales = fake.random_int(min=0, max=5)
            recuperaciones = fake.random_int(min=0, max=10)

            penal_desempate = fake.random_int(min=0, max=2)

            # se suman en las variables para luego determinar el ganador
            if es < 11:
                gol_local += goles
                penal_local += penal_desempate
            else:
                gol_visitante += goles
                penal_visitante += penal_desempate

            cursor.execute(
                "INSERT INTO estadistica (id_partido, id_jugador, asistencias, tiempo_jugado, posicion, goles, faltas, perdida_posesion, tarjeta_amarilla, tarjeta_roja, tiros, pases_clave, atajadas, paradas_penales, penal_desempate, recuperaciones) \
            VALUES (%s, %s,%s, %s,%s, %s,%s, %s,%s, %s,%s, %s,%s, %s,%s, %s)",
                (
                    otros_part + 1 + (m * 64) + 48,
                    id_jugador,
                    asistencias,
                    tiempo_jugado,
                    posicion,
                    goles,
                    faltas,
                    perdida_posesion,
                    tarjeta_amarilla,
                    tarjeta_roja,
                    tiros,
                    pases_clave,
                    atajadas,
                    paradas_penales,
                    penal_desempate,
                    recuperaciones,
                ),
            )
        # cuando se generaron las 22 estadisticas se define el ganador y se carga en la tabla resultado
        if gol_local < gol_visitante:
            print("gana visitante")
            cursor.execute(
                "INSERT INTO resultado (id_partido, id_equipo_ganador) VALUES (%s, %s)",
                (
                    otros_part + 1 + (m * 64) + 48,
                    id_visitante,
                ),
            )
        elif gol_local > gol_visitante:
            print("gana local")
            cursor.execute(
                "INSERT INTO resultado (id_partido, id_equipo_ganador) VALUES (%s, %s)",
                (
                    otros_part + 1 + (m * 64) + 48,
                    id_local,
                ),
            )
        # si es empate se define por penales
        else:
            if penal_local < penal_visitante:
                print("gana visitante")
                cursor.execute(
                    "INSERT INTO resultado (id_partido, id_equipo_ganador) VALUES (%s, %s)",
                    (
                        otros_part + 1 + (m * 64) + 48,
                        id_visitante,
                    ),
                )
            else:
                print("gana local")
                cursor.execute(
                    "INSERT INTO resultado (id_partido, id_equipo_ganador) VALUES (%s, %s)",
                    (
                        otros_part + 1 + (m * 64) + 48,
                        id_local,
                    ),
                )

# se cierra la conexión a la base de datos
conn.commit()
conn.close()
