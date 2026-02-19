# Informe Técnico – MONOPROLOG

## Semanas 1 y 2

### 1. Tablero

El tablero se representa como una lista Prolog de 40 elementos, donde cada posición es un término que codifica el tipo de casilla. Se emplean los functores `propiedad/3`, `impuesto/1`, `estacion/1`, `servicio/1`, `carta`, `chance`, `carcel`, `parking` e `ir_a_carcel`. Esta representación declarativa permite unificar directamente el tipo de una casilla sin necesidad de tablas auxiliares. El predicado `tablero/1` es un hecho que instancia la lista completa, y `casilla/2` delega en `nth0/3` para el acceso por índice 0-based. La elección de una lista única frente a hechos indexados facilita pasar el tablero como argumento del estado.

**Predicados:** `tablero/1`, `casilla/2`.

### 2. Estado

El estado global de la partida se encapsula en el término `estado(Jugadores, Tablero, Turno)`, donde `Jugadores` es una lista de términos `jugador(Nombre, Posicion, Dinero, Propiedades)`. El campo `Turno` es un contador absoluto de turnos jugados desde el inicio (entero no negativo); el jugador activo se obtiene calculando `Turno mod NumJugadores`, lo que garantiza rotación circular sin listas auxiliares. El predicado `estado_inicial/1` construye un estado con dos jugadores en la posición 0, con 1500 unidades monetarias cada uno y el turno a 0. Almacenar el tablero dentro del estado permite que predicados de reglas futuras accedan a él mediante unificación directa.

**Predicados:** `estado_inicial/1`.

### 3. Movimiento

La simulación del dado se realiza mediante una lista predefinida de veinte valores en `secuencia_dado/1`; el predicado `valor_dado/2` selecciona el elemento de índice `N mod 20`, garantizando ciclo infinito sin efectos laterales. La nueva posición se calcula con `(Pos + Tirada) mod 40` en `nueva_posicion/3`, asegurando que el tablero sea circular. El predicado `pasa_por_salida/2` detecta el cruce de la casilla 0 cuando `Pos + Tirada >= 40` y `mover_jugador/3` lo usa en una condicional `(->; )` para sumar 200 al jugador. La actualización de la lista de jugadores se delega a `actualizar_jugador/3`, que recorre la lista y reemplaza al jugador por nombre mediante corte.

**Predicados:** `secuencia_dado/1`, `valor_dado/2`, `nueva_posicion/3`, `pasa_por_salida/2`, `mover_jugador/3`, `actualizar_jugador/3`.

### 4. Control de turno

El predicado `jugador_actual/3` localiza el jugador activo a partir del índice `Turno mod N` usando `nth0/3`. El predicado `jugarTurno/2` implementa la transición de estado completa: obtiene el jugador activo, recupera el valor del dado para ese turno, mueve al jugador y reconstruye el estado con la lista actualizada y el turno incrementado. La interfaz `jugarTurno(EstadoEntrada, EstadoSalida)` sigue el patrón de acumulador estándar en Prolog, lo que facilita la composición iterativa necesaria en la simulación de semanas posteriores.

**Predicados:** `jugador_actual/3`, `siguiente_turno/2`, `jugarTurno/2`.
