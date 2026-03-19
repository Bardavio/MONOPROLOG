% PROYECTO MONOPOLY EN PROLOG
% Motor eficiente O(1) con Estado Global Non-Backtrackable

:- [reglas].

% --- Estado global ---
% Inicializa 6 jugadores con $1500 y turno 0
iniciar_juego :-
    nb_setval(jugadores, [
        jugador(alice,  0, 1500, []),
        jugador(bob,    0, 1500, []),
        jugador(alice1, 0, 1500, []),
        jugador(bob1,   0, 1500, []),
        jugador(alice2, 0, 1500, []),
        jugador(bob2,   0, 1500, [])
    ]),
    nb_setval(turno_actual, 0),
    writeln('================================================'),
    writeln('¡Partida iniciada con eficiencia maxima (6 jugadores)!'),
    writeln('Memoria lista. Usa "jugar_turno." para avanzar.'),
    writeln('Para pruebas, usa los comandos "test_..."'),
    writeln('================================================').

% --- Tablero (40 casillas) ---
% Lista con las 40 casillas del tablero
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

longitud_tablero(Len) :-
    tablero(T),
    length(T, Len).
    
% Devuelve la casilla en el indice dado (0-based)
casilla_en(Indice, Casilla) :-
    tablero(T),
    nth0(Indice, T, Casilla).

% --- Dado doble simulado ---
% Turno 0 (3 y 3) saca dobles
secuencia_dado1([3, 5, 2, 6, 1, 4, 2, 5, 3, 1, 4, 6, 2, 3, 5, 1, 4, 2, 6, 3]).
secuencia_dado2([3, 4, 6, 1, 3, 4, 1, 3, 6, 2, 5, 4, 3, 6, 2, 4, 1, 5, 3, 2]).

% Valor del dado 1 en el turno dado (ciclico)
valor_dado1(Turno, Valor) :-
    secuencia_dado1(Tiradas),
    length(Tiradas, Len),
    Idx is Turno mod Len,
    nth0(Idx, Tiradas, Valor).

% Valor del dado 2 en el turno dado (ciclico)
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

% Cierto si ambos dados son iguales
es_doble(Turno) :-
    valor_dado1(Turno, V),
    valor_dado2(Turno, V).

% --- Movimiento (nb_setarg O(1)) ---
% Calcula nueva posicion circular (mod 40)
nueva_posicion(Pos, Tirada, NuevaPos) :-
    longitud_tablero(Len),
    NuevaPos is (Pos + Tirada) mod Len.

% Cierto si el movimiento cruza la casilla de salida
pasa_por_salida(Pos, Tirada) :-
    longitud_tablero(Len),
    Pos + Tirada >= Len.

% Mueve con los dados automaticos del turno
mover_jugador(Jugador, Turno) :-
    valor_dados(Turno, Tirada),
    mover_jugador_con_tirada(Jugador, Tirada).

% Mueve con una tirada manual (para tests)
mover_jugador_con_tirada(Jugador, Tirada) :-
    Jugador = jugador(_, Pos, Dinero, _),
    nueva_posicion(Pos, Tirada, NuevaPos),
    ( pasa_por_salida(Pos, Tirada)
    -> NuevoDinero is Dinero + 200
    ;  NuevoDinero = Dinero
    ),
    nb_setarg(2, Jugador, NuevaPos),
    nb_setarg(3, Jugador, NuevoDinero).


% --- Enrutador de casillas ---
% Abstraccion: calle, estacion o servicio -> comprable generico
item_comprable(propiedad(Nombre, Precio, Color, _), Nombre, Nombre, Precio, Alquiler) :- 
    alquiler_color(Color, Alquiler).

item_comprable(estacion(Nombre, _), Nombre, estacion(Nombre), Precio, Alquiler) :- 
    precio_estacion(Precio), alquiler(Precio, Alquiler).

item_comprable(servicio(Nombre, _), Nombre, servicio(Nombre), Precio, Alquiler) :- 
    precio_servicio(Precio), alquiler(Precio, Alquiler).

% Busca dueño en las mochilas de todos los jugadores
estado_dueno(ItemGuardado, Dueno) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Dueno, _, _, Props), Jugadores),
    member(ItemGuardado, Props),
    !.

estado_dueno(_, libre).

% Casillas especiales
aplicar_casilla(casilla(ir_a_carcel, _), Jugador) :-
    nb_setarg(2, Jugador, 10), !.

aplicar_casilla(casilla(impuesto, Cantidad), Jugador) :-
    Jugador = jugador(_, _, Dinero, _),
    NuevoDinero is Dinero - Cantidad,
    nb_setarg(3, Jugador, NuevoDinero),
    comprobar_bancarrota(Jugador), !.

% Enrutador principal: compra o alquiler
aplicar_casilla(Casilla, Jugador) :-
    item_comprable(Casilla, NombreVisual, ItemGuardado, Precio, Alquiler),
    estado_dueno(ItemGuardado, Dueno),
    Jugador = jugador(NombreJ, _, _, _),
    
    ( Dueno == libre ->
        regla_0_compra(Jugador, NombreVisual, ItemGuardado, Precio)
    ; Dueno \== NombreJ ->
        regla_1_alquiler(Jugador, NombreVisual, Dueno, Alquiler),
        comprobar_bancarrota(Jugador)
    ; true
    ),
    !.

% Catch-all: casillas sin efecto
aplicar_casilla(_, _).

% --- Control de turno ---
% Ejecuta un turno completo: mover + aplicar casilla + log
ejecutar_turno(Idx, Turno) :-
    nb_getval(jugadores, Jugadores),
    nth0(Idx, Jugadores, JugadorActual),
    JugadorActual = jugador(Nombre, _, _, _),
    mover_jugador(JugadorActual, Turno),
    JugadorActual = jugador(_, NuevaPos, _, _),
    casilla_en(NuevaPos, Casilla),
    aplicar_casilla(Casilla, JugadorActual),
    valor_dados(Turno, Tirada),
    format('~n--- TURNO ~w ---~n', [Turno]),
    format('Juega: ~w. Saca un ~w en los dados.~n', [Nombre, Tirada]),
    format('Cae en la posicion ~w: ~w~n', [NuevaPos, Casilla]),
    format('Estado final del jugador: ~w~n', [JugadorActual]).

% Juega un turno (con turno extra si saca doble)
jugar_turno :-
    nb_getval(turno_actual, Turno),
    nb_getval(jugadores, Jugadores),
    length(Jugadores, N),
    Idx is Turno mod N,
    ejecutar_turno(Idx, Turno),
    NuevoTurno is Turno + 1,
    nb_setval(turno_actual, NuevoTurno),
    ( es_doble(Turno)
    -> nb_getval(turno_actual, Turno2),
       nth0(Idx, Jugadores, J),
       J = jugador(NombreJ, _, _, _),
       format('[Doble] ~w saca doble, juega de nuevo!~n', [NombreJ]),
       ejecutar_turno(Idx, Turno2),
       NuevoTurno2 is Turno2 + 1,
       nb_setval(turno_actual, NuevoTurno2)
    ;  true
    ).

% Juega N turnos consecutivos
jugar_turnos(0) :- !.
jugar_turnos(N) :-
    N > 0, jugar_turno, N1 is N - 1, jugar_turnos(N1).

% --- Consultas globales ---
% Lista de propiedades de un jugador
props_de_jugador(Nombre, Props) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Nombre, _, _, Props), Jugadores).

% Solo propiedades (sin estaciones ni servicios)
propiedades_de_dueno(Dueno, Lista) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Dueno, _, _, Props), Jugadores),
    include([X]>>(X \= estacion(_), X \= servicio(_)), Props, Lista).

% Lista de estaciones de un jugador
estaciones_de_dueno(Dueno, Lista) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Dueno, _, _, Props), Jugadores),
    findall(N, member(estacion(N), Props), Lista).

% Lista de servicios de un jugador
servicios_de_dueno(Dueno, Lista) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Dueno, _, _, Props), Jugadores),
    findall(N, member(servicio(N), Props), Lista).

% Valores base
alquiler_color(marron,    2).
alquiler_color(celeste,   6).
alquiler_color(rosa,     10).
alquiler_color(naranja,  14).
alquiler_color(rojo,     18).
alquiler_color(amarillo, 22).
alquiler_color(verde,    26).
alquiler_color(azul,     50).

precio_estacion(200).   % Precio fijo de estaciones
precio_servicio(150).   % Precio fijo de servicios
alquiler(Precio, Alquiler) :- Alquiler is Precio // 10. % 10% del precio

% Cierto si nadie posee esa propiedad
propiedad_libre(Nombre) :-
    nb_getval(jugadores, Jugadores),
    \+ (member(jugador(_, _, _, Props), Jugadores), member(Nombre, Props)).

% Busca el jugador dueño de una propiedad
dueno_de(Nombre, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Props),
    member(Nombre, Props).

% Busca el jugador dueño de una estacion
dueno_estacion(Nombre, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Props),
    member(estacion(Nombre), Props).

% Busca el jugador dueño de un servicio
dueno_servicio(Nombre, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Props),
    member(servicio(Nombre), Props).

% Cierto si todos los elementos de la primera lista estan en la segunda
subset_lista([], _).
subset_lista([X|Xs], Lista) :-
    member(X, Lista),
    subset_lista(Xs, Lista).