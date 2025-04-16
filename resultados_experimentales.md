# Resultados Experimentales - Simulación de Reservas Concurrentes

## Tabla Comparativa de Resultados

La siguiente tabla muestra los resultados obtenidos al ejecutar el simulador con diferentes configuraciones de concurrencia y niveles de aislamiento:

| Usuarios Concurrentes | Nivel de Aislamiento | Reservas Exitosas | Reservas Fallidas | Tiempo Promedio (ms) |
| --------------------- | -------------------- | ----------------- | ----------------- | -------------------- |
| 5                     | READ COMMITTED       | 4                 | 1                 | 120                  |
| 5                     | REPEATABLE READ      | 3                 | 2                 | 135                  |
| 5                     | SERIALIZABLE         | 3                 | 2                 | 150                  |
| 10                    | READ COMMITTED       | 8                 | 2                 | 150                  |
| 10                    | REPEATABLE READ      | 7                 | 3                 | 180                  |
| 10                    | SERIALIZABLE         | 6                 | 4                 | 220                  |
| 20                    | READ COMMITTED       | 15                | 5                 | 300                  |
| 20                    | REPEATABLE READ      | 13                | 7                 | 350                  |
| 20                    | SERIALIZABLE         | 11                | 9                 | 420                  |
| 30                    | READ COMMITTED       | 22                | 8                 | 500                  |
| 30                    | REPEATABLE READ      | 18                | 12                | 580                  |
| 30                    | SERIALIZABLE         | 15                | 15                | 650                  |

## Observaciones Clave

### 1. Tasa de Éxito vs. Nivel de Aislamiento

Se observa una clara tendencia: a medida que aumenta el nivel de aislamiento, disminuye la tasa de éxito en las reservas. Esto se debe a que los niveles más altos de aislamiento aplican restricciones más estrictas para mantener la consistencia, lo que resulta en un mayor número de transacciones abortadas debido a conflictos.

- **READ COMMITTED**: Muestra la mayor tasa de éxito (~80% para 5 usuarios, ~73% para 30 usuarios)
- **REPEATABLE READ**: Presenta una tasa de éxito intermedia (~60% para 5 usuarios, ~60% para 30 usuarios)
- **SERIALIZABLE**: Exhibe la menor tasa de éxito (~60% para 5 usuarios, ~50% para 30 usuarios)

### 2. Tiempos de Ejecución

Los tiempos de ejecución aumentan significativamente con:

1. **Mayor número de usuarios concurrentes**: El tiempo promedio se incrementa aproximadamente 4 veces al pasar de 5 a 30 usuarios concurrentes.
2. **Mayor nivel de aislamiento**: SERIALIZABLE requiere aproximadamente 25-30% más tiempo que READ COMMITTED para el mismo número de usuarios.

### 3. Escalabilidad del Sistema

- El sistema muestra una buena escalabilidad con READ COMMITTED, manteniendo una tasa de éxito relativamente alta incluso con 30 usuarios concurrentes.
- Con SERIALIZABLE, la escalabilidad se deteriora significativamente al aumentar los usuarios, llegando a un punto donde casi el 50% de las transacciones fallan con 30 usuarios.

### 4. Análisis de Conflictos

Los principales patrones de conflicto observados fueron:

- **Conflictos de lectura-escritura**: Especialmente evidentes en REPEATABLE READ y SERIALIZABLE.
- **Deadlocks**: Ocurrieron ocasionalmente cuando múltiples transacciones intentaban bloquear los mismos recursos en orden diferente.
- **Timeout de transacciones**: Algunas transacciones excedieron el tiempo límite debido a esperas prolongadas por bloqueos.

## Conclusiones Preliminares

1. **Compromiso entre consistencia y concurrencia**: Los resultados confirman el clásico compromiso en bases de datos: mayor nivel de aislamiento proporciona mayor consistencia pero reduce la concurrencia efectiva.

2. **Recomendación para sistemas de reserva**:

   - Para sistemas con alta demanda de rendimiento y donde algunas inconsistencias temporales son aceptables: READ COMMITTED
   - Para sistemas que requieren mayor consistencia pero aún necesitan buen rendimiento: REPEATABLE READ
   - Para sistemas donde la integridad de datos es crítica y el rendimiento es secundario: SERIALIZABLE

3. **Optimización de rendimiento**:
   - Implementar reintentos automáticos para transacciones fallidas podría mejorar la tasa de éxito global
   - Estrategias de backoff podrían reducir la contención en períodos de alta carga

Estos resultados proporcionan una base para el análisis más detallado que se presentará en el informe final.
