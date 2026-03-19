% TESTS Y ESCENARIOS (tests.pl)
:- [main].

% --- Herramientas de pruebas ---

% test_tirada(Nombre, Tirada) — fuerza una tirada exacta
% Comando: swipl -l tests.pl -g "iniciar_juego, test_tirada(alice, 4)" -t halt
test_tirada(Nombre, Tirada) :-
    % 1. Obtener jugador
    nb_getval(jugadores, Jugadores),
    member(JugadorActual, Jugadores),
    JugadorActual = jugador(Nombre, _, _, _),
    
    % 2. Forzar movimiento
    mover_jugador_con_tirada(JugadorActual, Tirada),
    JugadorActual = jugador(_, NuevaPos, _, _),
    casilla_en(NuevaPos, Casilla),
    format('~n[TEST] ~w ha sido forzado a sacar un ~w.~n', [Nombre, Tirada]),
    
    % 3. Aplicar efectos
    aplicar_casilla(Casilla, JugadorActual),
    format('[TEST] Estado actual de ~w: ~w~n', [Nombre, JugadorActual]).

% test_caer_en(Nombre, Pos) — teletransporta a una casilla
% Comando: swipl -l tests.pl -g "iniciar_juego, test_caer_en(bob, 30)" -t halt
test_caer_en(Nombre, PosicionCasilla) :-
    % 1. Obtener jugador
    nb_getval(jugadores, Jugadores),
    member(JugadorActual, Jugadores),
    JugadorActual = jugador(Nombre, _, _, _),
    
    % 2. Teletransportar
    nb_setarg(2, JugadorActual, PosicionCasilla),
    casilla_en(PosicionCasilla, Casilla),
    format('~n[TEST] Teletransportando a ~w a la casilla ~w (~w)...~n', [Nombre, PosicionCasilla, Casilla]),
    
    % 3. Aplicar efectos
    aplicar_casilla(Casilla, JugadorActual),
    format('[TEST] Estado actual de ~w: ~w~n', [Nombre, JugadorActual]).

% test_dinero(Nombre, Cantidad) — cambia el dinero
% Comando: swipl -l tests.pl -g "iniciar_juego, test_dinero(alice, 10)" -t halt
test_dinero(Nombre, NuevoDinero) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorActual, Jugadores),
    JugadorActual = jugador(Nombre, _, _, _),
    nb_setarg(3, JugadorActual, NuevoDinero),
    format('~n[TEST] El dinero de ~w ha sido ajustado a $~w.~n', [Nombre, NuevoDinero]).

% test_dar_propiedad(Nombre, Prop) — da una propiedad
% Comando: swipl -l tests.pl -g "iniciar_juego, test_dar_propiedad(bob, azul2)" -t halt
test_dar_propiedad(Nombre, NuevaPropiedad) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorActual, Jugadores),
    JugadorActual = jugador(Nombre, _, _, Props),
    \+ member(NuevaPropiedad, Props),
    nb_setarg(4, JugadorActual, [NuevaPropiedad | Props]),
    format('~n[TEST] ~w ha recibido la propiedad ~w magicamente.~n', [Nombre, NuevaPropiedad]).

% test_turno_doble(Nombre, ValorDoble, Extra) — fuerza turno doble
% Comando: swipl -l tests.pl -g "iniciar_juego, test_turno_doble(alice, 3, 5)" -t halt
test_turno_doble(Nombre, ValorDadoDoble, TiradaExtra) :-
    Tirada1 is ValorDadoDoble * 2,
    format('~n================================================'),
    format('~n[TEST] ~w inicia su turno y saca DOBLE ~w (~w y ~w)!~n', 
           [Nombre, ValorDadoDoble, ValorDadoDoble, ValorDadoDoble]),
           
    % 1. Tirada inicial (doble)
    test_tirada(Nombre, Tirada1),
    format('~n[TEST] ¡Doble detectado! Aplicando regla: Turno extra para ~w.~n', [Nombre]),
    
    % 2. Tirada extra
    test_tirada(Nombre, TiradaExtra),
    
    % 3. Avanzar turno
    nb_getval(turno_actual, Turno),
    NuevoTurno is Turno + 1,
    nb_setval(turno_actual, NuevoTurno),
    format('~n[TEST] Turno doble de ~w terminado. Avanzamos al turno ~w.~n', [Nombre, NuevoTurno]),
    format('================================================~n').

% test_bancarrota(Nombre) — pone $10 y envia a propiedad cara con dueño
% Comando: swipl -l tests.pl -g "iniciar_juego, test_bancarrota(alice1)" -t halt
test_bancarrota(Nombre) :-
    format('~n================================================~n'),
    format('[TEST BANCARROTA] Preparando escenario para ~w...~n', [Nombre]),
    
    % 1. Dejar poco dinero
    test_dinero(Nombre, 10),
    
    % 2. Buscar otro jugador (dueño)
    nb_getval(jugadores, Jugadores),
    member(Dueno, Jugadores),
    Dueno = jugador(DuenoNombre, _, _, _),
    DuenoNombre \== Nombre, !,
    
    % 3. Asegurar que el dueño tiene la propiedad cara
    ( \+ (Dueno = jugador(_, _, _, PropsD), member(azul2, PropsD))
    -> test_dar_propiedad(DuenoNombre, azul2)
    ;  true
    ),
    
    format('[TEST BANCARROTA] ~w tiene $10 y caera en azul2 (dueño: ~w, alquiler: $50)~n',
           [Nombre, DuenoNombre]),
           
    % 4. Forzar caída
    test_caer_en(Nombre, 39),
    
    % 5. Estado final
    format('[TEST BANCARROTA] Estado final de la partida:~n'),
    nb_getval(jugadores, JugadoresFinales),
    format('Jugadores restantes: ~w~n', [JugadoresFinales]),
    format('================================================~n').

test_bancarrota2(Nombre) :-
    format('~n================================================~n'),
    format('[TEST BANCARROTA 2] Preparando escenario para ~w...~n', [Nombre]),

    % 1. Dejar poco dinero
    test_dinero(Nombre, 10),

    % 2. Darle propiedades para que pueda liquidar
    test_dar_propiedad(Nombre, marron1),
    test_dar_propiedad(Nombre, marron2),

    % 3. Buscar otro jugador (dueño)
    nb_getval(jugadores, Jugadores),
    member(Dueno, Jugadores),
    Dueno = jugador(DuenoNombre, _, _, _),
    DuenoNombre \== Nombre, !,

    % 4. Asegurar que el dueño tiene la propiedad cara
    ( \+ (Dueno = jugador(_, _, _, PropsD), member(azul2, PropsD))
    -> test_dar_propiedad(DuenoNombre, azul2)
    ;  true
    ),

    format('[TEST BANCARROTA 2] ~w tiene $10 pero puede vender propiedades.~n', [Nombre]),
    format('[TEST BANCARROTA 2] Caera en azul2 (dueño: ~w, alquiler: $50)~n', [DuenoNombre]),

    % 5. Forzar caída
    test_caer_en(Nombre, 39),

    % 6. Estado final
    format('[TEST BANCARROTA 2] Estado final de la partida:~n'),
    nb_getval(jugadores, JugadoresFinales),
    format('Jugadores restantes: ~w~n', [JugadoresFinales]),

    format('================================================~n').
    

% --- Escenarios ---

% escenario_1 — dos jugadores, compras iniciales
% Comando: swipl -l tests.pl -g "escenario_1" -t halt
escenario_1 :-
    writeln(''),
    writeln('======== ESCENARIO 1: Compras iniciales ========'),
    iniciar_juego,
    test_caer_en(alice, 1),
    test_caer_en(bob, 6),
    test_caer_en(alice, 3),
    writeln(''),
    writeln('--- Estado tras compras ---'),
    nb_getval(jugadores, J1), format('Jugadores: ~w~n', [J1]),
    writeln('======== FIN ESCENARIO 1 ========'),
    writeln('').

% escenario_2 — jugador con monopolio formado
% Comando: swipl -l tests.pl -g "escenario_2" -t halt
escenario_2 :-
    writeln(''),
    writeln('======== ESCENARIO 2: Monopolio formado ========'),
    iniciar_juego,
    test_dar_propiedad(alice, azul1),
    test_dar_propiedad(alice, azul2),
    writeln(''),
    writeln('--- Comprobacion de monopolio ---'),
    comprobar_monopolios_jugador(alice),
    test_caer_en(bob, 37),
    nb_getval(jugadores, J2), format('Jugadores: ~w~n', [J2]),
    writeln('======== FIN ESCENARIO 2 ========'),
    writeln('').

% escenario_3 — jugador al borde de la bancarrota
% Comando: swipl -l tests.pl -g "escenario_3" -t halt
escenario_3 :-
    writeln(''),
    writeln('======== ESCENARIO 3: Bancarrota ========'),
    iniciar_juego,
    test_dar_propiedad(bob, azul2),
    test_dinero(alice, 30),
    test_dar_propiedad(alice, marron1),
    test_dar_propiedad(alice, marron2),
    writeln(''),
    writeln('--- Alice cae en azul2 de Bob (alquiler $50, alice tiene $30) ---'),
    test_caer_en(alice, 39),
    writeln(''),
    writeln('--- Estado tras posible liquidacion ---'),
    nb_getval(jugadores, J3), format('Jugadores: ~w~n', [J3]),
    writeln('======== FIN ESCENARIO 3 ========'),
    writeln('').

% escenario_4 — multiples pagos de alquiler consecutivos
% Comando: swipl -l tests.pl -g "escenario_4" -t halt
escenario_4 :-
    writeln(''),
    writeln('======== ESCENARIO 4: Pagos consecutivos ========'),
    iniciar_juego,
    test_dar_propiedad(bob, rosa1),
    test_dar_propiedad(bob, rosa2),
    test_dar_propiedad(bob, naranja1),
    writeln(''),
    writeln('--- Alice cae en propiedades de Bob una tras otra ---'),
    test_caer_en(alice, 11),
    test_caer_en(alice, 13),
    test_caer_en(alice, 16),
    writeln(''),
    writeln('--- Estado tras pagos consecutivos ---'),
    nb_getval(jugadores, J4), format('Jugadores: ~w~n', [J4]),
    writeln('======== FIN ESCENARIO 4 ========'),
    writeln('').

% escenario_5 — simulacion completa de 10 turnos
% Comando: swipl -l tests.pl -g "escenario_5" -t halt
escenario_5 :-
    writeln(''),
    writeln('======== ESCENARIO 5: Simulacion 10 turnos ========'),
    iniciar_juego,
    writeln(''),
    writeln('--- Jugando 10 turnos automaticos ---'),
    jugar_turnos(10),
    writeln(''),
    writeln('--- Resultados finales ---'),
    nb_getval(jugadores, J5), format('Jugadores: ~w~n', [J5]),
    writeln('======== FIN ESCENARIO 5 ========'),
    writeln('').
