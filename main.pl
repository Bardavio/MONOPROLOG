% --- Estado global ---
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

% --- Tablero con dueños ---
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

% --- Dado doble simulado ---
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

% cierto si ambos dados tienen el mismo valor
es_doble(Turno) :-
    valor_dado1(Turno, V),
    valor_dado2(Turno, V).

% --- Movimiento ---
nueva_posicion(Pos, Tirada, NuevaPos) :-
    NuevaPos is (Pos + Tirada) mod 40.

pasa_por_salida(Pos, Tirada) :-
    Pos + Tirada >= 40.

mover_jugador(Jugador, Turno) :-
    Jugador = jugador(_, Pos, Dinero, _),
    valor_dados(Turno, Tirada),
    nueva_posicion(Pos, Tirada, NuevaPos),
    % bonus $200 al cruzar salida
    ( pasa_por_salida(Pos, Tirada)
    -> NuevoDinero is Dinero + 200
    ;  NuevoDinero = Dinero
    ),
    nb_setarg(2, Jugador, NuevaPos),
    nb_setarg(3, Jugador, NuevoDinero).

% --- Acción de casillas ---

% teletransporta a casilla 10 (cárcel)
aplicar_casilla(casilla(ir_a_carcel, _), Jugador) :-
    nb_setarg(2, Jugador, 10).

aplicar_casilla(casilla(impuesto, Cantidad), Jugador) :-
    Jugador = jugador(_, _, Dinero, _),
    NuevoDinero is Dinero - Cantidad,
    nb_setarg(3, Jugador, NuevoDinero).

% propiedad de otro jugador → cobrar alquiler
aplicar_casilla(propiedad(Nombre, _, Color, _), Jugador) :-
    dueno_de(Nombre, Dueno),
    Jugador = jugador(NombreJ, _, _, _),
    Dueno   = jugador(NombreD, _, _, _),
    NombreJ \= NombreD,
    !,
    alquiler_color(Color, Alquiler),
    Jugador = jugador(_, _, DineroJ, _),
    Dueno   = jugador(_, _, DineroD, _),
    NuevoDineroJ is DineroJ - Alquiler,
    NuevoDineroD is DineroD + Alquiler,
    nb_setarg(3, Jugador, NuevoDineroJ),
    nb_setarg(3, Dueno,   NuevoDineroD),
    format('[Alquiler] ~w paga $~w a ~w por ~w.~n', [NombreJ, Alquiler, NombreD, Nombre]).

% propiedad propia → no hacer nada
aplicar_casilla(propiedad(Nombre, _, _, _), Jugador) :-
    dueno_de(Nombre, Dueno),
    Jugador = jugador(NombreJ, _, _, _),
    Dueno   = jugador(NombreJ, _, _, _),
    !.

% propiedad libre + fondos → comprar
aplicar_casilla(propiedad(Nombre, Precio, _, _), Jugador) :-
    propiedad_libre(Nombre),
    Jugador = jugador(NombreJ, _, Dinero, Props),
    Dinero >= Precio,
    !,
    NuevoDinero is Dinero - Precio,
    nb_setarg(3, Jugador, NuevoDinero),
    nb_setarg(4, Jugador, [Nombre | Props]),
    format('[Compra] ~w compra ~w por $~w. Dinero restante: $~w~n',
           [NombreJ, Nombre, Precio, NuevoDinero]).

% propiedad libre pero sin fondos
aplicar_casilla(propiedad(Nombre, Precio, _, _), Jugador) :-
    propiedad_libre(Nombre),
    Jugador = jugador(NombreJ, _, Dinero, _),
    Dinero < Precio,
    !,
    format('[Sin fondos] ~w no puede comprar ~w ($~w, cuesta $~w).~n',
           [NombreJ, Nombre, Dinero, Precio]).

% fallthrough (propiedad ya manejada con cortes)
aplicar_casilla(propiedad(_, _, _, _), _).

% estación de otro → pagar alquiler
aplicar_casilla(estacion(Nombre, _), Jugador) :-
    dueno_estacion(Nombre, Dueno),
    Jugador = jugador(NombreJ, _, _, _),
    Dueno   = jugador(NombreD, _, _, _),
    NombreJ \= NombreD,
    !,
    precio_estacion(Precio),
    alquiler(Precio, Alquiler),
    Jugador = jugador(_, _, DineroJ, _),
    Dueno   = jugador(_, _, DineroD, _),
    NuevoDineroJ is DineroJ - Alquiler,
    NuevoDineroD is DineroD + Alquiler,
    nb_setarg(3, Jugador, NuevoDineroJ),
    nb_setarg(3, Dueno,   NuevoDineroD),
    format('[Alquiler] ~w paga $~w a ~w por estacion ~w.~n', [NombreJ, Alquiler, NombreD, Nombre]).

% estación propia → nada
aplicar_casilla(estacion(Nombre, _), Jugador) :-
    dueno_estacion(Nombre, Dueno),
    Jugador = jugador(NombreJ, _, _, _),
    Dueno   = jugador(NombreJ, _, _, _),
    !.

% estación libre + fondos → comprar
aplicar_casilla(estacion(Nombre, _), Jugador) :-
    \+ dueno_estacion(Nombre, _),
    precio_estacion(Precio),
    Jugador = jugador(NombreJ, _, Dinero, Props),
    Dinero >= Precio,
    !,
    NuevoDinero is Dinero - Precio,
    nb_setarg(3, Jugador, NuevoDinero),
    nb_setarg(4, Jugador, [estacion(Nombre) | Props]),
    format('[Compra] ~w compra estacion ~w por $~w.~n', [NombreJ, Nombre, Precio]).

% estación libre sin fondos
aplicar_casilla(estacion(Nombre, _), Jugador) :-
    \+ dueno_estacion(Nombre, _),
    precio_estacion(Precio),
    Jugador = jugador(NombreJ, _, Dinero, _),
    Dinero < Precio,
    !,
    format('[Sin fondos] ~w no puede comprar estacion ~w ($~w).~n', [NombreJ, Nombre, Dinero]).

aplicar_casilla(estacion(_, _), _).

% servicio de otro → pagar alquiler
aplicar_casilla(servicio(Nombre, _), Jugador) :-
    dueno_servicio(Nombre, Dueno),
    Jugador = jugador(NombreJ, _, _, _),
    Dueno   = jugador(NombreD, _, _, _),
    NombreJ \= NombreD,
    !,
    precio_servicio(Precio),
    alquiler(Precio, Alquiler),
    Jugador = jugador(_, _, DineroJ, _),
    Dueno   = jugador(_, _, DineroD, _),
    NuevoDineroJ is DineroJ - Alquiler,
    NuevoDineroD is DineroD + Alquiler,
    nb_setarg(3, Jugador, NuevoDineroJ),
    nb_setarg(3, Dueno,   NuevoDineroD),
    format('[Alquiler] ~w paga $~w a ~w por servicio ~w.~n', [NombreJ, Alquiler, NombreD, Nombre]).

% servicio propio → nada
aplicar_casilla(servicio(Nombre, _), Jugador) :-
    dueno_servicio(Nombre, Dueno),
    Jugador = jugador(NombreJ, _, _, _),
    Dueno   = jugador(NombreJ, _, _, _),
    !.

% servicio libre + fondos → comprar
aplicar_casilla(servicio(Nombre, _), Jugador) :-
    \+ dueno_servicio(Nombre, _),
    precio_servicio(Precio),
    Jugador = jugador(NombreJ, _, Dinero, Props),
    Dinero >= Precio,
    !,
    NuevoDinero is Dinero - Precio,
    nb_setarg(3, Jugador, NuevoDinero),
    nb_setarg(4, Jugador, [servicio(Nombre) | Props]),
    format('[Compra] ~w compra servicio ~w por $~w.~n', [NombreJ, Nombre, Precio]).

% servicio libre sin fondos
aplicar_casilla(servicio(Nombre, _), Jugador) :-
    \+ dueno_servicio(Nombre, _),
    precio_servicio(Precio),
    Jugador = jugador(NombreJ, _, Dinero, _),
    Dinero < Precio,
    !,
    format('[Sin fondos] ~w no puede comprar servicio ~w ($~w).~n', [NombreJ, Nombre, Dinero]).

aplicar_casilla(servicio(_, _), _).

% Catch-all: resto de casillas (salida, carcel, parking, cartas) no mutan nada
aplicar_casilla(_, _).

% --- Control de turno ---

% mueve, aplica casilla y muestra log del turno
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

jugar_turno :-
    nb_getval(turno_actual, Turno),
    nb_getval(jugadores, Jugadores),
    Idx is Turno mod 2,
    ejecutar_turno(Idx, Turno),
    NuevoTurno is Turno + 1,
    nb_setval(turno_actual, NuevoTurno),
    % encadenamiento: dado doble → turno extra del mismo jugador
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

jugar_turnos(0) :- !.
jugar_turnos(N) :-
    N > 0, jugar_turno, N1 is N - 1, jugar_turnos(N1).

% --- Consultas globales ---

% props_de_jugador(+Nombre, -Props)
props_de_jugador(Nombre, Props) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Nombre, _, _, Props), Jugadores).

% propiedades_de_dueno(+Dueno, -Lista)
% TODO: Deberiamos definir la clausula propiedad/4 de forma que solo incluya propiedades, y no estaciones ni servicios, para evitar este filtro extra
propiedades_de_dueno(Dueno, Lista) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Dueno, _, _, Props), Jugadores),
    % filtrar solo propiedades (excluye estaciones y servicios)
    include([X]>>(X \= estacion(_), X \= servicio(_)), Props, Lista).

% estaciones_de_dueno(+Dueno, -Lista)
estaciones_de_dueno(Dueno, Lista) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Dueno, _, _, Props), Jugadores),
    findall(N, member(estacion(N), Props), Lista).

% servicios_de_dueno(+Dueno, -Lista)
servicios_de_dueno(Dueno, Lista) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Dueno, _, _, Props), Jugadores),
    findall(N, member(servicio(N), Props), Lista).

% --- Reglas de propiedad ---

% alquiler_color(+Color, -Alquiler): alquiler fijo por grupo de color (valores Monopoly original)
alquiler_color(marron,    2).
alquiler_color(celeste,   6).
alquiler_color(rosa,     10).
alquiler_color(naranja,  14).
alquiler_color(rojo,     18).
alquiler_color(amarillo, 22).
alquiler_color(verde,    26).
alquiler_color(azul,     50).

% propiedad_libre(+Nombre): cierto si ningún jugador la tiene en su lista
propiedad_libre(Nombre) :-
    nb_getval(jugadores, Jugadores),
    \+ (member(jugador(_, _, _, Props), Jugadores), member(Nombre, Props)).

% dueno_de(+Nombre, -JugadorDueno)
dueno_de(Nombre, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Props),
    member(Nombre, Props).

% dueno_estacion(+Nombre, -JugadorDueno)
dueno_estacion(Nombre, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Props),
    member(estacion(Nombre), Props).

% dueno_servicio(+Nombre, -JugadorDueno)
dueno_servicio(Nombre, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Props),
    member(servicio(Nombre), Props).


precio_estacion(200).
precio_servicio(150).
