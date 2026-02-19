% ------ TABLERO ------
% Representación del tablero de Monopoly

tablero(Tablero) :-
    Tablero = [
        salida,
        propiedad(marron1, 60, marron),
        carta,
        propiedad(marron2, 60, marron),
        impuesto(200),
        estacion(norte),
        propiedad(celeste1, 100, celeste),
        chance,
        propiedad(celeste2, 100, celeste),
        propiedad(celeste3, 120, celeste),
        carcel,
        propiedad(rosa1, 140, rosa),
        servicio(electrica),
        propiedad(rosa2, 140, rosa),
        propiedad(rosa3, 160, rosa),
        estacion(sur),
        propiedad(naranja1, 180, naranja),
        carta,
        propiedad(naranja2, 180, naranja),
        propiedad(naranja3, 200, naranja),
        parking,
        propiedad(rojo1, 220, rojo),
        chance,
        propiedad(rojo2, 220, rojo),
        propiedad(rojo3, 240, rojo),
        estacion(este),
        propiedad(amarillo1, 260, amarillo),
        propiedad(amarillo2, 260, amarillo),
        servicio(agua),
        propiedad(amarillo3, 280, amarillo),
        ir_a_carcel,
        propiedad(verde1, 300, verde),
        propiedad(verde2, 300, verde),
        carta,
        propiedad(verde3, 320, verde),
        estacion(oeste),
        chance,
        propiedad(azul1, 350, azul),
        impuesto(100),
        propiedad(azul2, 400, azul)
    ].

% Obtiene la casilla en una posición dada (0-39)
casilla(Indice, Casilla) :-
    tablero(T),
    nth0(Indice, T, Casilla).


% ------ ESTADO ------

% Representación del estado del juego
% estado(Jugadores, Tablero, Turno)
estado_inicial(estado(Jugadores, Tablero, 0)) :-
    tablero(Tablero),
    Jugadores = [
        jugador(alice, 0, 1500, []),
        jugador(bob,   0, 1500, [])
    ].


% ------ MOVIMIENTO ------

% Aleatoriedad simulada con una secuencia predefinida de tiradas de dado
secuencia_dado([3, 5, 2, 6, 1, 4, 2, 5, 3, 1, 4, 6, 2, 3, 5, 1, 4, 2, 6, 3]).

% Obtiene el valor del dado basado en el turno actual
valor_dado(N, Valor) :-
    secuencia_dado(Tiradas),
    length(Tiradas, Len),
    Idx is N mod Len,
    nth0(Idx, Tiradas, Valor).

% Calcula la nueva posición del jugador después de una tirada
nueva_posicion(Pos, Tirada, NuevaPos) :-
    NuevaPos is (Pos + Tirada) mod 40.

% Verifica si el jugador pasa por la salida, lo que le otorga $200
pasa_por_salida(Pos, Tirada) :-
    Pos + Tirada >= 40.

% Mueve al jugador y actualiza su dinero si pasa por la salida
mover_jugador(jugador(N, Pos, Dinero, Props), Tirada, NuevoJugador) :-
    nueva_posicion(Pos, Tirada, NuevaPos),
    (   pasa_por_salida(Pos, Tirada)
    ->  NuevoDinero is Dinero + 200
    ;   NuevoDinero = Dinero
    ),
    NuevoJugador = jugador(N, NuevaPos, NuevoDinero, Props).

% Actualiza la información de un jugador en la lista de jugadores
actualizar_jugador(Nuevo, [jugador(NombreJ,_,_,_)|R], [Nuevo|R]) :-
    Nuevo = jugador(NombreJ,_,_,_), !.
actualizar_jugador(Nuevo, [J|R], [J|RA]) :-
    actualizar_jugador(Nuevo, R, RA).

% ------ CONTROL DE TURNO ------

% Determina el jugador actual basado en el turno
jugador_actual(Jugadores, Turno, Jugador) :-
    length(Jugadores, N),
    Idx is Turno mod N,
    nth0(Idx, Jugadores, Jugador).

% Avanza al siguiente turno
siguiente_turno(Turno, Nuevo) :-
    Nuevo is Turno + 1.

% Jugar turno completo
jugarTurno(estado(Jugadores, Tablero, Turno),
           estado(NuevosJugadores, Tablero, NuevoTurno)) :-
    jugador_actual(Jugadores, Turno, Jugador),
    valor_dado(Turno, Tirada),
    mover_jugador(Jugador, Tirada, JugadorMovido),
    actualizar_jugador(JugadorMovido, Jugadores, NuevosJugadores),
    siguiente_turno(Turno, NuevoTurno).
