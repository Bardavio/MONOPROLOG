# Informe Técnico – MONOPROLOG

## 1. Tablero

El tablero se representa como una lista Prolog de 40 elementos, donde cada posición es un término que codifica el tipo de casilla. Se emplean los functores `propiedad/4` (nombre, precio, color, dueño), `casilla/2` (tipo, descripción), `estacion/2` (nombre, dueño) y `servicio/2` (nombre, dueño). El campo dueño puede ser `libre` o el término `jugador(...)` una vez adquirida. Esta representación declarativa permite unificar directamente el tipo de una casilla sin necesidad de tablas auxiliares. El predicado `tablero/1` es un hecho que instancia la lista completa, y `casilla_en/2` delega en `nth0/3` para el acceso por índice 0-based.

**Predicados:** `tablero/1`, `casilla_en/2`.

## 2. Estado

El estado global de la partida se gestiona con dos variables globales: `nb_setval(jugadores, Lista)` y `nb_setval(turno_actual, N)`. Cada jugador es el término `jugador(Nombre, Posicion, Dinero, Propiedades)`. El jugador activo se obtiene calculando `Turno mod 2`, garantizando rotación circular. La mutación de campos individuales de un jugador se realiza directamente con `nb_setarg/3`, evitando reconstruir la lista entera (coste O(1)). El predicado `iniciar_juego/0` inicializa ambas variables con dos jugadores en posición 0 y 1500 unidades cada uno.

**Predicados:** `iniciar_juego/0`.

## 3. Movimiento

La simulación del dado se realiza mediante dos listas predefinidas de veinte valores en `secuencia_dado1/1` y `secuencia_dado2/1`; `valor_dado1/2` y `valor_dado2/2` seleccionan el elemento de índice `Turno mod 20`, garantizando ciclo infinito sin efectos laterales. `valor_dados/2` suma ambos dados. La nueva posición se calcula con `(Pos + Tirada) mod 40` en `nueva_posicion/3`. El predicado `pasa_por_salida/2` detecta el cruce de salida cuando `Pos + Tirada >= 40` y `mover_jugador/2` lo usa en una condicional `(->; )` para sumar 200 al jugador. La actualización se realiza con `nb_setarg` sobre el término jugador vivo en la lista global.

**Predicados:** `secuencia_dado1/1`, `secuencia_dado2/1`, `valor_dado1/2`, `valor_dado2/2`, `valor_dados/2`, `nueva_posicion/3`, `pasa_por_salida/2`, `mover_jugador/2`.

## 4. Control de turno

`ejecutar_turno/2` implementa un turno completo: obtiene el jugador activo, lo mueve, aplica la casilla y muestra el log. `jugar_turno/0` orquesta la rotación: incrementa el contador global, detecta dado doble y en ese caso llama a `ejecutar_turno` de nuevo con el mismo índice de jugador (turno extra). `jugar_turnos/1` itera recursivamente N veces.

**Predicados:** `ejecutar_turno/2`, `jugar_turno/0`, `jugar_turnos/1`.

## 5. Compra de propiedades

`aplicar_casilla/2` detecta propiedades libres mediante `propiedad_libre/1`, que consulta la lista global de jugadores y verifica que ninguno tiene el nombre en su lista de propiedades. Si el jugador tiene fondos suficientes, se descuenta el precio con `nb_setarg(3, ...)` y se añade la propiedad a su lista con `nb_setarg(4, ...)`. Las estaciones y servicios siguen el mismo patrón usando `\+ dueno_estacion/2` y `\+ dueno_servicio/2` respectivamente, con precios fijos `precio_estacion(200)` y `precio_servicio(150)`.

**Predicados:** `propiedad_libre/1`, `aplicar_casilla(propiedad(...), ...)`, `aplicar_casilla(estacion(...), ...)`, `aplicar_casilla(servicio(...), ...)`.

## 6. Pago de alquiler

Si la casilla es una propiedad (o estación/servicio) con dueño distinto al jugador actual, `aplicar_casilla/2` cobra el alquiler correspondiente. El alquiler de propiedades se obtiene por color con `alquiler_color/2` (valores estándar de Monopoly). La transferencia se realiza mutando simultáneamente el dinero de ambos jugadores con `nb_setarg(3, ...)`. Las cláusulas usan corte `!` para garantizar que solo se aplica la primera rama que unifica.

**Predicados:** `dueno_de/2`, `dueno_estacion/2`, `dueno_servicio/2`, `alquiler_color/2`.

## 7. Dado doble y turno extra

`es_doble/1` es cierto cuando ambas secuencias de dados producen el mismo valor para el turno dado. En `jugar_turno/0`, tras ejecutar el turno normal, se comprueba `es_doble(Turno)`: si se cumple, se imprime `[Doble]` y se llama a `ejecutar_turno` una segunda vez con el mismo jugador, encadenando automáticamente el movimiento extra con la aplicación de compra o alquiler según la casilla destino.

Para localizar turnos con doble: `?- es_doble(T), T < 40.`

**Predicados:** `es_doble/1`.

## 8. Consultas globales

Predicados de consulta sobre el estado global para inspeccionar propiedades por dueño.

- `props_de_jugador/2` — propiedades en la lista interna del jugador
- `propiedades_de_dueno/2` — busca en el tablero por el campo dueño
- `estaciones_de_dueno/2` — estaciones por dueño en el tablero
- `servicios_de_dueno/2` — servicios por dueño en el tablero

**Predicados:** `props_de_jugador/2`, `propiedades_de_dueno/2`, `estaciones_de_dueno/2`, `servicios_de_dueno/2`.
