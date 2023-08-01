
CREATE SEQUENCE public.fase_id_fase_seq_1;

CREATE TABLE public.fase (
                id_fase INTEGER NOT NULL DEFAULT nextval('public.fase_id_fase_seq_1'),
                nombre_fase VARCHAR NOT NULL,
                CONSTRAINT id_fase PRIMARY KEY (id_fase)
);


ALTER SEQUENCE public.fase_id_fase_seq_1 OWNED BY public.fase.id_fase;

CREATE SEQUENCE public.persona_id_persona_seq;

CREATE TABLE public.persona (
                id_persona INTEGER NOT NULL DEFAULT nextval('public.persona_id_persona_seq'),
                ci_persona INTEGER NOT NULL,
                nombre_persona VARCHAR NOT NULL,
                fecha_nacimiento DATE NOT NULL,
                nacionalidad_persona VARCHAR(100) NOT NULL,
                CONSTRAINT persona_pk PRIMARY KEY (id_persona)
);


ALTER SEQUENCE public.persona_id_persona_seq OWNED BY public.persona.id_persona;

CREATE SEQUENCE public.entrenador_id_entrenador_seq_1;

CREATE TABLE public.entrenador (
                id_entrenador INTEGER NOT NULL DEFAULT nextval('public.entrenador_id_entrenador_seq_1'),
                id_persona INTEGER NOT NULL,
                periodo_de_entrenador VARCHAR NOT NULL,
                CONSTRAINT id_entrenador PRIMARY KEY (id_entrenador)
);


ALTER SEQUENCE public.entrenador_id_entrenador_seq_1 OWNED BY public.entrenador.id_entrenador;

CREATE SEQUENCE public.arbitro_id_arbitro_seq_1;

CREATE TABLE public.arbitro (
                id_arbitro INTEGER NOT NULL DEFAULT nextval('public.arbitro_id_arbitro_seq_1'),
                id_persona INTEGER NOT NULL,
                CONSTRAINT id_arbitro PRIMARY KEY (id_arbitro)
);


ALTER SEQUENCE public.arbitro_id_arbitro_seq_1 OWNED BY public.arbitro.id_arbitro;

CREATE SEQUENCE public.pais_id_pais_seq_1_1;

CREATE TABLE public.pais (
                id_pais INTEGER NOT NULL DEFAULT nextval('public.pais_id_pais_seq_1_1'),
                nombre VARCHAR(100) NOT NULL,
                cantidad_estadios INTEGER,
                CONSTRAINT id_pais PRIMARY KEY (id_pais)
);


ALTER SEQUENCE public.pais_id_pais_seq_1_1 OWNED BY public.pais.id_pais;

CREATE SEQUENCE public.estadio_id_estadio_seq;

CREATE TABLE public.estadio (
                id_estadio INTEGER NOT NULL DEFAULT nextval('public.estadio_id_estadio_seq'),
                id_pais INTEGER NOT NULL,
                nombre_estadio VARCHAR(100) NOT NULL,
                ciudad VARCHAR(100) NOT NULL,
                capacidad INTEGER NOT NULL,
                CONSTRAINT id_estadio PRIMARY KEY (id_estadio)
);


ALTER SEQUENCE public.estadio_id_estadio_seq OWNED BY public.estadio.id_estadio;

CREATE SEQUENCE public.mundial_id_mundial_seq;

CREATE TABLE public.mundial (
                id_mundial INTEGER NOT NULL DEFAULT nextval('public.mundial_id_mundial_seq'),
                id_pais INTEGER NOT NULL,
                anho INTEGER NOT NULL,
                CONSTRAINT id_mundial PRIMARY KEY (id_mundial)
);


ALTER SEQUENCE public.mundial_id_mundial_seq OWNED BY public.mundial.id_mundial;

CREATE SEQUENCE public.grupo_id_grupo_seq_1;

CREATE TABLE public.grupo (
                id_grupo INTEGER NOT NULL DEFAULT nextval('public.grupo_id_grupo_seq_1'),
                id_mundial INTEGER NOT NULL,
                nombre_grupo VARCHAR(100) NOT NULL,
                CONSTRAINT id_grupo PRIMARY KEY (id_grupo)
);


ALTER SEQUENCE public.grupo_id_grupo_seq_1 OWNED BY public.grupo.id_grupo;

CREATE SEQUENCE public.equipo_id_equipo_seq_1;

CREATE TABLE public.equipo (
                id_equipo INTEGER NOT NULL DEFAULT nextval('public.equipo_id_equipo_seq_1'),
                id_pais INTEGER NOT NULL,
                id_grupo INTEGER NOT NULL,
                CONSTRAINT id_equipo PRIMARY KEY (id_equipo)
);


ALTER SEQUENCE public.equipo_id_equipo_seq_1 OWNED BY public.equipo.id_equipo;

CREATE TABLE public.entrenador_x_equipo (
                id_entrenador INTEGER NOT NULL,
                id_equipo INTEGER NOT NULL,
                CONSTRAINT id_entrenador_x_equipo PRIMARY KEY (id_entrenador, id_equipo)
);


CREATE SEQUENCE public.partido_id_partido_seq;

CREATE TABLE public.partido (
                id_partido INTEGER NOT NULL DEFAULT nextval('public.partido_id_partido_seq'),
                id_mundial INTEGER NOT NULL,
                id_estadio INTEGER NOT NULL,
                id_fase INTEGER NOT NULL,
                id_arbitro INTEGER NOT NULL,
                id_local INTEGER NOT NULL,
                id_visitante INTEGER NOT NULL,
                fecha DATE NOT NULL,
                cantidad_jugadores INTEGER NOT NULL,
                CONSTRAINT id_partido PRIMARY KEY (id_partido)
);


ALTER SEQUENCE public.partido_id_partido_seq OWNED BY public.partido.id_partido;

CREATE SEQUENCE public.resultado_id_resultado_seq_1;

CREATE TABLE public.resultado (
                id_resultado INTEGER NOT NULL DEFAULT nextval('public.resultado_id_resultado_seq_1'),
                id_partido INTEGER NOT NULL,
                id_equipo_ganador INTEGER NOT NULL,
                CONSTRAINT id_resultado PRIMARY KEY (id_resultado, id_partido)
);


ALTER SEQUENCE public.resultado_id_resultado_seq_1 OWNED BY public.resultado.id_resultado;

CREATE SEQUENCE public.jugador_id_jugador_seq;

CREATE TABLE public.jugador (
                id_jugador INTEGER NOT NULL DEFAULT nextval('public.jugador_id_jugador_seq'),
                numero INTEGER NOT NULL,
                id_persona INTEGER NOT NULL,
                popularidad INTEGER NOT NULL,
                CONSTRAINT id_jugador_pk PRIMARY KEY (id_jugador)
);


ALTER SEQUENCE public.jugador_id_jugador_seq OWNED BY public.jugador.id_jugador;

CREATE SEQUENCE public.estadistica_id_estadistica_seq;

CREATE TABLE public.estadistica (
                id_estadistica INTEGER NOT NULL DEFAULT nextval('public.estadistica_id_estadistica_seq'),
                id_partido INTEGER NOT NULL,
                id_jugador INTEGER NOT NULL,
                asistencias INTEGER NOT NULL,
                tiempo_jugado TIMESTAMP NOT NULL,
                posicion VARCHAR(100),
                faltas INTEGER NOT NULL,
                perdida_posesion INTEGER NOT NULL,
                tarjeta_amarilla INTEGER NOT NULL,
                tarjeta_roja INTEGER NOT NULL,
                tiros INTEGER NOT NULL,
                pases_clave INTEGER NOT NULL,
                goles INTEGER NOT NULL,
                atajadas INTEGER,
                paradas_penales INTEGER,
                penal_desempate INTEGER,
                recuperaciones INTEGER NOT NULL,
                CONSTRAINT id_estadistica PRIMARY KEY (id_estadistica)
);


ALTER SEQUENCE public.estadistica_id_estadistica_seq OWNED BY public.estadistica.id_estadistica;

CREATE SEQUENCE public.score_id_score_seq;

CREATE TABLE public.score (
                id_score INTEGER NOT NULL DEFAULT nextval('public.score_id_score_seq'),
                id_estadistica INTEGER NOT NULL,
                puntaje INTEGER NOT NULL,
                CONSTRAINT id_score PRIMARY KEY (id_score, id_estadistica)
);


ALTER SEQUENCE public.score_id_score_seq OWNED BY public.score.id_score;

CREATE TABLE public.jugador_x_equipo (
                id_equipo INTEGER NOT NULL,
                id_jugador INTEGER NOT NULL,
                CONSTRAINT id_jugador_x_equipo PRIMARY KEY (id_equipo, id_jugador)
);


ALTER TABLE public.partido ADD CONSTRAINT fase_partido_fk
FOREIGN KEY (id_fase)
REFERENCES public.fase (id_fase)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.arbitro ADD CONSTRAINT persona_arbitro_fk
FOREIGN KEY (id_persona)
REFERENCES public.persona (id_persona)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.entrenador ADD CONSTRAINT persona_entrenador_fk
FOREIGN KEY (id_persona)
REFERENCES public.persona (id_persona)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.jugador ADD CONSTRAINT persona_jugador_fk
FOREIGN KEY (id_persona)
REFERENCES public.persona (id_persona)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.entrenador_x_equipo ADD CONSTRAINT entrenador_entrenador_x_equipo_fk
FOREIGN KEY (id_entrenador)
REFERENCES public.entrenador (id_entrenador)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.partido ADD CONSTRAINT arbitro_partido_fk
FOREIGN KEY (id_arbitro)
REFERENCES public.arbitro (id_arbitro)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.estadio ADD CONSTRAINT pais_estadio_fk
FOREIGN KEY (id_pais)
REFERENCES public.pais (id_pais)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.mundial ADD CONSTRAINT pais_mundial_fk
FOREIGN KEY (id_pais)
REFERENCES public.pais (id_pais)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.equipo ADD CONSTRAINT pais_equipo_fk
FOREIGN KEY (id_pais)
REFERENCES public.pais (id_pais)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.partido ADD CONSTRAINT estadio_partidos_fk
FOREIGN KEY (id_estadio)
REFERENCES public.estadio (id_estadio)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.partido ADD CONSTRAINT mundial_partidos_fk
FOREIGN KEY (id_mundial)
REFERENCES public.mundial (id_mundial)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.grupo ADD CONSTRAINT mundial_grupo_fk
FOREIGN KEY (id_mundial)
REFERENCES public.mundial (id_mundial)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.equipo ADD CONSTRAINT grupo_equipo_fk
FOREIGN KEY (id_grupo)
REFERENCES public.grupo (id_grupo)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.partido ADD CONSTRAINT equipo_partidos_fk
FOREIGN KEY (id_local)
REFERENCES public.equipo (id_equipo)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.partido ADD CONSTRAINT equipo_partidos_fk1
FOREIGN KEY (id_visitante)
REFERENCES public.equipo (id_equipo)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.jugador_x_equipo ADD CONSTRAINT equipo_jugador_x_equipo_fk
FOREIGN KEY (id_equipo)
REFERENCES public.equipo (id_equipo)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.entrenador_x_equipo ADD CONSTRAINT equipo_entrenador_x_equipo_fk
FOREIGN KEY (id_equipo)
REFERENCES public.equipo (id_equipo)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.resultado ADD CONSTRAINT equipo_resultado_fk
FOREIGN KEY (id_equipo_ganador)
REFERENCES public.equipo (id_equipo)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.estadistica ADD CONSTRAINT partido_estadistica_fk
FOREIGN KEY (id_partido)
REFERENCES public.partido (id_partido)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.resultado ADD CONSTRAINT resultado_partido_fk
FOREIGN KEY (id_partido)
REFERENCES public.partido (id_partido)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.jugador_x_equipo ADD CONSTRAINT jugador_jugador_x_equipo_fk
FOREIGN KEY (id_jugador)
REFERENCES public.jugador (id_jugador)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.estadistica ADD CONSTRAINT jugador_estadistica_fk
FOREIGN KEY (id_jugador)
REFERENCES public.jugador (id_jugador)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

ALTER TABLE public.score ADD CONSTRAINT estadistica_score_fk
FOREIGN KEY (id_estadistica)
REFERENCES public.estadistica (id_estadistica)
ON DELETE NO ACTION
ON UPDATE NO ACTION
NOT DEFERRABLE;

/*para reiniciar las ids*/
ALTER SEQUENCE arbitro_id_arbitro_seq_1 RESTART WITH 1;
ALTER SEQUENCE equipo_id_equipo_seq_1 RESTART WITH 1;
ALTER SEQUENCE estadio_id_estadio_seq RESTART WITH 1;
ALTER SEQUENCE fase_id_fase_seq_1 RESTART WITH 1;
ALTER SEQUENCE grupo_id_grupo_seq_1 RESTART WITH 1;
ALTER SEQUENCE jugador_id_jugador_seq RESTART WITH 1;
ALTER SEQUENCE mundial_id_mundial_seq RESTART WITH 1;
ALTER SEQUENCE pais_id_pais_seq_1_1 RESTART WITH 1;
ALTER SEQUENCE partido_id_partido_seq RESTART WITH 1;
ALTER SEQUENCE persona_id_persona_seq RESTART WITH 1;
ALTER SEQUENCE estadistica_id_estadistica_seq RESTART WITH 1;
ALTER SEQUENCE resultado_id_resultado_seq_1 RESTART WITH 1;
ALTER SEQUENCE score_id_score_seq RESTART WITH 1;
ALTER SEQUENCE entrenador_id_entrenador_seq_1 RESTART WITH 1;

-- INDICES
CREATE INDEX idx_estadistica_id_partido ON estadistica (id_partido);
CREATE INDEX idx_estadistica_penal_desempate ON estadistica (penal_desempate);
CREATE INDEX idx_estadistica_id_jugador ON estadistica (id_jugador);
CREATE INDEX idx_resultado_id_partido ON resultado (id_partido);
CREATE INDEX idx_jugadorxequipo_id_equipo ON jugador_x_equipo(id_equipo);
CREATE INDEX idx_partido_id_mundial ON partido(id_mundial);
CREATE INDEX idx_partido_id_fase ON public.partido (id_fase);
CREATE INDEX idx_jugador_id_persona ON jugador (id_persona);
CREATE INDEX idx_persona_nombre_persona ON persona (nombre_persona);
CREATE INDEX idx_equipo_id_grupo ON equipo (id_grupo);
CREATE INDEX idx_grupo_id_mundial ON grupo (id_mundial);