% ============================================================
%  PARTE DE: Ángel Jiménez, Sergio Bardavio y Diego Martínez
%  Módulo: Tablero + Dado doble + Estado Global Eficiente + Dueños
%  Mejoras integradas:
%    1. Dado doble y casillas estructuradas (Ángel)
%    2. Variables globales mutables (nb_setval) (Sergio)
%    3. Mutación directa (nb_setarg) para eficiencia O(1) (Sergio)
%    4. Sistema de turnos interactivo (Sergio)
%    5. Estructura de propiedades con dueño/libre y consultas (Diego)
% ============================================================

% ============================================================
% ------ ESTADO GLOBAL EFICIENTE (SERGIO) ------
% ============================================================
iniciar_juego :-
    nb_setval(jugadores, [
        jugador(alice, 0, 1500, []),
        jugador(bob,   0, 1500, [])
    ]),
    nb_setval(turno_actual, 0),
    writeln('================================================'),
    writeln('¡Partida iniciada con eficiencia maxima!'),
    writeln('Memoria lista. Usa "jugar_turno." para avanzar.'),
    writeln('================================================').

% ============================================================
% ------ TABLERO CON DUEÑOS (DIEGO + ÁNGEL) ------
% ============================================================
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

casilla_en(Indice, Casilla) :-
    tablero(T),
    nth0(Indice, T, Casilla).

% ============================================================
% ------ DADO DOBLE SIMULADO (ÁNGEL) ------
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

valor_dados(Turno, Total) :-
    valor_dado1(Turno, V1),
    valor_dado2(Turno, V2),
    Total is V1 + V2.

es_doble(Turno) :-
    valor_dado1(Turno, V),
    valor_dado2(Turno, V).

% ============================================================
% ------ MOVIMIENTO EFICIENTE (SERGIO) ------
% ============================================================
nueva_posicion(Pos, Tirada, NuevaPos) :-
    NuevaPos is (Pos + Tirada) mod 40.

pasa_por_salida(Pos, Tirada) :-
    Pos + Tirada >= 40.

mover_jugador(Jugador, Turno) :-
    Jugador = jugador(_, Pos, Dinero, _),
    valor_dados(Turno, Tirada),
    nueva_posicion(Pos, Tirada, NuevaPos),
    
    ( pasa_por_salida(Pos, Tirada) 
    -> NuevoDinero is Dinero + 200 
    ;  NuevoDinero = Dinero 
    ),
    
    nb_setarg(2, Jugador, NuevaPos),
    nb_setarg(3, Jugador, NuevoDinero).

% ============================================================
% ------ ACCIÓN DE CASILLAS EFICIENTE (SERGIO + DIEGO) ------
% ============================================================

% Ir a la cárcel: mutamos su posición (argumento 2) a la 10.
aplicar_casilla(casilla(ir_a_carcel, _), Jugador) :-
    nb_setarg(2, Jugador, 10).

% Impuesto: mutamos su dinero (argumento 3).
aplicar_casilla(casilla(impuesto, Cantidad), Jugador) :-
    Jugador = jugador(_, _, Dinero, _),
    NuevoDinero is Dinero - Cantidad,
    nb_setarg(3, Jugador, NuevoDinero).

% Propiedades, estaciones y servicios de Diego: 
% Por ahora no mutan nada, solo hacen match (más adelante se implementará compra/alquiler)
aplicar_casilla(propiedad(_, _, _, _), _).
aplicar_casilla(estacion(_, _), _).
aplicar_casilla(servicio(_, _), _).

% Catch-all: Resto de casillas simples (salida, carcel, parking, cartas) no mutan nada
aplicar_casilla(_, _).

% ============================================================
% ------ CONTROL DE TURNO INTERACTIVO (SERGIO) ------
% ============================================================
jugar_turno :-
    nb_getval(turno_actual, Turno),
    nb_getval(jugadores, Jugadores),
    
    Idx is Turno mod 2,
    nth0(Idx, Jugadores, JugadorActual),
    JugadorActual = jugador(Nombre, _, _, _),
    
    mover_jugador(JugadorActual, Turno),
    
    JugadorActual = jugador(_, NuevaPos, _, _),
    casilla_en(NuevaPos, Casilla),
    aplicar_casilla(Casilla, JugadorActual),
    
    NuevoTurno is Turno + 1,
    nb_setval(turno_actual, NuevoTurno),
    
    valor_dados(Turno, Tirada),
    format('~n--- TURNO ~w ---~n', [Turno]),
    format('Juega: ~w. Saca un ~w en los dados.~n', [Nombre, Tirada]),
    format('Cae en la posicion ~w: ~w~n', [NuevaPos, Casilla]),
    format('Estado final del jugador: ~w~n', [JugadorActual]).

jugar_turnos(0) :- !.
jugar_turnos(N) :-
    N > 0, jugar_turno, N1 is N - 1, jugar_turnos(N1).

% ============================================================
% ------ CONSULTAS ADAPTADAS AL ESTADO GLOBAL (DIEGO) ------
% ============================================================

% props_de_jugador(+Nombre, -Props)
% Busca las propiedades en la lista de jugadores global.
props_de_jugador(Nombre, Props) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Nombre, _, _, Props), Jugadores).

% propiedades_de_dueno(+Dueno, -ListaNombres)
% Busca las propiedades directamente leyendo el tablero.
propiedades_de_dueno(Dueno, ListaNombres) :-
    tablero(T),
    findall(Nombre, member(propiedad(Nombre, _, _, Dueno), T), ListaNombres).

% estaciones_de_dueno(+Dueno, -Lista)
estaciones_de_dueno(Dueno, Lista) :-
    tablero(T),
    findall(Nombre, member(estacion(Nombre, Dueno), T), Lista).

% servicios_de_dueno(+Dueno, -Lista)
servicios_de_dueno(Dueno, Lista) :-
    tablero(T),
    findall(Nombre, member(servicio(Nombre, Dueno), T), Lista).