

% ------ TABLERO ------

tablero(Tablero) :-
    Tablero = [
        casilla(salida,      'Cobras $200 al pasar'),
        propiedad(marron1,   60,  marron, libre),
        casilla(carta,       'Carta de Comunidad'),
        propiedad(marron2,   60,  marron, libre),
        casilla(impuesto,    200),
        estacion(norte, libre),
        propiedad(celeste1,  100, celeste, libre),
        casilla(chance,      'Carta de Suerte'),
        propiedad(celeste2,  100, celeste, libre),
        propiedad(celeste3,  120, celeste, libre),
        casilla(carcel,      'Solo de visita'),
        propiedad(rosa1,     140, rosa, libre),
        servicio(electrica, libre),
        propiedad(rosa2,     140, rosa, libre),
        propiedad(rosa3,     160, rosa, libre),
        estacion(sur, libre),
        propiedad(naranja1,  180, naranja, libre),
        casilla(carta,       'Carta de Comunidad'),
        propiedad(naranja2,  180, naranja, libre),
        propiedad(naranja3,  200, naranja, libre),
        casilla(parking,     'Parking gratuito'),
        propiedad(rojo1,     220, rojo, libre),
        casilla(chance,      'Carta de Suerte'),
        propiedad(rojo2,     220, rojo, libre),
        propiedad(rojo3,     240, rojo, libre),
        estacion(este, libre),
        propiedad(amarillo1, 260, amarillo, libre),
        propiedad(amarillo2, 260, amarillo, libre),
        servicio(agua, libre),
        propiedad(amarillo3, 280, amarillo, libre),
        casilla(ir_a_carcel, 'Ve directamente a la carcel'),
        propiedad(verde1,    300, verde, libre),
        propiedad(verde2,    300, verde, libre),
        casilla(carta,       'Carta de Comunidad'),
        propiedad(verde3,    320, verde, libre),
        estacion(oeste, libre),
        casilla(chance,      'Carta de Suerte'),
        propiedad(azul1,     350, azul, libre),
        casilla(impuesto,    100),
        propiedad(azul2,     400, azul, libre)
    ].

% casilla_en(+Indice, -Casilla)
% Obtiene la casilla en una posición dada (0-39).
% Se llama casilla_en para no colisionar con el functor casilla/2
% que ahora se usa dentro del tablero.
casilla_en(Indice, Casilla) :-
    tablero(T),
    nth0(Indice, T, Casilla).

% ------ ESTADO ------
% estado(Jugadores, Tablero, Turno)
estado_inicial(estado(Jugadores, Tablero, 0)) :-
    tablero(Tablero),
    Jugadores = [
        jugador(alice, 0, 1500, []),
        jugador(bob,   0, 1500, [])
    ].

% ============================================================
% ------ DADO DOBLE SIMULADO ------
% MEJORA 1: En Monopoly real se lanzan 2 dados.
% Como random/1 no funciona en Prolog estándar, se usan
% dos listas predefinidas independientes.
% El índice se determina por el turno actual (mod longitud),
% de forma que la secuencia es circular y determinista.
% ============================================================

secuencia_dado1([3, 5, 2, 6, 1, 4, 2, 5, 3, 1, 4, 6, 2, 3, 5, 1, 4, 2, 6, 3]).
secuencia_dado2([2, 4, 6, 1, 3, 5, 1, 3, 6, 2, 5, 4, 3, 6, 2, 4, 1, 5, 3, 2]).

valor_dado1(Turno, Valor) :-
    secuencia_dado1(Tiradas),
    length(Tiradas, Len),
    Idx is Turno mod Len,
    nth0(Idx, Tiradas, Valor).

valor_dado2(Turno, Valor) :-
    secuencia_dado2(Tiradas),
    length(Tiradas, Len),
    Idx is Turno mod Len,
    nth0(Idx, Tiradas, Valor).

% Suma de ambos dados
valor_dados(Turno, Total) :-
    valor_dado1(Turno, V1),
    valor_dado2(Turno, V2),
    Total is V1 + V2.

% Dobles: ambos dados igual (útil para turno extra)
es_doble(Turno) :-
    valor_dado1(Turno, V),
    valor_dado2(Turno, V).

% ============================================================
% ------ ACCIÓN DE CASILLAS SIMPLES ------
% MEJORA 2: gracias a la estructura casilla(Tipo, Dato)
% el pattern matching es uniforme y extensible.
%
% aplicar_casilla(+Casilla, +Jugador, -JugadorResultante)
% ============================================================

% Salida: no hace nada al caer (el bonus $200 se da al PASAR)
aplicar_casilla(casilla(salida, _), Jugador, Jugador).

% Cárcel: solo de visita
aplicar_casilla(casilla(carcel, _), Jugador, Jugador).

% Parking: casilla de descanso
aplicar_casilla(casilla(parking, _), Jugador, Jugador).

% Carta de comunidad: pendiente (gestión de cartas)
aplicar_casilla(casilla(carta, _), Jugador, Jugador).

% Chance: pendiente (gestión de cartas)
aplicar_casilla(casilla(chance, _), Jugador, Jugador).

% Ir a la cárcel: mueve al jugador a posición 10
aplicar_casilla(casilla(ir_a_carcel, _),
                jugador(N, _, Dinero, Props),
                jugador(N, 10, Dinero, Props)).

% Impuesto: resta la cantidad indicada
aplicar_casilla(casilla(impuesto, Cantidad),
                jugador(N, Pos, Dinero, Props),
                jugador(N, Pos, NuevoDinero, Props)) :-
    NuevoDinero is Dinero - Cantidad.

% Las casillas con propietario las gestionan las Reglas 0 y 1 del equipo
% aplicar_casilla(propiedad(_, _, _), Jugador, Jugador). CASILLA ANTIGUA MEJORA DIEGO
% Propiedad libre: por ahora no hace nada (más adelante compra/alquiler)
aplicar_casilla(propiedad(_, _, _, libre), Jugador, Jugador).
% Propiedad con dueño: por ahora no hace nada (más adelante alquiler)
aplicar_casilla(propiedad(_, _, _, Dueno), Jugador, Jugador) :-
    Dueno \= libre. %para asegurarte que si tiene dueño ya no esta libre

%aplicar_casilla(estacion(_),        Jugador, Jugador). CASILLA ANTIGUA MEJORA DIEGO
%aplicar_casilla(servicio(_),        Jugador, Jugador). CASILLA ANTIGUA MEJORA DIEGO

% Estación libre / con dueño (por ahora no hace nada)
aplicar_casilla(estacion(_, libre), Jugador, Jugador).
aplicar_casilla(estacion(_, Dueno), Jugador, Jugador) :- Dueno \= libre.

% Servicio libre / con dueño (por ahora no hace nada)
aplicar_casilla(servicio(_, libre), Jugador, Jugador).
aplicar_casilla(servicio(_, Dueno), Jugador, Jugador) :- Dueno \= libre.

% ------ MOVIMIENTO ------
nueva_posicion(Pos, Tirada, NuevaPos) :-
    NuevaPos is (Pos + Tirada) mod 40.

pasa_por_salida(Pos, Tirada) :-
    Pos + Tirada >= 40.

mover_jugador(jugador(N, Pos, Dinero, Props), Turno, NuevoJugador) :-
    valor_dados(Turno, Tirada),
    nueva_posicion(Pos, Tirada, NuevaPos),
    (   pasa_por_salida(Pos, Tirada)
    ->  NuevoDinero is Dinero + 200
    ;   NuevoDinero = Dinero
    ),
    NuevoJugador = jugador(N, NuevaPos, NuevoDinero, Props).

actualizar_jugador(Nuevo, [jugador(NombreJ,_,_,_)|R], [Nuevo|R]) :-
    Nuevo = jugador(NombreJ,_,_,_), !.
actualizar_jugador(Nuevo, [J|R], [J|RA]) :-
    actualizar_jugador(Nuevo, R, RA).

% ------ CONTROL DE TURNO ------
jugador_actual(Jugadores, Turno, Jugador) :-
    length(Jugadores, N),
    Idx is Turno mod N,
    nth0(Idx, Jugadores, Jugador).

siguiente_turno(Turno, Nuevo) :-
    Nuevo is Turno + 1.

% Jugar turno completo:
% 1. Jugador actual
% 2. Mover (2 dados + paso por salida)
% 3. Aplicar acción de la casilla
% 4. Actualizar jugadores
% 5. Avanzar turno
jugarTurno(estado(Jugadores, Tablero, Turno),
           estado(NuevosJugadores, Tablero, NuevoTurno)) :-
    jugador_actual(Jugadores, Turno, Jugador),
    mover_jugador(Jugador, Turno, JugadorMovido),
    JugadorMovido = jugador(_, NuevaPos, _, _),
    nth0(NuevaPos, Tablero, Casilla),
    aplicar_casilla(Casilla, JugadorMovido, JugadorFinal),
    actualizar_jugador(JugadorFinal, Jugadores, NuevosJugadores),
    siguiente_turno(Turno, NuevoTurno).

% ============================================================
% ------ CONSULTAS DE PROPIEDADES, ESTACIONES Y SERVICIOS ------
% ============================================================

% props_de_jugador(+Nombre, +Estado, -Props)
props_de_jugador(Nombre, estado(Jugadores, _, _), Props) :-
    member(jugador(Nombre, _, _, Props), Jugadores).

% propiedades_de_dueno(+Dueno, +Tablero, -ListaNombres)
propiedades_de_dueno(Dueno, Tablero, ListaNombres) :-
    findall(Nombre,
            member(propiedad(Nombre, _, _, Dueno), Tablero),
            ListaNombres).

estaciones_de_dueno(Dueno, Tablero, Lista) :-
    findall(Nombre, member(estacion(Nombre, Dueno), Tablero), Lista).

servicios_de_dueno(Dueno, Tablero, Lista) :-
    findall(Nombre, member(servicio(Nombre, Dueno), Tablero), Lista).