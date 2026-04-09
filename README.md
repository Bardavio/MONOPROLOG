# MONOPROLOG

- Sergio Bardavio
- Ángel Jimenez
- Karim Ahmed
- Diego Martínez

# Comandos útiles

Arranca siempre con:

```
swipl tests.pl
```

Esto carga tests.pl que a su vez carga main.pl → reglas.pl y metricas.pl.

## Inicialización

```prolog
% Iniciar partida (6 jugadores con $1500 en posición 0)
iniciar_juego.

% Ver estado completo de todos los jugadores
mostrar_estado.

% Ver el tablero visual ASCII
mostrar_tablero.

% Ver ranking por patrimonio
ranking.
```

## Tablero

```prolog
% Ver qué hay en una casilla concreta
casilla_en(0, X).    % Salida
casilla_en(1, X).    % marron1
casilla_en(30, X).   % Ir a la cárcel
casilla_en(39, X).   % azul2 (la más cara)

% Cuántas casillas tiene el tablero
longitud_tablero(N).

% Buscar el precio de una propiedad
tablero(T), member(propiedad(azul2, Precio, Color, _), T).

% Ver el alquiler base de un color
alquiler_color(marron, X).
alquiler_color(azul, X).
```

## Dados y movimiento

```prolog
% Ver qué valor dan los dados en el turno N
valor_dados(0, T).   % turno 0
valor_dados(1, T).   % turno 1

% Ver cada dado por separado
valor_dado1(0, V).
valor_dado2(0, V).

% ¿Hubo doble en el turno N?
es_doble(0).

% ¿Dónde cae alguien que está en pos 35 y saca 8?
nueva_posicion(35, 8, P).

% ¿Ese movimiento pasa por salida?
pasa_por_salida(35, 8).
pasa_por_salida(10, 5).
```

## Jugadores y propiedades

```prolog
% Ver todos los jugadores en bruto
nb_getval(jugadores, J), write(J).

% Ver propiedades de un jugador
props_de_jugador(alice, P).
props_de_jugador(bob, P).

% Ver dinero de un jugador
nb_getval(jugadores, J), member(jugador(alice, _, Dinero, _), J).

% Ver posición de un jugador
nb_getval(jugadores, J), member(jugador(alice, Pos, _, _), J).

% ¿Quién es el dueño de una propiedad?
estado_dueno(marron1, Dueno).
estado_dueno(azul2, Dueno).

% ¿Una propiedad está libre?
propiedad_libre(marron1).

% Ver el patrimonio total de un jugador (dinero + propiedades + casas)
patrimonio_total(alice, Total).
```

## Jugar turnos

```prolog
% Jugar un turno
jugar_turno.

% Jugar N turnos seguidos
jugar_turnos(5).
jugar_turnos(10).

% Ver en qué turno estamos
nb_getval(turno_actual, T).
```

## Herramientas de test (manipulación directa)

```prolog
% Mover a alice con una tirada exacta (sin dados predefinidos)
iniciar_juego, test_tirada(alice, 6).

% Teletransportar a bob directamente a una casilla
iniciar_juego, test_caer_en(bob, 39).   % azul2
iniciar_juego, test_caer_en(alice, 30). % ir a la cárcel
iniciar_juego, test_caer_en(alice, 4).  % impuesto $200

% Ajustar el dinero de un jugador directamente
iniciar_juego, test_dinero(alice, 50).
iniciar_juego, test_dinero(alice, -10). % forzar bancarrota

% Dar una propiedad a un jugador sin compra
iniciar_juego, test_dar_propiedad(alice, marron1).
iniciar_juego, test_dar_propiedad(bob, azul2).

% Forzar bancarrota sin recuperación (alice tiene $10, cae en azul2 ajena)
iniciar_juego, test_bancarrota(alice).

% Forzar bancarrota con recuperación (tiene propiedades para liquidar)
iniciar_juego, test_bancarrota2(alice).

% Simular turno con dobles
iniciar_juego, test_turno_doble(alice, 3, 7).
```

## Reglas

```prolog
% --- Regla 0: Compra ---
% Hacer que alice compre marron1 manualmente
iniciar_juego,
nb_getval(jugadores, J), member(Jug, J), Jug = jugador(alice,_,_,_),
regla_0_compra(Jug, marron1, marron1, 60).

% --- Regla 1: Alquiler ---
% Ver cuánto costaría el alquiler de marron1 con monopolio y 2 casas
alquiler_color(marron, Base),
alquiler_efectivo(marron1, Base, alice, Final).

% --- Regla 2: Monopolio ---
% Ver qué propiedades forman un grupo
grupo_color(marron, G).
grupo_color(azul, G).

% Comprobar si alice tiene monopolio de un color
iniciar_juego,
test_dar_propiedad(alice, marron1),
test_dar_propiedad(alice, marron2),
tiene_monopolio(alice, marron).

% Forzar comprobación de monopolios de alice
iniciar_juego,
test_dar_propiedad(alice, marron1),
test_dar_propiedad(alice, marron2),
comprobar_monopolios_jugador(alice).

% --- Regla 3: Bancarrota ---
% Ver cuánto recuperaría un jugador liquidando sus propiedades
calcular_valor_liquidacion([marron1, marron2], V).
calcular_valor_liquidacion([azul1, azul2], V).
```

## Casas

```prolog
% Ver cuántas casas hay en una propiedad
iniciar_juego, obtener_casas(marron1, N).

% Construir una casa manualmente (necesita monopolio y fondos)
iniciar_juego,
test_dar_propiedad(alice, marron1),
test_dar_propiedad(alice, marron2),
construir_casa(alice, marron1).

% Ver coste de construir una casa por color
coste_casa(marron, C).
coste_casa(azul, C).
```

## Hipotecas

```prolog
% Hipotecar una propiedad (alice debe ser dueña y no tener casas)
iniciar_juego,
test_dar_propiedad(alice, marron1),
hipotecar(alice, marron1).

% Levantar hipoteca
iniciar_juego,
test_dar_propiedad(alice, marron1),
hipotecar(alice, marron1),
levantar_hipoteca(alice, marron1).

% Ver qué propiedades están hipotecadas
nb_getval(hipotecas, H).

% Comprobar si una propiedad está hipotecada
esta_hipotecada(marron1).
```

## Métricas

```prolog
% Ver ranking completo
ranking.

% Ver patrimonio de un jugador
patrimonio_total(alice, T).
patrimonio_total(bob, T).

% Ver historial de riqueza (últimos turnos)
nb_getval(historial_riqueza, H).

% Forzar detección de estancamiento
detectar_estancamiento.
```

## Escenarios completos

```prolog
% Escenario 1: Dos jugadores hacen compras iniciales
escenario_1.

% Escenario 2: Un jugador forma monopolio y construye casas
escenario_2.

% Escenario 3: Jugador al borde de la bancarrota pero se recupera liquidando
escenario_3.

% Escenario 4: Múltiples alquileres consecutivos
escenario_4.

% Escenario 5: Simulación completa de 10 turnos con métricas
escenario_5.

% Escenario extra: Monopolio + casas + alquiler escalado
escenario_casas.

% Escenario 6: Alquiler doble por monopolio sin casas
escenario_alquiler_monopolio.

% Escenario 7: Eliminación completa de jugador insolvente
escenario_eliminacion.

% Escenario 8: Detección de estancamiento
escenario_estancamiento.

% Escenario 9: Dos monopolios enfrentados
escenario_monopolios_cruzados.

% Escenario 10: Hipotecas completo
escenario_hipotecas.
```
