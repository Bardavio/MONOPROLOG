% REGLAS DEL JUEGO (reglas.pl)
% Regla 0: Compra | Regla 1: Alquiler | Regla 2: Monopolio + Casas | Regla 3: Bancarrota

% --- Regla 0: Compra ---
regla_0_compra(Jugador, NombreProp, ItemGuardado, Precio) :-
    Jugador = jugador(NombreJugador, _, DineroActual, PropiedadesActuales),
    DineroActual >= Precio,
    !,
    DineroTrasCompra is DineroActual - Precio,
    nb_setarg(3, Jugador, DineroTrasCompra),
    nb_setarg(4, Jugador, [ItemGuardado | PropiedadesActuales]),
    format('[Regla 0 - Compra] ~w compra ~w por $~w. Dinero restante: $~w~n',
           [NombreJugador, NombreProp, Precio, DineroTrasCompra]),
    comprobar_monopolios_jugador(NombreJugador).

regla_0_compra(Jugador, NombreProp, _, Precio) :-
    Jugador = jugador(NombreJugador, _, DineroActual, _),
    format('[Regla 0 - Sin fondos] ~w no puede comprar ~w ($~w, cuesta $~w).~n',
           [NombreJugador, NombreProp, DineroActual, Precio]).

% --- Regla 1: Alquiler ---
regla_1_alquiler(Jugador, NombreProp, ItemGuardado, NombreDueno, AlquilerBase) :-
    Jugador = jugador(NombreJugador, _, DineroJugador, _),
    nb_getval(jugadores, Jugadores),
    member(Dueno, Jugadores),
    Dueno = jugador(NombreDueno, _, DineroDueno, _),
    !,
    alquiler_efectivo(ItemGuardado, AlquilerBase, NombreDueno, AlquilerFinal),
    DineroJugadorTras is DineroJugador - AlquilerFinal,
    DineroDuenoTras   is DineroDueno   + AlquilerFinal,
    nb_setarg(3, Jugador, DineroJugadorTras),
    nb_setarg(3, Dueno,   DineroDuenoTras),
    format('[Regla 1 - Alquiler] ~w paga $~w a ~w por ~w.~n',
           [NombreJugador, AlquilerFinal, NombreDueno, NombreProp]).

% --- Alquiler efectivo (con casas y monopolio) ---
alquiler_efectivo(ItemGuardado, AlquilerBase, NombreDueno, AlquilerFinal) :-
    atom(ItemGuardado),
    tablero(Tablero),
    member(propiedad(ItemGuardado, _, Color, _), Tablero),
    !,
    obtener_casas(ItemGuardado, NumCasas),
    ( NumCasas =:= 0 ->
        ( tiene_monopolio(NombreDueno, Color) ->
            AlquilerFinal is AlquilerBase * 2
        ;   AlquilerFinal = AlquilerBase
        )
    ; NumCasas =:= 1 -> AlquilerFinal is AlquilerBase * 5
    ; NumCasas =:= 2 -> AlquilerFinal is AlquilerBase * 15
    ; NumCasas =:= 3 -> AlquilerFinal is AlquilerBase * 37
    ;                   AlquilerFinal is AlquilerBase * 100
    ).

alquiler_efectivo(_, AlquilerBase, _, AlquilerBase).

% --- Regla 2: Monopolio ---
grupo_color(marron,   [marron1, marron2]).
grupo_color(celeste,  [celeste1, celeste2, celeste3]).
grupo_color(rosa,     [rosa1, rosa2, rosa3]).
grupo_color(naranja,  [naranja1, naranja2, naranja3]).
grupo_color(rojo,     [rojo1, rojo2, rojo3]).
grupo_color(amarillo, [amarillo1, amarillo2, amarillo3]).
grupo_color(verde,    [verde1, verde2, verde3]).
grupo_color(azul,     [azul1, azul2]).

tiene_monopolio(NombreJugador, Color) :-
    props_de_jugador(NombreJugador, Propiedades),
    grupo_color(Color, GrupoColor),
    subset_lista(GrupoColor, Propiedades).

comprobar_monopolios_jugador(NombreJugador) :-
    tiene_monopolio(NombreJugador, Color),
    format('[Regla 2 - Monopolio] ~w tiene el monopolio del color ~w y puede construir casas.~n',
           [NombreJugador, Color]),
    construir_casas_auto(NombreJugador, Color),
    fail.
comprobar_monopolios_jugador(_).

% --- Gestion de casas ---

inicializar_casas :-
    nb_setval(casas, []).

% Devuelve el numero de casas en una propiedad (0 si no hay registro)
obtener_casas(NombreProp, NumCasas) :-
    nb_getval(casas, ListaCasas),
    ( member(casas(NombreProp, NumCasas), ListaCasas) -> true ; NumCasas = 0 ).

% Actualiza el numero de casas de una propiedad en el estado global
set_casas(NombreProp, NumCasas) :-
    nb_getval(casas, ListaCasas),
    ( select(casas(NombreProp, _), ListaCasas, ListaSinProp) -> true ; ListaSinProp = ListaCasas ),
    nb_setval(casas, [casas(NombreProp, NumCasas) | ListaSinProp]).

coste_casa(marron,    50).
coste_casa(celeste,   50).
coste_casa(rosa,     100).
coste_casa(naranja,  100).
coste_casa(rojo,     150).
coste_casa(amarillo, 150).
coste_casa(verde,    200).
coste_casa(azul,     200).

% Construye 1 casa en NombreProp si el jugador tiene monopolio y fondos suficientes
construir_casa(NombreJugador, NombreProp) :-
    tablero(Tablero),
    member(propiedad(NombreProp, _, Color, _), Tablero),
    tiene_monopolio(NombreJugador, Color),
    obtener_casas(NombreProp, CasasActuales),
    CasasActuales < 4,
    coste_casa(Color, CosteCasa),
    nb_getval(jugadores, Jugadores),
    member(Jugador, Jugadores),
    Jugador = jugador(NombreJugador, _, DineroActual, _),
    DineroActual >= CosteCasa,
    !,
    DineroTras is DineroActual - CosteCasa,
    nb_setarg(3, Jugador, DineroTras),
    CasasNuevo is CasasActuales + 1,
    set_casas(NombreProp, CasasNuevo),
    format('[Regla 2 - Casa] ~w construye casa en ~w (total: ~w). Coste: $~w. Dinero: $~w~n',
           [NombreJugador, NombreProp, CasasNuevo, CosteCasa, DineroTras]).

construir_casa(NombreJugador, NombreProp) :-
    obtener_casas(NombreProp, CasasActuales),
    ( CasasActuales >= 4 ->
        format('[Regla 2 - Casa] ~w: maximo de casas alcanzado en ~w.~n', [NombreJugador, NombreProp])
    ;   format('[Regla 2 - Casa] ~w no puede construir en ~w (sin fondos o sin monopolio).~n',
               [NombreJugador, NombreProp])
    ).

% Construye 1 casa automatica en cada propiedad del Color al detectar monopolio
construir_casas_auto(NombreJugador, Color) :-
    grupo_color(Color, PropiedadesColor),
    construir_casas_lista(NombreJugador, PropiedadesColor).

construir_casas_lista(_, []).
construir_casas_lista(NombreJugador, [Prop | Resto]) :-
    construir_casa(NombreJugador, Prop),
    construir_casas_lista(NombreJugador, Resto).

% --- Hipotecas ---

inicializar_hipotecas :-
    nb_setval(hipotecas, []).

esta_hipotecada(NombreProp) :-
    nb_getval(hipotecas, H),
    member(NombreProp, H).

% Hipotecar: el jugador recibe el 50% del precio y la propiedad queda bloqueada
hipotecar(NombreJugador, NombreProp) :-
    props_de_jugador(NombreJugador, Propiedades),
    member(NombreProp, Propiedades),
    \+ esta_hipotecada(NombreProp),
    obtener_casas(NombreProp, 0),
    precio_propiedad(NombreProp, Precio),
    ValorHipoteca is Precio // 2,
    nb_getval(jugadores, Jugadores),
    member(Jugador, Jugadores),
    Jugador = jugador(NombreJugador, _, Dinero, _),
    !,
    DineroTras is Dinero + ValorHipoteca,
    nb_setarg(3, Jugador, DineroTras),
    nb_getval(hipotecas, H),
    nb_setval(hipotecas, [NombreProp | H]),
    format('[Hipoteca] ~w hipoteca ~w y recibe $~w. Dinero: $~w~n',
           [NombreJugador, NombreProp, ValorHipoteca, DineroTras]).

hipotecar(NombreJugador, NombreProp) :-
    ( esta_hipotecada(NombreProp) ->
        format('[Hipoteca] ~w ya esta hipotecada.~n', [NombreProp])
    ;   obtener_casas(NombreProp, N), N > 0 ->
        format('[Hipoteca] Debes vender las ~w casas de ~w antes de hipotecar.~n', [N, NombreProp])
    ;   format('[Hipoteca] ~w no puede hipotecar ~w (no es dueno o propiedad invalida).~n',
               [NombreJugador, NombreProp])
    ).

% Levantar hipoteca: el jugador paga el 110% del valor hipotecado
levantar_hipoteca(NombreJugador, NombreProp) :-
    esta_hipotecada(NombreProp),
    props_de_jugador(NombreJugador, Propiedades),
    member(NombreProp, Propiedades),
    precio_propiedad(NombreProp, Precio),
    Coste is (Precio // 2) * 110 // 100,
    nb_getval(jugadores, Jugadores),
    member(Jugador, Jugadores),
    Jugador = jugador(NombreJugador, _, Dinero, _),
    Dinero >= Coste,
    !,
    DineroTras is Dinero - Coste,
    nb_setarg(3, Jugador, DineroTras),
    nb_getval(hipotecas, H),
    delete(H, NombreProp, HTras),
    nb_setval(hipotecas, HTras),
    format('[Hipoteca] ~w levanta la hipoteca de ~w pagando $~w. Dinero: $~w~n',
           [NombreJugador, NombreProp, Coste, DineroTras]).

levantar_hipoteca(_, NombreProp) :-
    \+ esta_hipotecada(NombreProp),
    !,
    format('[Hipoteca] ~w no esta hipotecada.~n', [NombreProp]).

levantar_hipoteca(NombreJugador, NombreProp) :-
    precio_propiedad(NombreProp, Precio),
    Coste is (Precio // 2) * 110 // 100,
    format('[Hipoteca] ~w no tiene fondos para levantar hipoteca de ~w (necesita $~w).~n',
           [NombreJugador, NombreProp, Coste]).

% --- Regla 3: Bancarrota ---
comprobar_bancarrota(Jugador) :-
    Jugador = jugador(NombreJugador, _, Dinero, _),
    Dinero < 0,
    !,
    format('[Regla 3 - Bancarrota] ~w tiene $~w. Intentando liquidar activos...~n',
           [NombreJugador, Dinero]),
    liquidar_activos(Jugador),
    Jugador = jugador(_, _, DineroTrasLiquidacion, _),
    ( DineroTrasLiquidacion < 0
    -> format('[Regla 3 - Eliminacion] ~w sigue en negativo ($~w). Eliminado del juego.~n',
              [NombreJugador, DineroTrasLiquidacion]),
       eliminar_jugador(NombreJugador)
    ;  format('[Regla 3 - Recuperado] ~w se salva con $~w tras liquidar.~n',
              [NombreJugador, DineroTrasLiquidacion])
    ).

comprobar_bancarrota(_).

% Vende todas las propiedades al 50% de su valor
liquidar_activos(Jugador) :-
    Jugador = jugador(NombreJugador, _, Dinero, Propiedades),
    calcular_valor_liquidacion(Propiedades, ValorRecuperado),
    DineroTras is Dinero + ValorRecuperado,
    nb_setarg(3, Jugador, DineroTras),
    nb_setarg(4, Jugador, []),
    format('[Regla 3 - Liquidacion] ~w liquida propiedades por $~w. Dinero: $~w~n',
           [NombreJugador, ValorRecuperado, DineroTras]).

calcular_valor_liquidacion([], 0).
calcular_valor_liquidacion([Prop | Resto], Total) :-
    precio_propiedad(Prop, Precio),
    ( esta_hipotecada(Prop) -> ValProp = 0 ; ValProp is Precio // 2 ),
    calcular_valor_liquidacion(Resto, TotalResto),
    Total is ValProp + TotalResto.

% Busca el precio de una propiedad en el tablero
precio_propiedad(NombreProp, Precio) :-
    tablero(Tablero),
    member(propiedad(NombreProp, Precio, _, _), Tablero), !.

precio_propiedad(estacion(_), Precio) :-
    precio_estacion(Precio), !.

precio_propiedad(servicio(_), Precio) :-
    precio_servicio(Precio), !.

precio_propiedad(_, 0).

% Elimina un jugador de la lista global
eliminar_jugador(NombreJugador) :-
    nb_getval(jugadores, Jugadores),
    exclude([J]>>(J = jugador(NombreJugador, _, _, _)), Jugadores, JugadoresRestantes),
    nb_setval(jugadores, JugadoresRestantes),
    format('[Regla 3] ~w ha sido eliminado del juego.~n', [NombreJugador]).
