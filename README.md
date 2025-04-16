# Simulador de Reservas Concurrentes

Este proyecto implementa un sistema de simulación de reservas concurrentes para un evento, permitiendo estudiar el comportamiento de transacciones y niveles de aislamiento en PostgreSQL.

## Estructura del Proyecto

- `ddl.sql`: Script para la creación de la base de datos, esquemas, tablas y funciones.
- `data.sql`: Script para cargar datos de prueba en la base de datos.
- `simulacion_reservas.py`: Programa principal para ejecutar la simulación de reservas concurrentes.
- `README.md`: Documentación del proyecto e instrucciones de uso.

## Requisitos

- PostgreSQL 12 o superior
- Python 3.7 o superior
- Bibliotecas Python:
  - psycopg2
  - threading
  - tabulate

## Instalación

1. **Configurar la base de datos**:

   ```bash
   # Ejecutar script de creación de estructura
   psql -U postgres -f ddl.sql

   # Conectarse a la base de datos creada
   psql -U reserva_user -d reservaciones

   # Ejecutar script de carga de datos (desde psql)
   \i data.sql
   ```

2. **Instalar dependencias Python**:

   ```bash
   pip install psycopg2-binary tabulate
   ```

## Uso del Simulador

El simulador permite diferentes opciones de ejecución:

### Ejecutar una simulación básica

```bash
python simulacion_reservas.py
```

Esto ejecutará la simulación con 10 usuarios concurrentes y nivel de aislamiento "READ COMMITTED" (valores por defecto).

### Especificar parámetros de la simulación

```bash
python simulacion_reservas.py --users 20 --isolation serializable
```

Donde:

- `--users`: Número de usuarios concurrentes (5, 10, 20, 30, etc.)
- `--isolation`: Nivel de aislamiento a utilizar (read_committed, repeatable_read, serializable)

### Restablecer datos de simulación

```bash
python simulacion_reservas.py --reset
```

Esto restaura los asientos a su estado original, eliminando reservas previas realizadas en simulaciones anteriores.

### Ejecutar todas las pruebas de concurrencia

```bash
python simulacion_reservas.py --run-all
```

Ejecuta automáticamente todas las combinaciones de prueba:

- Usuarios concurrentes: 5, 10, 20, 30
- Niveles de aislamiento: READ COMMITTED, REPEATABLE READ, SERIALIZABLE

Los resultados se guardan en el archivo `resultados_simulacion.csv`.

### Generar un informe de resultados

```bash
python simulacion_reservas.py --report
```

Genera y muestra un informe basado en los registros guardados en la base de datos.

## Experimentos de Concurrencia

El sistema está diseñado para realizar pruebas con diferentes niveles de concurrencia y aislamiento:

1. **Nivel de usuario**: Diferentes cantidades de usuarios intentando reservas simultáneamente (5, 10, 20, 30)
2. **Nivel de aislamiento**: Diferentes niveles de aislamiento de transacciones:
   - `READ COMMITTED`: Lee solo datos confirmados, pero puede tener problemas de lectura no repetible
   - `REPEATABLE READ`: Garantiza que las lecturas sean consistentes durante toda la transacción
   - `SERIALIZABLE`: Ofrece el mayor nivel de aislamiento, evitando anomalías de concurrencia

## Análisis de Resultados

Durante la ejecución, el programa registra:

- Número de reservas exitosas y fallidas
- Tiempo de ejecución de cada operación
- Errores producidos durante las transacciones

Estos datos permiten comparar cómo los diferentes niveles de aislamiento afectan el rendimiento y la consistencia del sistema.

## Solución de Problemas

- **Error de conexión**: Verificar que PostgreSQL esté en ejecución y los parámetros de conexión sean correctos.
- **Errores de simulación**: Use la opción `--reset` para restaurar los datos a un estado consistente.
- **Timeout en transacciones**: Pueden suceder bloqueos excesivos. Modificar los parámetros de timeout de PostgreSQL.
