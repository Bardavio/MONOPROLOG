% MONOPOLY EN PROLOG (main.pl)

:- [reglas].
:- [metricas].

% --- Estado global ---
iniciar_juego :-
    nb_setval(jugadores, [
        jugador(alice,  0, 1500, []),
        jugador(bob,    0, 1500, []),
        jugador(carter, 0, 1500, []),
        jugador(dylan,   0, 1500, []),
        jugador(eloy, 0, 1500, []),
        jugador(lito,   0, 1500, [])
    ]),
    nb_setval(turno_actual, 0),
    inicializar_casas,
    inicializar_hipotecas,
    inicializar_metricas,
    writeln('================================================'),
    writeln('Partida iniciada (6 jugadores, $1500 cada uno).'),
    writeln('Usa "jugar_turno." o "jugar_turnos(N)."'),
    writeln('================================================').

% --- Tablero (40 casillas, indices 0-39) ---
tablero(Tablero) :-
    Tablero = [
        casilla(salida,      'Cobras $200 al pasar'),   % 0
        propiedad(marron1,   60,  marron,   libre),      % 1
        casilla(carta,       'Carta de Comunidad'),      % 2
        propiedad(marron2,   60,  marron,   libre),      % 3
        casilla(impuesto,    200),                       % 4
        estacion(norte,      libre),                     % 5
        propiedad(celeste1,  100, celeste,  libre),      % 6
        casilla(chance,      'Carta de Suerte'),         % 7
        propiedad(celeste2,  100, celeste,  libre),      % 8
        propiedad(celeste3,  120, celeste,  libre),      % 9
        casilla(carcel,      'Solo de visita'),          % 10
        propiedad(rosa1,     140, rosa,     libre),      % 11
        servicio(electrica,  libre),                     % 12
        propiedad(rosa2,     140, rosa,     libre),      % 13
        propiedad(rosa3,     160, rosa,     libre),      % 14
        estacion(sur,        libre),                     % 15
        propiedad(naranja1,  180, naranja,  libre),      % 16
        casilla(carta,       'Carta de Comunidad'),      % 17
        propiedad(naranja2,  180, naranja,  libre),      % 18
        propiedad(naranja3,  200, naranja,  libre),      % 19
        casilla(parking,     'Parking gratuito'),        % 20
        propiedad(rojo1,     220, rojo,     libre),      % 21
        casilla(chance,      'Carta de Suerte'),         % 22
        propiedad(rojo2,     220, rojo,     libre),      % 23
        propiedad(rojo3,     240, rojo,     libre),      % 24
        estacion(este,       libre),                     % 25
        propiedad(amarillo1, 260, amarillo, libre),      % 26
        propiedad(amarillo2, 260, amarillo, libre),      % 27
        servicio(agua,       libre),                     % 28
        propiedad(amarillo3, 280, amarillo, libre),      % 29
        casilla(ir_a_carcel, 'Ve directamente a la carcel'), % 30
        propiedad(verde1,    300, verde,    libre),      % 31
        propiedad(verde2,    300, verde,    libre),      % 32
        casilla(carta,       'Carta de Comunidad'),      % 33
        propiedad(verde3,    320, verde,    libre),      % 34
        estacion(oeste,      libre),                     % 35
        casilla(chance,      'Carta de Suerte'),         % 36
        propiedad(azul1,     350, azul,     libre),      % 37
        casilla(impuesto,    100),                       % 38
        propiedad(azul2,     400, azul,     libre)       % 39
    ].


longitud_tablero(Longitud) :-
    tablero(Tablero),
    length(Tablero, Longitud).

casilla_en(Indice, Casilla) :-
    tablero(Tablero),
    nth0(Indice, Tablero, Casilla).

% --- Dados predefinidos (ciclicos) ---
secuencia_dado1([3, 5, 2, 6, 1, 4, 2, 5, 3, 1, 4, 6, 2, 3, 5, 1, 4, 2, 6, 3]).
secuencia_dado2([3, 4, 6, 1, 3, 4, 1, 3, 6, 2, 5, 4, 3, 6, 2, 4, 1, 5, 3, 2]).

valor_dado1(Turno, Valor) :-
    secuencia_dado1(Tiradas),
    length(Tiradas, LongSecuencia),
    Indice is Turno mod LongSecuencia,
    nth0(Indice, Tiradas, Valor).

valor_dado2(Turno, Valor) :-
    secuencia_dado2(Tiradas),
    length(Tiradas, LongSecuencia),
    Indice is Turno mod LongSecuencia,
    nth0(Indice, Tiradas, Valor).

valor_dados(Turno, Total) :-
    valor_dado1(Turno, V1),
    valor_dado2(Turno, V2),
    Total is V1 + V2.

es_doble(Turno) :-
    valor_dado1(Turno, Valor),
    valor_dado2(Turno, Valor).

% --- Movimiento ---
nueva_posicion(PosActual, Tirada, PosNueva) :-
    longitud_tablero(Longitud),
    PosNueva is (PosActual + Tirada) mod Longitud.

pasa_por_salida(PosActual, Tirada) :-
    longitud_tablero(Longitud),
    PosActual + Tirada >= Longitud.

mover_jugador(Jugador, Turno) :-
    valor_dados(Turno, Tirada),
    mover_jugador_con_tirada(Jugador, Tirada).

mover_jugador_con_tirada(Jugador, Tirada) :-
    Jugador = jugador(_, PosActual, DineroActual, _),
    nueva_posicion(PosActual, Tirada, PosNueva),
    ( pasa_por_salida(PosActual, Tirada)
    -> DineroTras is DineroActual + 200
    ;  DineroTras = DineroActual
    ),
    nb_setarg(2, Jugador, PosNueva),
    nb_setarg(3, Jugador, DineroTras).

% --- Enrutador de casillas ---
% Unifica con nombre visual, item a guardar, precio y alquiler base
item_comprable(propiedad(Nombre, Precio, Color, _), Nombre, Nombre, Precio, AlquilerBase) :-
    alquiler_color(Color, AlquilerBase).

item_comprable(estacion(Nombre, _), Nombre, estacion(Nombre), Precio, AlquilerBase) :-
    precio_estacion(Precio),
    alquiler(Precio, AlquilerBase).

item_comprable(servicio(Nombre, _), Nombre, servicio(Nombre), Precio, AlquilerBase) :-
    precio_servicio(Precio),
    alquiler(Precio, AlquilerBase).

% Busca el dueno de un item en las propiedades de todos los jugadores
estado_dueno(ItemGuardado, NombreDueno) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(NombreDueno, _, _, Propiedades), Jugadores),
    member(ItemGuardado, Propiedades),
    !.

estado_dueno(_, libre).

% Casillas especiales
aplicar_casilla(casilla(ir_a_carcel, _), Jugador) :-
    nb_setarg(2, Jugador, 10), !.

aplicar_casilla(casilla(impuesto, Cantidad), Jugador) :-
    Jugador = jugador(_, _, Dinero, _),
    DineroTras is Dinero - Cantidad,
    nb_setarg(3, Jugador, DineroTras),
    comprobar_bancarrota(Jugador), !.

% Enrutador principal: compra si libre, alquiler si tiene dueno ajeno
aplicar_casilla(Casilla, Jugador) :-
    item_comprable(Casilla, NombreVisual, ItemGuardado, Precio, AlquilerBase),
    estado_dueno(ItemGuardado, NombreDueno),
    Jugador = jugador(NombreJugador, _, _, _),
    ( NombreDueno == libre ->
        regla_0_compra(Jugador, NombreVisual, ItemGuardado, Precio)
    ; NombreDueno \== NombreJugador ->
        ( esta_hipotecada(ItemGuardado) ->
            format('[Hipoteca] ~w esta hipotecada, no se cobra alquiler.~n', [ItemGuardado])
        ;   regla_1_alquiler(Jugador, NombreVisual, ItemGuardado, NombreDueno, AlquilerBase),
            comprobar_bancarrota(Jugador)
        )
    ; true
    ),
    !.

aplicar_casilla(_, _).

% --- Control de turno ---
ejecutar_turno(IndiceJugador, Turno) :-
    nb_getval(jugadores, Jugadores),
    nth0(IndiceJugador, Jugadores, Jugador),
    Jugador = jugador(NombreJugador, _, _, _),
    mover_jugador(Jugador, Turno),
    Jugador = jugador(_, PosNueva, _, _),
    casilla_en(PosNueva, Casilla),
    aplicar_casilla(Casilla, Jugador),
    valor_dados(Turno, Tirada),
    format('~n--- TURNO ~w ---~n', [Turno]),
    format('Juega: ~w | Tirada: ~w | Pos: ~w (~w)~n', [NombreJugador, Tirada, PosNueva, Casilla]),
    format('Estado: ~w~n', [Jugador]).

jugar_turno :-
    nb_getval(turno_actual, Turno),
    nb_getval(jugadores, Jugadores),
    length(Jugadores, NumJugadores),
    IndiceJugador is Turno mod NumJugadores,
    ejecutar_turno(IndiceJugador, Turno),
    TurnoSiguiente is Turno + 1,
    nb_setval(turno_actual, TurnoSiguiente),
    % Turno extra si saca dobles
    ( es_doble(Turno)
    -> nth0(IndiceJugador, Jugadores, Jugador),
       Jugador = jugador(NombreJugador, _, _, _),
       format('[Doble] ~w lanza de nuevo!~n', [NombreJugador]),
       ejecutar_turno(IndiceJugador, TurnoSiguiente),
       TurnoTrasDoble is TurnoSiguiente + 1,
       nb_setval(turno_actual, TurnoTrasDoble)
    ;  true
    ),
    registrar_estado_turno,
    detectar_estancamiento.

jugar_turnos(0) :- !.
jugar_turnos(N) :-
    N > 0,
    jugar_turno,
    N1 is N - 1,
    jugar_turnos(N1).

% --- Consultas globales ---
props_de_jugador(NombreJugador, Propiedades) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(NombreJugador, _, _, Propiedades), Jugadores).

propiedades_de_dueno(NombreDueno, SoloPropiedades) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(NombreDueno, _, _, TodasProps), Jugadores),
    % Como Propiedad no tiene clausula tenemos que filtrar por exclusion en vez de por inclusion
    % TODO: Añadir una clausula a Propiedad ?
    include([X]>>(X \= estacion(_), X \= servicio(_)), TodasProps, SoloPropiedades).

estaciones_de_dueno(NombreDueno, ListaEstaciones) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(NombreDueno, _, _, Propiedades), Jugadores),
    findall(Nombre, member(estacion(Nombre), Propiedades), ListaEstaciones).

servicios_de_dueno(NombreDueno, ListaServicios) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(NombreDueno, _, _, Propiedades), Jugadores),
    findall(Nombre, member(servicio(Nombre), Propiedades), ListaServicios).

% --- Valores base del tablero ---
alquiler_color(marron,    2).
alquiler_color(celeste,   6).
alquiler_color(rosa,     10).
alquiler_color(naranja,  14).
alquiler_color(rojo,     18).
alquiler_color(amarillo, 22).
alquiler_color(verde,    26).
alquiler_color(azul,     50).

precio_estacion(200).
precio_servicio(150).

% Alquiler de 10% (estaciones y servicios)
alquiler(Precio, AlquilerBase) :- AlquilerBase is Precio // 10.

propiedad_libre(NombreProp) :-
    nb_getval(jugadores, Jugadores),
    \+ (member(jugador(_, _, _, Propiedades), Jugadores), member(NombreProp, Propiedades)).

dueno_de(NombreProp, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Propiedades),
    member(NombreProp, Propiedades).

dueno_estacion(NombreEstacion, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Propiedades),
    member(estacion(NombreEstacion), Propiedades).

dueno_servicio(NombreServicio, JugadorDueno) :-
    nb_getval(jugadores, Jugadores),
    member(JugadorDueno, Jugadores),
    JugadorDueno = jugador(_, _, _, Propiedades),
    member(servicio(NombreServicio), Propiedades).

subset_lista([], _).
subset_lista([X | Xs], Lista) :-
    member(X, Lista),
    subset_lista(Xs, Lista).

% --- Interfaz ASCII del tablero ---

% Rellena o trunca un atom a exactamente N caracteres (relleno con espacios por la derecha)
atom_fijo(Atom, N, Resultado) :-
    format(atom(A), '~w', [Atom]),
    atom_length(A, L),
    ( L >= N ->
        sub_atom(A, 0, N, _, Resultado)
    ;
        Diff is N - L,
        length(EspaciosLista, Diff),
        maplist(=(' '), EspaciosLista),
        atom_chars(Relleno, EspaciosLista),
        atom_concat(A, Relleno, Resultado)
    ).

% Nombre de la casilla en exactamente 7 caracteres
nombre_casilla_7(casilla(salida,      _), 'SALIDA ').
nombre_casilla_7(casilla(carta,       _), 'CARTA  ').
nombre_casilla_7(casilla(chance,      _), 'SUERTE ').
nombre_casilla_7(casilla(impuesto,    _), 'IMPUEST').
nombre_casilla_7(casilla(carcel,      _), 'CARCEL ').
nombre_casilla_7(casilla(parking,     _), 'PARKING').
nombre_casilla_7(casilla(ir_a_carcel, _), 'IRCARCL').
nombre_casilla_7(propiedad(N, _, _, _), R) :- atom_fijo(N, 7, R).
nombre_casilla_7(estacion(N, _), R)  :- atom_concat('E.', N, A), atom_fijo(A, 7, R).
nombre_casilla_7(servicio(N, _), R)  :- atom_concat('S.', N, A), atom_fijo(A, 7, R).

% Inicial del dueno: letra si tiene dueno, '.' si libre, ' ' si la casilla no es comprable
char_dueno(Casilla, C) :-
    ( item_comprable(Casilla, _, Item, _, _) ->
        ( estado_dueno(Item, Dueno), Dueno \== libre ->
            atom_chars(Dueno, [C | _])
        ;   C = '.'
        )
    ;   C = ' '
    ).

% Caracter de casas: digito 1-4 si hay casas, espacio en otro caso
char_casas(Casilla, C) :-
    ( item_comprable(Casilla, _, Item, _, _), atom(Item),
      obtener_casas(Item, N), N > 0 ->
        Code is 48 + N, char_code(C, Code)   % '0' = 48, '1' = 49, '2' = 50, ...
    ;   C = ' '
    ).

% Caracter de jugador: inicial del jugador si esta en la casilla, espacio si no
char_jugador(Indice, C) :-
    nb_getval(jugadores, Jugadores),
    findall(N, member(jugador(N, Indice, _, _), Jugadores), EnCasilla),
    ( EnCasilla = []      -> C = ' '
    ; EnCasilla = [J | _] -> atom_chars(J, [C | _])
    ).

% Construye la cadena de una celda: exactamente 14 chars
% Formato: [NAME7 DH J]  ->  1+7+1+1+1+1+1+1 = 14
celda(Indice, CeldaStr) :-
    casilla_en(Indice, Casilla),
    nombre_casilla_7(Casilla, Nombre7),
    char_dueno(Casilla, CD),
    char_casas(Casilla, CH),
    char_jugador(Indice, CJ),
    format(atom(CeldaStr), '[~w ~w~w ~w]', [Nombre7, CD, CH, CJ]).

imprimir_fila([]).
imprimir_fila([Indice | Resto]) :-
    celda(Indice, S),
    write(S),
    imprimir_fila(Resto).

% Calcula la anchura total de una fila (11 celdas de 14 chars = 154)
anchura_fila(154).

mostrar_tablero :-
    anchura_fila(W),
    SepW is W + 2,
    writeln(''),
    sep_linea(SepW),
    writeln('           TABLERO DE MONOPOLY'),
    sep_linea(SepW),
    % Fila superior: casillas 30 -> 20 (der a izq)
    numlist(20, 30, FilaTopAsc),
    reverse(FilaTopAsc, FilaTop),
    imprimir_fila(FilaTop), nl,
    sep_linea(SepW),
    % Columnas laterales: izquierda 39..31, derecha 11..19
    mostrar_filas_medio(39, 31, 11, 19),
    sep_linea(SepW),
    % Fila inferior: casillas 0 -> 10
    numlist(0, 10, FilaBot),
    imprimir_fila(FilaBot), nl,
    sep_linea(SepW),
    writeln('  Leyenda: D=dueno  H=casas(1-4)  J=jugador  .=libre  _=sin efecto'),
    nl.

% Imprime una linea separadora de N guiones
sep_linea(N) :-
    length(Lista, N),
    maplist(=('-'), Lista),
    atom_chars(Sep, Lista),
    writeln(Sep).

% Fila del medio: celda izquierda, espacio hasta col ColDer, celda derecha
% Cada celda = 14 chars, 11 celdas = 154 chars, col derecha empieza en 140
mostrar_filas_medio(IndiceIzq, LimIzq, IndiceDer, LimDer) :-
    IndiceIzq >= LimIzq,
    IndiceDer =< LimDer,
    !,
    celda(IndiceIzq, CeldaIzq),
    celda(IndiceDer, CeldaDer),
    format('~w~t~140|~w~n', [CeldaIzq, CeldaDer]),
    IndiceIzqSig is IndiceIzq - 1,
    IndiceDerSig is IndiceDer + 1,
    mostrar_filas_medio(IndiceIzqSig, LimIzq, IndiceDerSig, LimDer).
mostrar_filas_medio(_, _, _, _).

mostrar_estado :-
    writeln(''),
    writeln('============= ESTADO DEL JUEGO ============='),
    nb_getval(jugadores, Jugadores),
    nb_getval(turno_actual, Turno),
    format('Turno actual: ~w~n', [Turno]),
    writeln('--------------------------------------------'),
    maplist(mostrar_jugador_estado, Jugadores),
    writeln('============================================'),
    nl.

mostrar_jugador_estado(jugador(Nombre, Pos, Dinero, Propiedades)) :-
    casilla_en(Pos, Casilla),
    nombre_casilla_7(Casilla, NomCasilla),
    length(Propiedades, NumPropiedades),
    format('~w: $~w | Pos ~w (~w) | ~w propiedades~n',
           [Nombre, Dinero, Pos, NomCasilla, NumPropiedades]).
