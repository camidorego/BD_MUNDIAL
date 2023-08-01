

-- TRIGGER QUE LIMITA LA CANTIDAD DE JUGADORES POR EQUIPO
CREATE FUNCTION  verificar_cant_jugadores()
RETURNS TRIGGER AS $$
DECLARE
	cantidad_jugadores integer;
BEGIN
	-- se cuenta la cantidad de jugadores ingresados de un mismo equipo 
	SELECT count(*) INTO cantidad_jugadores 
	FROM jugador_x_equipo
	WHERE id_equipo = new.id_equipo;

	-- se verifica que hayan como maximo 23 jugadores
	IF cantidad_jugadores > 23 then
		RAISE EXCEPTION 'Se alcanzo la cantidad maxima de 23 jugadores por equipo';
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER cantidad_jugadores_equipo
AFTER INSERT ON jugador_x_equipo
FOR EACH ROW
EXECUTE FUNCTION verificar_cant_jugadores();

-- TRIGGER QUE VERICA QUE LOS DATOS QUE SE INSERTAN EN ESTADISTICA TENGAN SENTIDO
CREATE FUNCTION tr_insert_estadistica()
RETURNS TRIGGER AS $$
BEGIN
  -- Verificar que los datos de goles, faltas, asistencias sean mayores o iguales a 0
  IF NEW.goles < 0 THEN
    RAISE EXCEPTION 'El número de goles no puede ser menor a 0.';
  END IF;

  IF NEW.faltas < 0 THEN
    RAISE EXCEPTION 'El número de faltas no puede ser menor a 0.';
  END IF;

  IF NEW.asistencias < 0 THEN
    RAISE EXCEPTION 'El número de asistencias no puede ser menor a 0.';
  END IF;

  -- Verificar que el valor de tarjeta_amarilla esté entre 0 y 2
  IF NEW.tarjeta_amarilla < 0 OR NEW.tarjeta_amarilla > 2 THEN
    RAISE EXCEPTION 'El valor de la tarjeta amarilla debe estar entre 0 y 2.';
  END IF;

  -- Verificar que el valor de tarjeta_roja esté entre 0 y 1
  IF NEW.tarjeta_roja < 0 OR NEW.tarjeta_roja > 1 THEN
    RAISE EXCEPTION 'El valor de la tarjeta roja debe estar entre 0 y 1.';
  END IF;

  -- Insertar el nuevo registro en la tabla estadistica
  INSERT INTO public.estadistica (id_partido, id_jugador, asistencias, tiempo_jugado, posicion, faltas, perdida_posesion, tarjeta_amarilla, tarjeta_roja, tiros, pases_clave, goles, atajadas, paradas_penales, penal_desempate, recuperaciones)
  VALUES (NEW.id_partido, NEW.id_jugador, NEW.asistencias, NEW.tiempo_jugado, NEW.posicion, NEW.faltas, NEW.perdida_posesion, NEW.tarjeta_amarilla, NEW.tarjeta_roja, NEW.tiros, NEW.pases_clave, NEW.goles, NEW.atajadas, NEW.paradas_penales, NEW.penal_desempate, NEW.recuperaciones);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_insert_estadistica
BEFORE INSERT ON public.estadistica
FOR EACH ROW
EXECUTE FUNCTION tr_insert_estadistica();

-- TRIGGER QUE VERIFICA QUE LOS DATOS QUE SE ELIMINAN DE ESTADISTICA NO SEAN DE UN MUNDIAL RECIENTE
CREATE OR REPLACE FUNCTION tr_delete_estadistica()
RETURNS TRIGGER AS $$
DECLARE
  jugador_pertenece_equipo BOOLEAN;
BEGIN
  -- Verificar si el jugador pertenece a un equipo de un mundial reciente
  SELECT EXISTS (
    SELECT 1
    FROM public.jugador_x_equipo jxe
    INNER JOIN public.equipo eq ON jxe.id_equipo = eq.id_equipo
    INNER JOIN public.mundial m ON eq.id_mundial = m.id_mundial
    WHERE jxe.id_jugador = OLD.id_jugador
      AND m.anho >= EXTRACT(YEAR FROM CURRENT_DATE) - 1
  ) INTO jugador_pertenece_equipo;

  -- Si el jugador pertenece a un equipo de un mundial reciente, cancelar la eliminación
  IF jugador_pertenece_equipo THEN
    RAISE EXCEPTION 'No se puede eliminar la estadistica. El jugador pertenece a un equipo de un mundial reciente.';
  END IF;

  DELETE FROM public.estadistica WHERE id_estadistica = OLD.id_estadistica;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_delete_estadistica
BEFORE DELETE ON public.estadistica
FOR EACH ROW
EXECUTE FUNCTION tr_delete_estadistica();

-- FUNCION QUE DEVUELVE UNA TABLA DE LOS PUNTAJES DE GRUPO DE UN MUNDIAL ESPECIFICO
CREATE OR REPLACE FUNCTION reporte_tabla_grupos(id_mundial_var INTEGER)
RETURNS TABLE (
    id_mundial INTEGER,
    id_grupo INTEGER,
    nombre_grupo VARCHAR,
    nombre_pais VARCHAR,
    puntaje BIGINT
)
AS $$
BEGIN
    RETURN QUERY
    WITH puntajes AS (
        SELECT
            m.id_mundial,
            g.id_grupo,
            g.nombre_grupo,
            p.nombre,
            SUM(
                CASE
                    WHEN r.id_equipo_ganador = e.id_equipo THEN 3  -- Equipo ganador
                    WHEN r.id_equipo_ganador IS NULL THEN 1       -- Empate
                    ELSE 0                                        -- Equipo perdedor
                END
            ) AS puntaje
        FROM
            grupo g
            JOIN equipo e ON g.id_grupo = e.id_grupo
            JOIN pais p ON e.id_pais = p.id_pais
            JOIN mundial m ON g.id_mundial = m.id_mundial
            LEFT JOIN resultado r ON e.id_equipo = r.id_equipo_ganador AND r.id_partido IN (
                SELECT id_partido
                FROM partido
                WHERE id_fase = 1  -- Fase de grupo
            )
        WHERE
            m.id_mundial = id_mundial_var
        GROUP BY
            m.id_mundial,
            g.id_grupo,
            g.nombre_grupo,
            p.nombre
    )
    SELECT * FROM puntajes;
END;
$$ LANGUAGE plpgsql;


-- FUNCION QUE CALCULA EL SCORE DE UN JUGADOR EN UN PARTIDO ESPECIFICO
CREATE OR REPLACE FUNCTION calcular_puntaje()
RETURNS VOID AS $$
DECLARE
    contador INT := 1;
    puntaje_final INT;
    goles_var INT;
    asistencias_var INT;
    tarjeta_amarilla_var INT;
    tarjeta_roja_var INT;
    perdida_posesion_var INT;
    pases_clave_var INT;
    tiros_var INT;
    tiempo_jugado_var INT;
    posicion_var VARCHAR;
    faltas_var INT;
    atajadas_var INT;
   	cant_estadistica INT;
begin
	SELECT count(*)
    INTO cant_estadistica
   	FROM estadistica;
    WHILE contador <= cant_estadistica LOOP
        -- Obtener los valores de la estadÃ­stica utilizando el ID actual
        SELECT goles, asistencias, tarjeta_amarilla, tarjeta_roja, perdida_posesion, pases_clave, tiros, posicion, faltas, atajadas
    	INTO goles_var, asistencias_var, tarjeta_amarilla_var, tarjeta_roja_var, perdida_posesion_var, pases_clave_var, tiros_var, posicion_var, faltas_var, atajadas_var
        FROM estadistica
        WHERE id_estadistica = contador;

        -- Calcular el puntaje final
        puntaje_final := CASE
            WHEN goles_var >= 3 THEN 30
            WHEN goles_var = 2 THEN 20
            WHEN goles_var = 1 THEN 10
            ELSE 0
        END;
        puntaje_final := puntaje_final + CASE
            WHEN asistencias_var >= 3 THEN 15
            WHEN asistencias_var = 2 THEN 10
            WHEN asistencias_var = 1 THEN 5
            ELSE 0
        END;
        puntaje_final := puntaje_final + CASE
            WHEN tarjeta_amarilla_var = 1 THEN -5
            WHEN tarjeta_amarilla_var = 2 OR tarjeta_roja_var = 1 THEN -20
            ELSE 0
        END;
        puntaje_final := puntaje_final + CASE
            WHEN perdida_posesion_var > 10 AND perdida_posesion_var < 16 THEN -5
            WHEN perdida_posesion_var > 15 THEN -10
            ELSE 0
        END;
        puntaje_final := puntaje_final + CASE   
            WHEN pases_clave_var > 3 AND tiros_var > 5 THEN 10
            WHEN pases_clave_var > 3 OR tiros_var > 5 THEN 5
            ELSE 0
        END;

        IF puntaje_final >= 45 THEN
            puntaje_final := 10;
        ELSIF puntaje_final >= 40 AND puntaje_final < 45 THEN
            puntaje_final := 9;
        ELSIF puntaje_final >= 35 AND puntaje_final < 40 THEN
            puntaje_final := 8;
        ELSIF puntaje_final >= 30 AND puntaje_final < 35 THEN
            puntaje_final := 7;
        ELSIF puntaje_final >= 25 AND puntaje_final < 30 THEN
            puntaje_final := 6;
        ELSIF puntaje_final >= 20 AND puntaje_final < 25 THEN
            puntaje_final := 5;
        ELSIF puntaje_final >= 10 AND puntaje_final < 20 THEN
            puntaje_final := 4;
        ELSE
            puntaje_final := 3;
        END IF;

        -- Insertar el puntaje en la tabla nueva
        INSERT INTO score (id_estadistica, puntaje)
        VALUES (contador, puntaje_final);

        contador := contador + 1;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

-- REPORTE PODIUM
CREATE FUNCTION reporte_podium(id_mundial_f integer)
RETURNS TABLE (posicion text, id_equipo integer, pais varchar) AS $$
DECLARE
	id_equipo_primer integer;
	pais_equipo_primer varchar;
	id_equipo_segundo integer;
	pais_equipo_segundo varchar;
	id_equipo_tercer integer;
	pais_equipo_tercer varchar;
BEGIN
	-- el equipo que sale en primer puesto es el que gano la final
	SELECT resultado.id_equipo_ganador INTO id_equipo_primer
	FROM partido
	INNER JOIN resultado ON partido.id_partido = resultado.id_partido
	WHERE partido.id_fase = 5 AND partido.id_mundial = id_mundial_f;
	 
	-- el equipo que sale en segundo puesto es el que perdio la final
	SELECT CASE 
		WHEN id_equipo_primer = partido.id_local THEN partido.id_visitante
		ELSE partido.id_local
	END INTO id_equipo_segundo
	FROM partido WHERE partido.id_fase = 5 AND partido.id_mundial = id_mundial_f;

	-- el equipo que sale en tercer puesto es el que gana el partido por el tercer puesto
	SELECT resultado.id_equipo_ganador INTO id_equipo_tercer
	FROM partido
	INNER JOIN resultado ON partido.id_partido = resultado.id_partido
	WHERE partido.id_fase = 6 AND partido.id_mundial = id_mundial;

	-- se definen los paises de los equipos ganadores
	SELECT pais.nombre INTO pais_equipo_primer
	FROM pais
	INNER JOIN equipo ON pais.id_pais = equipo.id_pais
	WHERE equipo.id_equipo = id_equipo_primer;

	SELECT pais.nombre INTO pais_equipo_segundo
	FROM pais
	INNER JOIN equipo ON pais.id_pais = equipo.id_pais
	WHERE equipo.id_equipo = id_equipo_segundo;

	SELECT pais.nombre INTO pais_equipo_tercer
	FROM pais
	INNER JOIN equipo ON pais.id_pais = equipo.id_pais
	WHERE equipo.id_equipo = id_equipo_tercer;

	-- se retorna toda la info
	RETURN QUERY
	SELECT 'Primer Puesto' AS posicion, id_equipo_primer AS id_equipo, pais_equipo_primer AS pais
	UNION ALL
	SELECT 'Segundo Puesto' AS posicion, id_equipo_segundo AS id_equipo, pais_equipo_segundo AS pais
	UNION ALL
	SELECT 'Tercer Puesto' AS posicion, id_equipo_tercer AS id_equipo, pais_equipo_tercer AS pais;	
END;
$$ LANGUAGE plpgsql;


-- REPORTE DE LOS TOP 20 JUGADORES QUE MAS MUNDIALES JUGARON
CREATE FUNCTION reporte_top_jugadores()
RETURNS TABLE (posicion bigint, id_jugador integer, nombre varchar, cantidad_mundiales bigint, posiciones_jugadas bigint) AS $$
BEGIN
    RETURN QUERY
    SELECT
        -- con row_number() le asignamos un número a cada fila que se va a imprimir
        row_number() OVER (ORDER BY subconsulta.cant_mundiales_var DESC) as posicion,
        subconsulta.id_jugador,
        p.nombre_persona,
        subconsulta.cant_mundiales_var,
        subconsulta.cant_posiciones_var
    FROM (
        -- por cada jugador se cuentan la cantidad de mundiales en los que jugó y las cantidad de posiciones
        SELECT
            j.id_jugador,
            COUNT(DISTINCT pa.id_mundial) AS cant_mundiales_var,
            COUNT(DISTINCT e.posicion) AS cant_posiciones_var
        FROM
            jugador j
            JOIN estadistica e ON j.id_jugador = e.id_jugador
            JOIN partido pa ON e.id_partido = pa.id_partido
        GROUP BY
            j.id_jugador
    ) AS subconsulta
    JOIN jugador ju ON subconsulta.id_jugador = ju.id_jugador
    JOIN persona p ON ju.id_persona = p.id_persona
    -- se ordena por cantidad de mundiales de mayor a menor
    ORDER BY
        subconsulta.cant_mundiales_var DESC
    -- se limita a 20 las filas que se van a imprimir
    LIMIT 20;
END;
$$ LANGUAGE plpgsql;

--REPORTE MVP, MEJOR ARQUERO, MEJOR DEFENSA. (ultimos 5 mundiales)
CREATE OR REPLACE FUNCTION obtener_mvp(id_mundial_var INTEGER)
RETURNS TABLE(id_mundial INTEGER, nombre_jugador VARCHAR(100), suma_puntaje BIGINT, pais_equipo VARCHAR(100), posicion VARCHAR(100)) AS $$
DECLARE
    id_equipo_ganador INTEGER;
    id_equipo_perdedor INTEGER;
    contador INTEGER := 0;
    id_mundial_loop INTEGER := id_mundial_var;
BEGIN
    WHILE id_mundial_var >= (id_mundial_loop - 4) AND contador < 6 LOOP
        -- Obtiene el equipo ganador de la final
        SELECT resultado.id_equipo_ganador INTO id_equipo_ganador
        FROM partido
        INNER JOIN resultado ON partido.id_partido = resultado.id_partido
        WHERE partido.id_fase = 5 AND partido.id_mundial = id_mundial_var;

        -- Obtiene el equipo perdedor de la final
        SELECT CASE 
            WHEN id_equipo_ganador = partido.id_local THEN partido.id_visitante
            ELSE partido.id_local
        END INTO id_equipo_perdedor
        FROM partido WHERE partido.id_fase = 5 AND partido.id_mundial = id_mundial_var;

        -- Obtiene al mejor jugador sin importar la posición
        RETURN QUERY
        SELECT p.id_mundial, pe.nombre_persona, SUM(s.puntaje) AS suma_puntaje, pa.nombre, e.posicion
        FROM estadistica e
        INNER JOIN score s ON s.id_estadistica = e.id_estadistica
        INNER JOIN jugador_x_equipo jxe ON e.id_jugador = jxe.id_jugador
        INNER JOIN partido p ON p.id_partido = e.id_partido
        INNER JOIN jugador ju ON ju.id_jugador = e.id_jugador
        INNER JOIN equipo eq ON eq.id_equipo = jxe.id_equipo
        INNER JOIN pais pa ON pa.id_pais = eq.id_pais
        INNER JOIN persona pe ON pe.id_persona = ju.id_persona
        WHERE (jxe.id_equipo = id_equipo_ganador OR jxe.id_equipo = id_equipo_perdedor)
            AND p.id_mundial = id_mundial_var
        GROUP BY p.id_mundial, pe.nombre_persona, pa.nombre, e.posicion
        ORDER BY suma_puntaje DESC
        LIMIT 1;

        -- Obtiene al arquero con el puntaje más alto
        RETURN QUERY
        SELECT p.id_mundial, pe.nombre_persona, SUM(s.puntaje) AS suma_puntaje, pa.nombre, e.posicion
        FROM estadistica e
        INNER JOIN score s ON s.id_estadistica = e.id_estadistica
        INNER JOIN jugador_x_equipo jxe ON e.id_jugador = jxe.id_jugador
        INNER JOIN partido p ON p.id_partido = e.id_partido
        INNER JOIN jugador ju ON ju.id_jugador = e.id_jugador
        INNER JOIN equipo eq ON eq.id_equipo = jxe.id_equipo
        INNER JOIN pais pa ON pa.id_pais = eq.id_pais
        INNER JOIN persona pe ON pe.id_persona = ju.id_persona
        WHERE (jxe.id_equipo = id_equipo_ganador OR jxe.id_equipo = id_equipo_perdedor)
            AND p.id_mundial = id_mundial_var
            AND e.posicion = 'Arquero'
        GROUP BY p.id_mundial, pe.nombre_persona, pa.nombre, e.posicion
        ORDER BY suma_puntaje DESC
        LIMIT 1;

        -- Obtiene al defensa con el puntaje más alto
        RETURN QUERY
        SELECT p.id_mundial, pe.nombre_persona, SUM(s.puntaje) AS suma_puntaje, pa.nombre, e.posicion
        FROM estadistica e
        INNER JOIN score s ON s.id_estadistica = e.id_estadistica
        INNER JOIN jugador_x_equipo jxe ON e.id_jugador = jxe.id_jugador
        INNER JOIN partido p ON p.id_partido = e.id_partido
        INNER JOIN jugador ju ON ju.id_jugador = e.id_jugador
        INNER JOIN equipo eq ON eq.id_equipo = jxe.id_equipo
        INNER JOIN pais pa ON pa.id_pais = eq.id_pais
        INNER JOIN persona pe ON pe.id_persona = ju.id_persona
        WHERE (jxe.id_equipo = id_equipo_ganador OR jxe.id_equipo = id_equipo_perdedor)
            AND p.id_mundial = id_mundial_var
            AND e.posicion = 'Defensa'
        GROUP BY p.id_mundial, pe.nombre_persona, pa.nombre, e.posicion
        ORDER BY suma_puntaje DESC
        LIMIT 1;

        contador := contador + 1;
        id_mundial_var := id_mundial_var - 1;
    END LOOP;

    RETURN;
END;
$$
LANGUAGE plpgsql;

-- REPORTE DE UN PARTIDO
CREATE OR REPLACE FUNCTION reporte_partido(id_partido_N INTEGER)
RETURNS TABLE (
    id_mundial INTEGER,
    id_fase INTEGER,
    nombre_fase VARCHAR,
    fecha DATE,
    id_es INTEGER,
    nombre_estadio VARCHAR,
    id_equipo_local INTEGER,
    nombre_pais_local VARCHAR,
    id_equipo_visitante INTEGER,
    nombre_pais_visitante VARCHAR,
    id_arbitro INTEGER,
    nombre_arbitro VARCHAR,
    cantidad_jugadores INTEGER,
    total_faltas_local BIGINT,
    total_faltas_visitante BIGINT,
    total_goles_local BIGINT,
    total_goles_visitante BIGINT,
    total_tarjetas_amarillas BIGINT,
    total_tarjetas_rojas BIGINT,
    total_penales_local BIGINT,
    total_penales_visitante BIGINT
) AS
$$
BEGIN
    RETURN QUERY
    SELECT
        p.id_mundial,
        f.id_fase,
        f.nombre_fase,
        p.fecha,
        e.id_estadio,
        e.nombre_estadio,
        eq_local.id_equipo,
        pais_local.nombre AS nombre_pais_local,
        eq_visitante.id_equipo,
        pais_visitante.nombre AS nombre_pais_visitante,
        a.id_arbitro,
        per.nombre_persona AS nombre_arbitro,
        p.cantidad_jugadores,
        (
            SELECT SUM(est.faltas)
            FROM estadistica est
            INNER JOIN jugador_x_equipo je_local ON est.id_jugador = je_local.id_jugador
            WHERE est.id_partido = p.id_partido
            AND je_local.id_equipo = p.id_local
        ) AS total_faltas_local,
        (
            SELECT SUM(est.faltas)
            FROM estadistica est
            INNER JOIN jugador_x_equipo je_visitante ON est.id_jugador = je_visitante.id_jugador
            WHERE est.id_partido = p.id_partido
            AND je_visitante.id_equipo = p.id_visitante
        ) AS total_faltas_visitante,
        (
            SELECT SUM(est.goles)
            FROM estadistica est
            INNER JOIN jugador_x_equipo je_local ON est.id_jugador = je_local.id_jugador
            WHERE est.id_partido = p.id_partido
            AND je_local.id_equipo = p.id_local
        ) AS total_goles_local,
        (
            SELECT SUM(est.goles)
            FROM estadistica est
            INNER JOIN jugador_x_equipo je_visitante ON est.id_jugador = je_visitante.id_jugador
            WHERE est.id_partido = p.id_partido
            AND je_visitante.id_equipo = p.id_visitante
        ) AS total_goles_visitante,
        (
            SELECT SUM(est.tarjeta_amarilla)
            FROM estadistica est
            WHERE est.id_partido = p.id_partido
        ) AS total_tarjetas_amarillas,
        (
            SELECT SUM(est.tarjeta_roja)
            FROM estadistica est
            WHERE est.id_partido = p.id_partido
        ) AS total_tarjetas_rojas,
        (
            SELECT SUM(est.penal_desempate)
            FROM estadistica est
            INNER JOIN jugador_x_equipo je_local ON est.id_jugador = je_local.id_jugador
            WHERE est.id_partido = p.id_partido
            AND je_local.id_equipo = p.id_local
        ) AS total_penales_local,
        (
            SELECT SUM(est.penal_desempate)
            FROM estadistica est
            INNER JOIN jugador_x_equipo je_visitante ON est.id_jugador = je_visitante.id_jugador
            WHERE est.id_partido = p.id_partido
            AND je_visitante.id_equipo = p.id_visitante
        ) AS total_penales_visitante
    FROM
        partido p
        INNER JOIN fase f ON p.id_fase = f.id_fase
        INNER JOIN estadio e ON p.id_estadio = e.id_estadio
        INNER JOIN equipo eq_local ON p.id_local = eq_local.id_equipo
        INNER JOIN equipo eq_visitante ON p.id_visitante = eq_visitante.id_equipo
        INNER JOIN pais pais_local ON eq_local.id_pais = pais_local.id_pais
        INNER JOIN pais pais_visitante ON eq_visitante.id_pais = pais_visitante.id_pais
        INNER JOIN arbitro a ON p.id_arbitro = a.id_arbitro
        INNER JOIN persona per ON a.id_persona = per.id_persona
    WHERE
        p.id_partido = id_partido_N;
END
$$
LANGUAGE plpgsql;

-- REPORTE QUE IMPRIME EL GOLEADOR DE UN MUNDIAL ESPECIFICO
CREATE FUNCTION reporte_goleador(id_mundial_N integer)
RETURNS TABLE (
    id_mundial integer,
    nombre_jugador varchar,
    partidos_jugados bigint,
    goles_metidos bigint
) AS
$$
BEGIN
    RETURN QUERY
    SELECT 
        id_mundial_N AS id_mundial,
        p.nombre_persona AS nombre_jugador,
        subconsulta.cant_partidos_jugados AS partidos_jugados,
        subconsulta.cant_goles_metidos AS goles_metidos
    FROM (
        -- por cada jugador se cuentan la cantidad de mundiales en los que jugó y la cantidad de goles metidos
        SELECT
            j.id_jugador,
            COUNT(DISTINCT pa.id_partido) AS cant_partidos_jugados,
            SUM(e.goles) AS cant_goles_metidos
        FROM
            jugador j
            JOIN estadistica e ON j.id_jugador = e.id_jugador
            JOIN partido pa ON e.id_partido = pa.id_partido
        WHERE
            pa.id_mundial = id_mundial_N
        GROUP BY
            j.id_jugador
    ) AS subconsulta
    JOIN jugador ju ON subconsulta.id_jugador = ju.id_jugador
    JOIN persona p ON ju.id_persona = p.id_persona
    -- se ordena por cantidad de goles metidos de mayor a menor
    ORDER BY
        subconsulta.cant_goles_metidos DESC
    -- se limita a 5 las filas que se van a imprimir
    LIMIT 5;
    
END
$$
LANGUAGE plpgsql;

-- REPORTE DE UN JUGADOR EN UN MUNDIAL ESPECIFICO
CREATE OR REPLACE FUNCTION estadisticas_jugador_mundial(id_mundial_var INTEGER, id_jugador_var INTEGER)
RETURNS TABLE (
	nombre_persona VARCHAR,
	id_jugador INTEGER,
	id_persona INTEGER,
    id_partido INTEGER,
    goles INTEGER,
    asistencias INTEGER,
    tiempo_jugado TIMESTAMP,
    posicion VARCHAR(100),
    faltas INTEGER,
    perdida_posesion INTEGER,
    tarjeta_amarilla INTEGER,
    tarjeta_roja INTEGER,
    tiros INTEGER,
    pases_clave INTEGER,
    atajadas INTEGER
)
AS $$
BEGIN
    RETURN QUERY
    select
    	per.nombre_persona,
        jug.id_jugador,
        per.id_persona,
        est.id_partido,
        est.goles,
        est.asistencias,
        est.tiempo_jugado,
        est.posicion,
        est.faltas,
        est.perdida_posesion,
        est.tarjeta_amarilla,
        est.tarjeta_roja,
        est.tiros,
        est.pases_clave,
        est.atajadas
    FROM
        estadistica est
        INNER JOIN partido p ON est.id_partido = p.id_partido
        INNER JOIN jugador jug ON est.id_jugador = jug.id_jugador
        INNER JOIN persona per ON jug.id_persona = per.id_persona
        
    WHERE
        p.id_mundial = id_mundial_var
        AND est.id_jugador = id_jugador_var;

    RETURN;
END;
$$ LANGUAGE plpgsql;

-- REPORTE DE UN JUGADOR EN TODOS LOS MUNDIALES EN QUE JUGO
CREATE OR REPLACE FUNCTION estadisticas_jugador_total(id_jugador_var INTEGER)
RETURNS TABLE (
	nombre_persona VARCHAR,
	id_jugador INTEGER,
	id_persona INTEGER,
    id_partido INTEGER,
    anho INTEGER,
    goles INTEGER,
    asistencias INTEGER,
    tiempo_jugado TIMESTAMP,
    posicion VARCHAR(100),
    faltas INTEGER,
    perdida_posesion INTEGER,
    tarjeta_amarilla INTEGER,
    tarjeta_roja INTEGER,
    tiros INTEGER,
    pases_clave INTEGER,
    atajadas INTEGER
)
AS $$
BEGIN
    RETURN QUERY
    select
    	per.nombre_persona,
        jug.id_jugador,
        per.id_persona,
        est.id_partido,
        mun.anho,
        est.goles,
        est.asistencias,
        est.tiempo_jugado,
        est.posicion,
        est.faltas,
        est.perdida_posesion,
        est.tarjeta_amarilla,
        est.tarjeta_roja,
        est.tiros,
        est.pases_clave,
        est.atajadas
    FROM
        estadistica est
        INNER JOIN partido p ON est.id_partido = p.id_partido
        INNER JOIN jugador jug ON est.id_jugador = jug.id_jugador
        INNER JOIN persona per ON jug.id_persona = per.id_persona
        INNER JOIN mundial mun ON p.id_mundial = mun.id_mundial
    WHERE
        est.id_jugador = id_jugador_var;

    RETURN;
END;
$$ LANGUAGE plpgsql;
