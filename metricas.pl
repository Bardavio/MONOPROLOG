% METRICAS (metricas.pl)
% Ranking dinamico | Deteccion de estancamiento | Patrimonio total

% --- Inicializacion ---
inicializar_metricas :-
    nb_setval(historial_riqueza, []),
    nb_setval(turno_metrics, 0).

% --- Patrimonio total por jugador ---

patrimonio_total(Nombre, Total) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Nombre, _, Dinero, Props), Jugadores),
    valor_propiedades(Props, ValorProps),
    valor_casas_jugador(Props, ValorCasas),
    Total is Dinero + ValorProps + ValorCasas.

% Suma el valor de cada propiedad (negativo si hipotecada: se debe el valor al banco)
valor_propiedades([], 0).
valor_propiedades([P|Rest], Total) :-
    precio_propiedad(P, Precio),
    ( esta_hipotecada(P) -> ValP is -(Precio // 2) ; ValP = Precio ),
    valor_propiedades(Rest, RestVal),
    Total is ValP + RestVal.

% Suma el valor de las casas construidas en las propiedades del jugador
valor_casas_jugador([], 0).
valor_casas_jugador([P|Rest], Total) :-
    ( atom(P), obtener_casas(P, NC), NC > 0,
      tablero(T), member(propiedad(P, _, Color, _), T),
      coste_casa(Color, CosteCasa)
    -> ValCasas is NC * CosteCasa
    ;  ValCasas = 0
    ),
    valor_casas_jugador(Rest, RestVal),
    Total is ValCasas + RestVal.

% --- Ranking dinamico ---

ranking :-
    mostrar_ranking.

mostrar_ranking :-
    writeln(''),
    writeln('============= RANKING DE JUGADORES ============='),
    nb_getval(jugadores, Jugadores),
    findall(Total-Nombre,
            (member(jugador(Nombre, _, _, _), Jugadores),
             patrimonio_total(Nombre, Total)),
            Pares),
    msort(Pares, Ordenados),
    reverse(Ordenados, OrdenadosDesc),
    imprimir_ranking(OrdenadosDesc, 1),
    writeln('================================================'),
    nl.

imprimir_ranking([], _).
imprimir_ranking([Total-Nombre|Rest], Pos) :-
    nb_getval(jugadores, Jugadores),
    member(jugador(Nombre, _, Dinero, Props), Jugadores),
    length(Props, NumProps),
    format('  #~w ~w: $~w patrimonio (dinero: $~w, propiedades: ~w)~n',
           [Pos, Nombre, Total, Dinero, NumProps]),
    Pos1 is Pos + 1,
    imprimir_ranking(Rest, Pos1).

% --- Deteccion de estancamiento ---

% Registra el estado de riqueza de todos los jugadores en el historial
registrar_estado_turno :-
    nb_getval(jugadores, Jugadores),
    findall(Nombre-Total,
            (member(jugador(Nombre, _, _, _), Jugadores),
             patrimonio_total(Nombre, Total)),
            Estado),
    nb_getval(historial_riqueza, Hist),
    NuevoHist = [Estado | Hist],
    length(NuevoHist, Len),
    ( Len > 10
    -> length(HistFinal, 10), append(HistFinal, _, NuevoHist)
    ;  HistFinal = NuevoHist
    ),
    nb_setval(historial_riqueza, HistFinal).

% Detecta estancamiento: si en los ultimos 5 turnos el cambio maximo
% de patrimonio por jugador es < 50
detectar_estancamiento :-
    nb_getval(historial_riqueza, Hist),
    length(Hist, L),
    L >= 5,
    !,
    % Tomar los ultimos 5 estados
    length(Ultimos5, 5),
    append(Ultimos5, _, Hist),
    % Comparar el mas reciente con el mas antiguo de los 5
    Ultimos5 = [Reciente | _],
    last(Ultimos5, Antiguo),
    ( estancado(Reciente, Antiguo) ->
        format('[Metrica - Estancamiento] ATENCION: El juego lleva 5 turnos sin cambios significativos de patrimonio.~n')
    ;   true
    ).
detectar_estancamiento. % No hay suficiente historial aun

% Comprueba si la diferencia de patrimonio entre dos estados es < 50 para todos los jugadores
estancado(Estado1, Estado2) :-
    % Para cada jugador en Estado1, buscar su valor en Estado2 y comparar
    \+ (
        member(Nombre-V1, Estado1),
        member(Nombre-V2, Estado2),
        Delta is abs(V1 - V2),
        Delta >= 50
    ).
