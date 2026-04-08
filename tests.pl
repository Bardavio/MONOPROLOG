% TESTS Y ESCENARIOS (tests.pl)
:- [main].

% --- Herramientas de prueba ---

% Fuerza una tirada exacta para un jugador
% swipl -l tests.pl -g "iniciar_juego, test_tirada(alice, 4)" -t halt
test_tirada(NombreJugador, Tirada) :-
    nb_getval(jugadores, Jugadores),
    member(Jugador, Jugadores),
    Jugador = jugador(NombreJugador, _, _, _),
    mover_jugador_con_tirada(Jugador, Tirada),
    Jugador = jugador(_, PosNueva, _, _),
    casilla_en(PosNueva, Casilla),
    format('~n[TEST] ~w saca ~w. Cae en pos ~w.~n', [NombreJugador, Tirada, PosNueva]),
    aplicar_casilla(Casilla, Jugador),
    format('[TEST] Estado: ~w~n', [Jugador]).

% Teletransporta a un jugador directamente a una casilla
% swipl -l tests.pl -g "iniciar_juego, test_caer_en(bob, 30)" -t halt
test_caer_en(NombreJugador, IndiceCasilla) :-
    nb_getval(jugadores, Jugadores),
    member(Jugador, Jugadores),
    Jugador = jugador(NombreJugador, _, _, _),
    nb_setarg(2, Jugador, IndiceCasilla),
    casilla_en(IndiceCasilla, Casilla),
    format('~n[TEST] ~w teleportado a casilla ~w (~w).~n', [NombreJugador, IndiceCasilla, Casilla]),
    aplicar_casilla(Casilla, Jugador),
    format('[TEST] Estado: ~w~n', [Jugador]).

% Ajusta el dinero de un jugador directamente
% swipl -l tests.pl -g "iniciar_juego, test_dinero(alice, 10)" -t halt
test_dinero(NombreJugador, DineroNuevo) :-
    nb_getval(jugadores, Jugadores),
    member(Jugador, Jugadores),
    Jugador = jugador(NombreJugador, _, _, _),
    nb_setarg(3, Jugador, DineroNuevo),
    format('~n[TEST] Dinero de ~w ajustado a $~w.~n', [NombreJugador, DineroNuevo]).

% Da una propiedad a un jugador directamente (sin compra)
% swipl -l tests.pl -g "iniciar_juego, test_dar_propiedad(bob, azul2)" -t halt
test_dar_propiedad(NombreJugador, NuevaProp) :-
    nb_getval(jugadores, Jugadores),
    member(Jugador, Jugadores),
    Jugador = jugador(NombreJugador, _, _, PropiedadesActuales),
    \+ member(NuevaProp, PropiedadesActuales),
    nb_setarg(4, Jugador, [NuevaProp | PropiedadesActuales]),
    format('~n[TEST] ~w recibe la propiedad ~w.~n', [NombreJugador, NuevaProp]).

% Fuerza un turno con dobles: tirada inicial doble + tirada extra
test_turno_doble(NombreJugador, ValorDoble, TiradaExtra) :-
    TiradaDoble is ValorDoble * 2,
    format('~n================================================'),
    format('~n[TEST] ~w lanza doble ~w + extra ~w.~n',
           [NombreJugador, ValorDoble, TiradaExtra]),
    test_tirada(NombreJugador, TiradaDoble),
    format('[TEST] Doble! Turno extra para ~w.~n', [NombreJugador]),
    test_tirada(NombreJugador, TiradaExtra),
    nb_getval(turno_actual, Turno),
    TurnoSiguiente is Turno + 1,
    nb_setval(turno_actual, TurnoSiguiente),
    format('[TEST] Fin turno doble. Turno avanzado a ~w.~n', [TurnoSiguiente]),
    format('================================================~n').

% Prepara el escenario de bancarrota sin recuperacion (jugador es eliminado)
% swipl -l tests.pl -g "iniciar_juego, test_bancarrota(alice1)" -t halt
test_bancarrota(NombreJugador) :-
    format('~n================================================~n'),
    format('[TEST BANCARROTA] Preparando ~w con $10 sin propiedades...~n', [NombreJugador]),
    test_dinero(NombreJugador, 10),
    nb_getval(jugadores, Jugadores),
    member(Dueno, Jugadores),
    Dueno = jugador(NombreDueno, _, _, _),
    NombreDueno \== NombreJugador, !,
    ( \+ (Dueno = jugador(_, _, _, Props), member(azul2, Props))
    -> test_dar_propiedad(NombreDueno, azul2)
    ;  true
    ),
    format('[TEST BANCARROTA] ~w (dueño: ~w) caera en azul2 (alquiler $50).~n',
           [NombreJugador, NombreDueno]),
    test_caer_en(NombreJugador, 39),
    nb_getval(jugadores, JugadoresFinales),
    format('Jugadores restantes: ~w~n', [JugadoresFinales]),
    format('================================================~n').

% Prepara bancarrota con recuperacion via liquidacion de propiedades
test_bancarrota2(NombreJugador) :-
    format('~n================================================~n'),
    format('[TEST BANCARROTA 2] ~w con $10 y propiedades para liquidar...~n', [NombreJugador]),
    test_dinero(NombreJugador, 10),
    test_dar_propiedad(NombreJugador, marron1),
    test_dar_propiedad(NombreJugador, marron2),
    nb_getval(jugadores, Jugadores),
    member(Dueno, Jugadores),
    Dueno = jugador(NombreDueno, _, _, _),
    NombreDueno \== NombreJugador, !,
    ( \+ (Dueno = jugador(_, _, _, Props), member(azul2, Props))
    -> test_dar_propiedad(NombreDueno, azul2)
    ;  true
    ),
    format('[TEST BANCARROTA 2] Caera en azul2 de ~w. Deberia liquidar y sobrevivir.~n', [NombreDueno]),
    test_caer_en(NombreJugador, 39),
    nb_getval(jugadores, JugadoresFinales),
    format('Jugadores restantes: ~w~n', [JugadoresFinales]),
    format('================================================~n').

% --- Escenarios ---

% Escenario 1: Dos jugadores hacen compras iniciales
% swipl -l tests.pl -g "escenario_1" -t halt
escenario_1 :-
    writeln(''),
    writeln('======== ESCENARIO 1: Compras iniciales ========'),
    iniciar_juego,
    test_caer_en(alice, 1),   % marron1
    test_caer_en(bob,   6),   % celeste1
    test_caer_en(alice, 3),   % marron2 -> monopolio!
    writeln('--- Estado tras compras ---'),
    nb_getval(jugadores, J), format('Jugadores: ~w~n', [J]),
    mostrar_ranking,
    writeln('======== FIN ESCENARIO 1 ========').

% Escenario 2: Un jugador forma monopolio y se construyen casas automaticamente
% swipl -l tests.pl -g "escenario_2" -t halt
escenario_2 :-
    writeln(''),
    writeln('======== ESCENARIO 2: Monopolio formado ========'),
    iniciar_juego,
    test_dar_propiedad(alice, azul1),
    test_dar_propiedad(alice, azul2),
    writeln('--- Verificando monopolio ---'),
    comprobar_monopolios_jugador(alice),
    obtener_casas(azul1, C1), format('Casas en azul1: ~w~n', [C1]),
    obtener_casas(azul2, C2), format('Casas en azul2: ~w~n', [C2]),
    writeln('--- Bob cae en azul1 (alquiler elevado con casas) ---'),
    test_caer_en(bob, 37),
    nb_getval(jugadores, J), format('Jugadores: ~w~n', [J]),
    mostrar_ranking,
    writeln('======== FIN ESCENARIO 2 ========').

% Escenario 3: Jugador al borde de la bancarrota pero se recupera
% swipl -l tests.pl -g "escenario_3" -t halt
escenario_3 :-
    writeln(''),
    writeln('======== ESCENARIO 3: Bancarrota con recuperacion ========'),
    iniciar_juego,
    test_dar_propiedad(bob, azul2),
    test_dinero(alice, 30),
    test_dar_propiedad(alice, marron1),
    test_dar_propiedad(alice, marron2),
    writeln('--- Alice ($30) cae en azul2 de Bob (alquiler $50). Liquidara propiedades. ---'),
    test_caer_en(alice, 39),
    nb_getval(jugadores, J), format('Jugadores: ~w~n', [J]),
    mostrar_ranking,
    writeln('======== FIN ESCENARIO 3 ========').

% Escenario 4: Multiples pagos de alquiler consecutivos
% swipl -l tests.pl -g "escenario_4" -t halt
escenario_4 :-
    writeln(''),
    writeln('======== ESCENARIO 4: Alquileres consecutivos ========'),
    iniciar_juego,
    test_dar_propiedad(bob, rosa1),
    test_dar_propiedad(bob, rosa2),
    test_dar_propiedad(bob, naranja1),
    writeln('--- Alice cae en tres propiedades de Bob consecutivamente ---'),
    test_caer_en(alice, 11),  % rosa1
    test_caer_en(alice, 13),  % rosa2
    test_caer_en(alice, 16),  % naranja1
    nb_getval(jugadores, J), format('Jugadores: ~w~n', [J]),
    mostrar_ranking,
    writeln('======== FIN ESCENARIO 4 ========').

% Escenario 5: Simulacion completa de 10 turnos con metricas
% swipl -l tests.pl -g "escenario_5" -t halt
escenario_5 :-
    writeln(''),
    writeln('======== ESCENARIO 5: Simulacion 10 turnos ========'),
    iniciar_juego,
    jugar_turnos(10),
    writeln('--- Resultados ---'),
    nb_getval(jugadores, J), format('Jugadores: ~w~n', [J]),
    mostrar_ranking,
    writeln('======== FIN ESCENARIO 5 ========').

% Escenario Casas: monopolio + construccion manual + alquiler escalado
% swipl -l tests.pl -g "escenario_casas" -t halt
escenario_casas :-
    writeln(''),
    writeln('======== ESCENARIO CASAS: Monopolio + Casas + Alquiler Elevado ========'),
    iniciar_juego,
    test_dar_propiedad(alice, marron1),
    test_dar_propiedad(alice, marron2),
    comprobar_monopolios_jugador(alice),
    obtener_casas(marron1, C1), format('Casas en marron1: ~w~n', [C1]),
    obtener_casas(marron2, C2), format('Casas en marron2: ~w~n', [C2]),
    writeln('--- Alice construye 2 casas mas en marron1 manualmente ---'),
    construir_casa(alice, marron1),
    construir_casa(alice, marron1),
    obtener_casas(marron1, C3), format('Casas en marron1 ahora: ~w~n', [C3]),
    writeln('--- Bob cae en marron1 con 3 casas ---'),
    test_caer_en(bob, 1),
    mostrar_estado,
    mostrar_ranking,
    mostrar_tablero,
    writeln('======== FIN ESCENARIO CASAS ========').

% Escenario 6: Alquiler doble por monopolio sin casas
% swipl -l tests.pl -g "escenario_alquiler_monopolio" -t halt
escenario_alquiler_monopolio :-
    writeln(''),
    writeln('======== ESCENARIO 6: Alquiler doble con monopolio (sin casas) ========'),
    iniciar_juego,
    % Alice tiene monopolio naranja pero NO tiene dinero para construir casas
    test_dar_propiedad(alice, naranja1),
    test_dar_propiedad(alice, naranja2),
    test_dar_propiedad(alice, naranja3),
    test_dinero(alice, 0),   % Sin dinero para construir casas
    writeln('--- Alice tiene monopolio naranja con $0 (no puede construir casas) ---'),
    comprobar_monopolios_jugador(alice),
    writeln('--- Bob cae en naranja1: alquiler debe ser x2 (monopolio sin casas) ---'),
    % alquiler base naranja = 14, con monopolio sin casas = 28
    test_caer_en(bob, 16),
    nb_getval(jugadores, J), format('Jugadores: ~w~n', [J]),
    writeln('======== FIN ESCENARIO 6 ========').

% Escenario 7: Eliminacion completa de jugador insolvente
% swipl -l tests.pl -g "escenario_eliminacion" -t halt
escenario_eliminacion :-
    writeln(''),
    writeln('======== ESCENARIO 7: Eliminacion de jugador ========'),
    iniciar_juego,
    % Bob tiene las 2 azules con 4 casas cada una
    test_dar_propiedad(bob, azul1),
    test_dar_propiedad(bob, azul2),
    comprobar_monopolios_jugador(bob),   % 1 casa automatica
    construir_casa(bob, azul1), construir_casa(bob, azul1), construir_casa(bob, azul1), % 4 total
    construir_casa(bob, azul2), construir_casa(bob, azul2), construir_casa(bob, azul2),
    obtener_casas(azul1, C1), obtener_casas(azul2, C2),
    format('Casas: azul1=~w, azul2=~w~n', [C1, C2]),
    % Alice con muy poco dinero
    test_dinero(alice, 5),
    alquiler_color(azul, AlqBase),
    alquiler_efectivo(azul1, AlqBase, bob, AlqFinal),
    format('--- Alice ($5) cae en azul1 de Bob (alquiler: $~w). Sin salvacion. ---~n', [AlqFinal]),
    test_caer_en(alice, 37),
    nb_getval(jugadores, JugadoresFinales),
    format('Jugadores restantes: ~w~n', [JugadoresFinales]),
    mostrar_ranking,
    writeln('======== FIN ESCENARIO 7 ========').

% Escenario 8: Verificacion de deteccion de estancamiento
% swipl -l tests.pl -g "escenario_estancamiento" -t halt
escenario_estancamiento :-
    writeln(''),
    writeln('======== ESCENARIO 8: Deteccion de estancamiento ========'),
    iniciar_juego,
    writeln('--- Simulando 10 turnos (todos en casillas sin efecto economico) ---'),
    % Colocar a todos en carcel (sin efecto economico) para forzar estancamiento
    nb_getval(jugadores, Jugadores),
    maplist([J]>>(nb_setarg(2, J, 10)), Jugadores),
    jugar_turnos(10),
    writeln('--- Si hubo estancamiento, deberias haberlo visto arriba ---'),
    mostrar_ranking,
    writeln('======== FIN ESCENARIO 8 ========').

% Escenario 9: Dos monopolios en juego, alquileres cruzados elevados
% swipl -l tests.pl -g "escenario_monopolios_cruzados" -t halt
escenario_monopolios_cruzados :-
    writeln(''),
    writeln('======== ESCENARIO 9: Dos monopolios en juego ========'),
    iniciar_juego,
    % Alice: monopolio marron
    test_dar_propiedad(alice, marron1),
    test_dar_propiedad(alice, marron2),
    comprobar_monopolios_jugador(alice),
    % Bob: monopolio azul
    test_dar_propiedad(bob, azul1),
    test_dar_propiedad(bob, azul2),
    comprobar_monopolios_jugador(bob),
    writeln('--- Alice cae en azul de Bob (alquiler x5 con 1 casa) ---'),
    test_caer_en(alice, 37),  % azul1 de bob, 1 casa
    writeln('--- Bob cae en marron de Alice (alquiler x5 con 1 casa) ---'),
    test_caer_en(bob, 1),     % marron1 de alice, 1 casa
    nb_getval(jugadores, J), format('Jugadores: ~w~n', [J]),
    mostrar_ranking,
    writeln('======== FIN ESCENARIO 9 ========').

% --- Escenario 10: Hipotecas ---
escenario_hipotecas :-
    writeln(''),
    writeln('======== ESCENARIO 10: Hipotecas ========'),
    iniciar_juego,
    % Alice tiene las dos marrones con poco dinero
    test_dar_propiedad(alice, marron1),
    test_dar_propiedad(alice, marron2),
    test_dinero(alice, 50),
    writeln('--- Estado inicial ---'),
    nb_getval(jugadores, J0), format('Jugadores: ~w~n', [J0]),
    % Alice hipoteca marron2 (recibe 30 = 60//2)
    writeln('--- Alice hipoteca marron2 ---'),
    hipotecar(alice, marron2),
    nb_getval(jugadores, J1), format('Jugadores: ~w~n', [J1]),
    % Bob cae en marron2: no debe pagar alquiler (hipotecada)
    writeln('--- Bob cae en marron2 (hipotecada, sin alquiler) ---'),
    test_caer_en(bob, 3),
    nb_getval(jugadores, J2), format('Jugadores: ~w~n', [J2]),
    % Bob cae en marron1: paga alquiler normal
    writeln('--- Bob cae en marron1 (alquiler normal) ---'),
    test_caer_en(bob, 1),
    nb_getval(jugadores, J3), format('Jugadores: ~w~n', [J3]),
    % Alice levanta la hipoteca de marron2 (paga 33 = 30*110//100)
    writeln('--- Alice levanta hipoteca de marron2 ---'),
    levantar_hipoteca(alice, marron2),
    nb_getval(jugadores, J4), format('Jugadores: ~w~n', [J4]),
    % Bob cae en marron2 de nuevo: ahora si paga
    writeln('--- Bob cae en marron2 (hipoteca levantada, paga alquiler) ---'),
    test_caer_en(bob, 3),
    nb_getval(jugadores, J5), format('Jugadores: ~w~n', [J5]),
    mostrar_ranking,
    writeln('======== FIN ESCENARIO 10 ========').
