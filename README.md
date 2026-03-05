# MONOPROLOG

- Sergio Bardavio
- Ángel Jimenez
- Karim Ahmed
- Diego Martínez

## Entregas

#### Tablero

- [x] Tablero como lista de 40 casillas
- [x] Casillas representadas como terminos `propiedad(Nombre, Precio, Color, Dueno)`, `casilla(Tipo, Desc)`, `estacion(Nombre, Dueno)`, `servicio(Nombre, Dueno)`
- [x] Se debe poder accederse a una casilla por índice (`casilla_en/2`)

#### Estado

- [x] Estado global con `nb_setval(jugadores, ...)` + `nb_setval(turno_actual, ...)`
- [x] `jugador(Nombre, Posicion, Dinero, Propiedades)`
- [x] Lista de jugadores correctamente estructurada.

#### Movimiento

- [x] Dado simulado con lista predefinida.
- [x] Nueva posición con módulo 40.
- [x] Si pasa por salida, suma dinero.
- [x] Actualización del jugador con `nb_setarg/3` (mutación O(1)).

#### Control de turno

- [x] Cambio de turno circular
- [x] `jugar_turno/0`, `ejecutar_turno/2`, `jugar_turnos/1`

#### Reglas del Juego

- [x] Regla 0 – Compra
  - [x] Detectar propiedad sin dueño (`propiedad_libre/1`)
  - [x] Verificar dinero suficiente
  - [x] Restar dinero al jugador
  - [x] Añadir propiedad a la lista del jugador
- [x] Regla 1 – Alquiler
  - [x] Detectar propiedad con dueño (`dueno_de/2`, `dueno_estacion/2`, `dueno_servicio/2`)
  - [x] Transferir dinero al propietario
  - [x] Actualizar ambos jugadores con `nb_setarg`
- [ ] Regla 2 – Monopolio
  - [ ] Detectar si un jugador posee todas las propiedades de un color
  - [ ] Predicado de verificación de subconjunto
- [ ] Regla 3 – Bancarrota
  - [ ] Detectar dinero negativo
  - [ ] Eliminar jugador o liquidar propiedades

#### Aplicación de reglas

- [x] Predicado `aplicar_casilla/2`
- [x] Aplicación encadenada de reglas en orden (cortes + fallthrough)
- [x] Turno completo con efectos económicos

#### Mejoras implementadas

- [x] Estado global mutable con `nb_setval`/`nb_getval` (Sergio)
- [x] Mutación O(1) con `nb_setarg` (Sergio)
- [x] Dado doble con secuencias predefinidas (Ángel)
- [x] Propiedades/estaciones/servicios con dueño (Diego)
- [x] Reglas no independientes: dado doble activa turno extra

#### Simulación automática

- [ ] Predicado `simular(N, EstadoInicial, EstadoFinal)`
- [ ] Iteración recursiva de turnos
- [ ] Finalización por N turnos o un único jugador restante

#### Métricas

- [ ] Contador de turnos
- [ ] Contador de compras
- [ ] Contador de alquileres
- [ ] Contador de bancarrotas
- [ ] Archivo `metricas.pl`

#### Mejoras (mínimo 2)

- [ ] Patrimonio total por jugador
- [ ] Ranking dinámico
- [ ] Otra mejora adicional documentada

#### Escenarios de prueba

- [ ] Escenario 1 – Compras iniciales
- [ ] Escenario 2 – Monopolio formado
- [ ] Escenario 3 – Jugador próximo a bancarrota
- [ ] Escenario 4 – Múltiples alquileres consecutivos
- [ ] Escenario 5 – Simulación completa de 10 turnos
