% REGLAS DEL JUEGO (reglas.pl)
% Regla 0: Compra | Regla 1: Alquiler | Regla 2: Monopolio | Regla 3: Bancarrota

% --- Regla 0: Compra ---
regla_0_compra(Jugador, NombreVisual, ItemGuardado, Precio) :-
    Jugador = jugador(NombreJ, _, Dinero, Props),
    Dinero >= Precio,
    !,
    NuevoDinero is Dinero - Precio,
    nb_setarg(3, Jugador, NuevoDinero),
    nb_setarg(4, Jugador, [ItemGuardado | Props]),
    format('[Regla 0 - Compra] ~w compra ~w por $~w. Dinero restante: $~w~n', 
           [NombreJ, NombreVisual, Precio, NuevoDinero]),
    comprobar_monopolios_jugador(NombreJ).

% Si esta libre pero no hay fondos
regla_0_compra(Jugador, NombreVisual, _, Precio) :-
    Jugador = jugador(NombreJ, _, Dinero, _),
    format('[Regla 0 - Sin fondos] ~w no tiene dinero para comprar ~w ($~w, cuesta $~w).~n', 
           [NombreJ, NombreVisual, Dinero, Precio]).

% --- Regla 1: Alquiler ---
regla_1_alquiler(Jugador, NombreVisual, DuenoNombre, Alquiler) :-
    Jugador = jugador(NombreJ, _, DineroJ, _),
    nb_getval(jugadores, Jugadores),
    member(DuenoJugador, Jugadores),
    DuenoJugador = jugador(DuenoNombre, _, DineroD, _),
    !,
    NuevoDineroJ is DineroJ - Alquiler,
    NuevoDineroD is DineroD + Alquiler,
    nb_setarg(3, Jugador, NuevoDineroJ),
    nb_setarg(3, DuenoJugador, NuevoDineroD),
    format('[Regla 1 - Alquiler] ~w paga $~w a ~w por ~w.~n', 
           [NombreJ, Alquiler, DuenoNombre, NombreVisual]).

% --- Regla 2: Monopolio ---
grupo_color(marron, [marron1, marron2]).
grupo_color(celeste, [celeste1, celeste2, celeste3]).
grupo_color(rosa, [rosa1, rosa2, rosa3]).
grupo_color(naranja, [naranja1, naranja2, naranja3]).
grupo_color(rojo, [rojo1, rojo2, rojo3]).
grupo_color(amarillo, [amarillo1, amarillo2, amarillo3]).
grupo_color(verde, [verde1, verde2, verde3]).
grupo_color(azul, [azul1, azul2]).

tiene_monopolio(NombreJugador, Color) :-
    props_de_jugador(NombreJugador, Props),
    grupo_color(Color, Grupo),
    subset_lista(Grupo, Props).

comprobar_monopolios_jugador(NombreJugador) :-
    tiene_monopolio(NombreJugador, Color),
    format('[Regla 2 - Monopolio] ~w tiene el monopolio del color ~w y puede construir casas.~n',
           [NombreJugador, Color]),
    fail.
comprobar_monopolios_jugador(_).

% --- Regla 3: Bancarrota ---
% Se llama tras pagar alquiler o impuesto. Si dinero < 0:
%   1) liquidar_activos: vende propiedades al 50%
%   2) eliminar_jugador: si sigue en negativo, lo saca del juego

comprobar_bancarrota(Jugador) :-
    Jugador = jugador(Nombre, _, Dinero, _),
    Dinero < 0,
    !,
    format('[Regla 3 - Bancarrota] ~w tiene $~w (negativo). Intentando liquidar activos...~n',
           [Nombre, Dinero]),
    liquidar_activos(Jugador),
    Jugador = jugador(_, _, DineroPost, _),
    ( DineroPost < 0
    -> format('[Regla 3 - Eliminacion] ~w sigue en negativo ($~w) tras liquidar. Eliminado del juego.~n',
              [Nombre, DineroPost]),
       eliminar_jugador(Nombre)
    ;  format('[Regla 3 - Recuperado] ~w se salva tras liquidar. Dinero actual: $~w~n',
              [Nombre, DineroPost])
    ).

comprobar_bancarrota(_). % Si no esta en negativo, no pasa nada

% Vende todas las propiedades a mitad de precio
liquidar_activos(Jugador) :-
    Jugador = jugador(Nombre, _, Dinero, Props),
    calcular_valor_liquidacion(Props, ValorRecuperado),
    NuevoDinero is Dinero + ValorRecuperado,
    nb_setarg(3, Jugador, NuevoDinero),
    nb_setarg(4, Jugador, []),
    format('[Regla 3 - Liquidacion] ~w vende todas sus propiedades por $~w. Dinero: $~w~n',
           [Nombre, ValorRecuperado, NuevoDinero]).

% Suma mitad del precio de cada propiedad
calcular_valor_liquidacion([], 0).

calcular_valor_liquidacion([Prop|Rest], Total) :-
    precio_propiedad(Prop, Precio),
    calcular_valor_liquidacion(Rest, RestTotal),
    Total is (Precio // 2) + RestTotal.

% Busca el precio de una propiedad en el tablero
precio_propiedad(Nombre, Precio) :-
    tablero(T),
    member(propiedad(Nombre, Precio, _, _), T), !.

precio_propiedad(estacion(_), Precio) :-
    precio_estacion(Precio), !.

precio_propiedad(servicio(_), Precio) :-
    precio_servicio(Precio), !.

precio_propiedad(_, 0).

% Elimina al jugador de la lista global
eliminar_jugador(Nombre) :-
    nb_getval(jugadores, Jugadores),
    exclude([J]>>(J = jugador(Nombre, _, _, _)), Jugadores, NuevaLista),
    nb_setval(jugadores, NuevaLista),
    format('[Regla 3] ~w ha sido eliminado del juego.~n', [Nombre]).
