% --- Estado global ---
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

es_doble(Turno) :-
    valor_dado1(Turno, V),
    valor_dado2(Turno, V).

% --- Movimiento Separado (Para permitir Testeo) ---
nueva_posicion(Pos, Tirada, NuevaPos) :-
    NuevaPos is (Pos + Tirada) mod 40.

pasa_por_salida(Pos, Tirada) :-
    Pos + Tirada >= 40.

% Mueve con los dados automáticos
mover_jugador(Jugador, Turno) :-
    valor_dados(Turno, Tirada),
    mover_jugador_con_tirada(Jugador, Tirada).

% Mueve con la tirada que nosotros queramos (Esencial para los Tests)
mover_jugador_con_tirada(Jugador, Tirada) :-
    Jugador = jugador(_, Pos, Dinero, _),
    nueva_posicion(Pos, Tirada, NuevaPos),
    ( pasa_por_salida(Pos, Tirada)
    -> NuevoDinero is Dinero + 200
    ;  NuevoDinero = Dinero
    ),
    nb_setarg(2, Jugador, NuevaPos),
    nb_setarg(3, Jugador, NuevoDinero).


% --- Acción de casillas ---
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

aplicar_casilla(_, _).


% --- Control de turno ---
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
    % SOLUCIÓN: Calculamos el índice basándonos en cuántos jugadores hay
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

jugar_turnos(0) :- !.
jugar_turnos(N) :-
    N > 0, jugar_turno, N1 is N - 1, jugar_turnos(N1).

% --- Consultas globales ---
props_de_jugador(Nombre, Props) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Nombre, _, _, Props), Jugadores).

propiedades_de_dueno(Dueno, Lista) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Dueno, _, _, Props), Jugadores),
    include([X]>>(X \= estacion(_), X \= servicio(_)), Props, Lista).

estaciones_de_dueno(Dueno, Lista) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Dueno, _, _, Props), Jugadores),
    findall(N, member(estacion(N), Props), Lista).

servicios_de_dueno(Dueno, Lista) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Dueno, _, _, Props), Jugadores),
    findall(N, member(servicio(N), Props), Lista).

% --- Reglas de propiedad ---
alquiler_color(marron,    2).
alquiler_color(celeste,   6).
alquiler_color(rosa,     10).
alquiler_color(naranja,  14).
alquiler_color(rojo,     18).
alquiler_color(amarillo, 22).
alquiler_color(verde,    26).
alquiler_color(azul,     50).

propiedad_libre(Nombre) :-
    nb_getval(jugadores, Jugadores),
    \+ (member(jugador(_, _, _, Props), Jugadores), member(Nombre, Props)).

dueno_de(Nombre, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Props),
    member(Nombre, Props).

dueno_estacion(Nombre, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Props),
    member(estacion(Nombre), Props).

dueno_servicio(Nombre, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Props),
    member(servicio(Nombre), Props).

precio_estacion(200).
precio_servicio(150).

alquiler(Precio, Alquiler) :-
    Alquiler is Precio // 10.


% ============================================================
% --- MODO TEST / HERRAMIENTAS DE PRUEBAS ---
% Utiliza estas funciones para probar partes específicas del juego
% ============================================================

% 1. Forzar una tirada exacta para un jugador (Ej: test_tirada(alice, 4).)
test_tirada(Nombre, Tirada) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorActual, Jugadores),
    JugadorActual = jugador(Nombre, _, _, _),
    mover_jugador_con_tirada(JugadorActual, Tirada),
    JugadorActual = jugador(_, NuevaPos, _, _),
    casilla_en(NuevaPos, Casilla),
    format('~n[TEST] ~w ha sido forzado a sacar un ~w.~n', [Nombre, Tirada]),
    aplicar_casilla(Casilla, JugadorActual),
    format('[TEST] Estado actual de ~w: ~w~n', [Nombre, JugadorActual]).

% 2. Teletransportar a un jugador a una casilla (Ej: test_caer_en(bob, 30). -> Ir a cárcel)
test_caer_en(Nombre, PosicionCasilla) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorActual, Jugadores),
    JugadorActual = jugador(Nombre, _, _, _),
    nb_setarg(2, JugadorActual, PosicionCasilla),
    casilla_en(PosicionCasilla, Casilla),
    format('~n[TEST] Teletransportando a ~w a la casilla ~w (~w)...~n', [Nombre, PosicionCasilla, Casilla]),
    aplicar_casilla(Casilla, JugadorActual),
    format('[TEST] Estado actual de ~w: ~w~n', [Nombre, JugadorActual]).

% 3. Cambiar el dinero de un jugador (Ej: test_dinero(alice, 10). -> Arruinar a Alice)
test_dinero(Nombre, NuevoDinero) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorActual, Jugadores),
    JugadorActual = jugador(Nombre, _, _, _),
    nb_setarg(3, JugadorActual, NuevoDinero),
    format('~n[TEST] El dinero de ~w ha sido ajustado a $~w.~n', [Nombre, NuevoDinero]).

% 4. Dar una propiedad gratis a un jugador (Ej: test_dar_propiedad(bob, azul2).)
test_dar_propiedad(Nombre, NuevaPropiedad) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorActual, Jugadores),
    JugadorActual = jugador(Nombre, _, _, Props),
    \+ member(NuevaPropiedad, Props), % Se asegura de que no la tenga ya
    nb_setarg(4, JugadorActual, [NuevaPropiedad | Props]),
    format('~n[TEST] ~w ha recibido la propiedad ~w mágicamente.~n', [Nombre, NuevaPropiedad]).

% 5. Forzar un turno doble completo (Demuestra la regla del turno extra)
% Uso: test_turno_doble(alice, 3, 5). -> Saca doble 3, y en el turno extra saca un 5.
test_turno_doble(Nombre, ValorDadoDoble, TiradaExtra) :-
    Tirada1 is ValorDadoDoble * 2,
    format('~n================================================'),
    format('~n[TEST] ~w inicia su turno y saca DOBLE ~w (~w y ~w)!~n', 
           [Nombre, ValorDadoDoble, ValorDadoDoble, ValorDadoDoble]),
    
    % 1. Ejecutamos la primera tirada (el doble)
    test_tirada(Nombre, Tirada1),
    
    % 2. Simulamos la detección del doble y el turno extra
    format('~n[TEST] ¡Doble detectado! Aplicando regla: Turno extra para ~w.~n', [Nombre]),
    test_tirada(Nombre, TiradaExtra),
    
    % 3. Avanzamos el reloj de la partida para que el juego siga con normalidad
    nb_getval(turno_actual, Turno),
    NuevoTurno is Turno + 1,
    nb_setval(turno_actual, NuevoTurno),
    format('~n[TEST] Turno doble de ~w terminado. Avanzamos al turno ~w.~n', [Nombre, NuevoTurno]),
    format('================================================~n').