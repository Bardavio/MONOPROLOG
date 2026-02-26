# MONOPROLOG

- Sergio Bardavio
- Ángel Jimenez
- Karim Ahmed
- Diego Martínez

## Entregas

### Semanas 1 y 2

#### Tablero

- [x] Tablero como lista de 40 casillas
- [x] Casillas representadas como terminos `propiedad(Nombre, Precio, Color)`, `impuesto(Cantidad)`...
- [x] Se debe poder accederse a una casilla por índice.

#### Estado

- [x] `estado(Jugadores, Tablero, Turno)`
- [x] `jugador(Nombre, Posicion, Dinero, Propiedades)`
- [x] Lista de jugadores correctamente estructurada.

#### Movimiento

- [x] Dado simulado con lista predefinida.
- [x] Nueva posición con módulo 40.
- [x] Si pasa por salida, suma dinero.
- [x] Actualización correcta del jugador dentro de la lista.

#### Control de turno

- [x] Cambio de turno circular
- [x] Predicado tipo `jugarTurno/2`

### Semanas 3 y 4

#### Reglas del Juego

- [ ] Regla 0 – Compra
- [ ] Detectar propiedad sin dueño
- [ ] Verificar dinero suficiente
- [ ] Restar dinero al jugador
- [ ] Añadir propiedad a la lista del jugador
- [ ] Regla 1 – Alquiler
- [ ] Detectar propiedad con dueño
- [ ] Transferir dinero al propietario
- [ ] Actualizar ambos jugadores en la lista
- [ ] Regla 2 – Monopolio
- [ ] Detectar si un jugador posee todas las propiedades de un color
- [ ] Predicado de verificación de subconjunto
- [ ] Regla 3 – Bancarrota
- [ ] Detectar dinero negativo
- [ ] Eliminar jugador o liquidar propiedades

#### Aplicación de reglas

- [ ] Predicado `aplicarReglas/2`
- [ ] Aplicación encadenada de reglas en orden
- [ ] Turno completo con efectos económicos

### Semanas 5 y 6

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
