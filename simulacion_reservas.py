"""
Simulación de reservas concurrentes para el proyecto de Bases de Datos.
Este script simula múltiples usuarios intentando reservar asientos simultáneamente
con diferentes niveles de aislamiento en PostgreSQL.
"""

import psycopg2
import threading
import time
import random
import argparse
import csv
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from tabulate import tabulate

# Configuración de la conexión a la base de datos
DB_CONFIG = {
    'dbname': 'reservaciones',
    'user': 'reserva_user',
    'password': 'reserva_password',
    'host': 'localhost',
    'port': '5432'
}

# Niveles de aislamiento disponibles
ISOLATION_LEVELS = {
    'read_committed': 'READ COMMITTED',
    'repeatable_read': 'REPEATABLE READ',
    'serializable': 'SERIALIZABLE'
}

# Configuración global
DEFAULT_NUM_USERS = 10
DEFAULT_ISOLATION_LEVEL = 'read_committed'
RESULTS_FILE = 'resultados_simulacion.csv'

class ReservationSimulator:
    """Clase para simular reservas concurrentes en la base de datos."""
    
    def __init__(self, num_users, isolation_level, target_section=1, event_id=1):
        """Inicializa el simulador con la configuración especificada.
        
        Args:
            num_users: Número de usuarios concurrentes para la simulación.
            isolation_level: Nivel de aislamiento de transacciones a utilizar.
            target_section: ID de la sección objetivo para las reservas.
            event_id: ID del evento objetivo.
        """
        self.num_users = num_users
        self.isolation_level = isolation_level
        self.target_section = target_section
        self.event_id = event_id
        self.results = {
            'successful_reservations': 0,
            'failed_reservations': 0,
            'execution_times': []
        }
        self.lock = threading.Lock()
        
    def _get_connection(self):
        """Establece una conexión a la base de datos."""
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = False
        return conn
    
    def _get_available_seat(self, conn):
        """Obtiene un asiento disponible de la sección objetivo.
        
        Args:
            conn: Conexión activa a la base de datos.
            
        Returns:
            Tuple con (asiento_id, fila, numero) o None si no hay asientos disponibles.
        """
        cursor = conn.cursor()
        cursor.execute("""
            SELECT asiento_id, fila, numero 
            FROM eventos.asiento 
            WHERE seccion_id = %s AND estado = 'DISPONIBLE'
            LIMIT 1
        """, (self.target_section,))
        
        result = cursor.fetchone()
        cursor.close()
        return result
    
    def _attempt_reservation(self, user_id):
        """Intenta realizar una reserva para un usuario específico.
        
        Args:
            user_id: ID del usuario que intenta hacer la reserva.
            
        Returns:
            Tuple con (resultado, tiempo_ejecucion, mensaje_error)
        """
        conn = None
        start_time = time.time()
        result = 'FALLIDO'
        error_message = ''
        seat_id = None
        
        try:
            conn = self._get_connection()
            
            # Establecer el nivel de aislamiento
            if self.isolation_level == ISOLATION_LEVELS['read_committed']:
                conn.set_session(isolation_level='READ COMMITTED')
            elif self.isolation_level == ISOLATION_LEVELS['repeatable_read']:
                conn.set_session(isolation_level='REPEATABLE READ')
            elif self.isolation_level == ISOLATION_LEVELS['serializable']:
                conn.set_session(isolation_level='SERIALIZABLE')
            
            cursor = conn.cursor()
            
            # Iniciar transacción
            cursor.execute("BEGIN")
            
            # Obtener un asiento disponible
            seat_info = self._get_available_seat(conn)
            if not seat_info:
                raise Exception("No hay asientos disponibles en la sección seleccionada.")
            
            seat_id, row, number = seat_info
            
            # Simular algo de procesamiento/latencia
            time.sleep(random.uniform(0.05, 0.2))
            
            # Intentar realizar la reserva usando la función de la base de datos
            cursor.execute("SELECT eventos.realizar_reserva(%s, %s)", (user_id, seat_id))
            
            # Recuperar el ID de la reserva creada/actualizada
            reservation_id = cursor.fetchone()[0]
            
            # Confirmar la transacción
            conn.commit()
            
            result = 'EXITOSO'
            print(f"Usuario {user_id} reservó asiento {row}{number} (ID: {seat_id}) exitosamente.")
            
        except Exception as e:
            if conn:
                conn.rollback()
            error_message = str(e)
            print(f"Error para usuario {user_id}: {error_message}")
            
        finally:
            if conn:
                conn.close()
        
        # Calcular tiempo de ejecución en milisegundos
        execution_time = int((time.time() - start_time) * 1000)
        
        # Registrar el intento en la base de datos
        self._log_attempt(user_id, seat_id, result, execution_time, error_message)
        
        return (result, execution_time, error_message)
    
    def _log_attempt(self, user_id, seat_id, result, execution_time, error_message):
        """Registra el intento de reserva en la base de datos para análisis posterior.
        
        Args:
            user_id: ID del usuario que intentó la reserva.
            seat_id: ID del asiento que se intentó reservar (puede ser None).
            result: Resultado de la operación ('EXITOSO' o 'FALLIDO').
            execution_time: Tiempo de ejecución en milisegundos.
            error_message: Mensaje de error, si lo hubo.
        """
        try:
            conn = self._get_connection()
            conn.autocommit = True
            cursor = conn.cursor()
            
            cursor.execute("""
                INSERT INTO eventos.log_intentos_reserva
                (usuario_id, asiento_id, resultado, nivel_aislamiento, tiempo_ejecucion, mensaje_error)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, (user_id, seat_id, result, self.isolation_level, execution_time, error_message))
            
            cursor.close()
            conn.close()
        except Exception as e:
            print(f"Error al registrar el intento: {str(e)}")
    
    def _reservation_worker(self, user_id):
        """Función de trabajo para cada hilo que intenta realizar una reserva.
        
        Args:
            user_id: ID del usuario que intenta hacer la reserva.
        """
        result, execution_time, _ = self._attempt_reservation(user_id)
        
        with self.lock:
            if result == 'EXITOSO':
                self.results['successful_reservations'] += 1
            else:
                self.results['failed_reservations'] += 1
            self.results['execution_times'].append(execution_time)
    
    def run_simulation(self):
        """Ejecuta la simulación con múltiples hilos."""
        print(f"\nIniciando simulación con {self.num_users} usuarios concurrentes")
        print(f"Nivel de aislamiento: {self.isolation_level}")
        
        threads = []
        start_time = time.time()
        
        # Crear un grupo de hilos para simular usuarios concurrentes
        with ThreadPoolExecutor(max_workers=self.num_users) as executor:
            # Seleccionar usuarios aleatorios de los disponibles (4-40)
            random_user_ids = random.sample(range(4, 41), self.num_users)
            
            # Ejecutar tareas de reserva
            for user_id in random_user_ids:
                executor.submit(self._reservation_worker, user_id)
        
        total_time = time.time() - start_time
        
        # Calcular tiempo promedio de ejecución
        avg_execution_time = sum(self.results['execution_times']) / len(self.results['execution_times']) if self.results['execution_times'] else 0
        
        # Mostrar resultados
        print("\nResultados de la simulación:")
        print(f"Reservas exitosas: {self.results['successful_reservations']}")
        print(f"Reservas fallidas: {self.results['failed_reservations']}")
        print(f"Tiempo promedio de ejecución: {avg_execution_time:.2f} ms")
        print(f"Tiempo total: {total_time:.2f} segundos")
        
        return {
            'num_users': self.num_users,
            'isolation_level': self.isolation_level,
            'successful': self.results['successful_reservations'],
            'failed': self.results['failed_reservations'],
            'avg_time': avg_execution_time,
            'total_time': total_time
        }

def reset_simulation_data():
    """Restablece los datos de simulación, marcando todos los asientos como disponibles excepto los ya reservados inicialmente."""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        conn.autocommit = True
        cursor = conn.cursor()
        
        # Eliminar registros de intentos anteriores
        cursor.execute("TRUNCATE eventos.log_intentos_reserva")
        
        # Restablecer los asientos a su estado original según data.sql
        # (mantener solo las reservas iniciales A1-A2, F1-F2, K1-K2)
        cursor.execute("""
            UPDATE eventos.asiento
            SET estado = 'DISPONIBLE'
            WHERE NOT (
                (seccion_id = 1 AND fila = 'A' AND numero IN ('1', '2')) OR
                (seccion_id = 2 AND fila = 'F' AND numero IN ('1', '2')) OR
                (seccion_id = 3 AND fila = 'K' AND numero IN ('1', '2'))
            ) AND estado = 'RESERVADO'
        """)
        
        # Eliminar las reservas y detalles que no son las iniciales (1, 2, 3)
        cursor.execute("""
            DELETE FROM eventos.reserva_detalle
            WHERE reserva_id NOT IN (1, 2, 3)
        """)
        
        cursor.execute("""
            DELETE FROM eventos.reserva
            WHERE reserva_id NOT IN (1, 2, 3)
        """)
        
        cursor.close()
        conn.close()
        print("Datos de simulación restablecidos correctamente.")
    except Exception as e:
        print(f"Error al restablecer datos: {str(e)}")

def save_results_to_csv(results):
    """Guarda los resultados de la simulación en un archivo CSV.
    
    Args:
        results: Lista de diccionarios con los resultados de cada simulación.
    """
    try:
        with open(RESULTS_FILE, 'w', newline='') as csvfile:
            fieldnames = ['num_users', 'isolation_level', 'successful', 'failed', 'avg_time', 'total_time']
            writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
            
            writer.writeheader()
            for result in results:
                writer.writerow(result)
        
        print(f"Resultados guardados en {RESULTS_FILE}")
    except Exception as e:
        print(f"Error al guardar resultados: {str(e)}")

def generate_report():
    """Genera un informe con los resultados de las simulaciones basado en los registros de la base de datos."""
    try:
        conn = psycopg2.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        # Obtener estadísticas por nivel de aislamiento y número de usuarios
        cursor.execute("""
            SELECT 
                nivel_aislamiento, 
                COUNT(DISTINCT usuario_id) AS num_usuarios,
                SUM(CASE WHEN resultado = 'EXITOSO' THEN 1 ELSE 0 END) AS reservas_exitosas,
                SUM(CASE WHEN resultado = 'FALLIDO' THEN 1 ELSE 0 END) AS reservas_fallidas,
                AVG(tiempo_ejecucion) AS tiempo_promedio
            FROM 
                eventos.log_intentos_reserva
            GROUP BY 
                nivel_aislamiento, 
                (SELECT COUNT(DISTINCT usuario_id) FROM eventos.log_intentos_reserva l2 
                 WHERE l2.nivel_aislamiento = eventos.log_intentos_reserva.nivel_aislamiento)
            ORDER BY 
                nivel_aislamiento, 
                num_usuarios
        """)
        
        report_data = cursor.fetchall()
        
        # Crear tabla para el informe
        if report_data:
            headers = ["Nivel de Aislamiento", "Usuarios Concurrentes", "Reservas Exitosas", "Reservas Fallidas", "Tiempo Promedio (ms)"]
            table = tabulate(report_data, headers=headers, tablefmt="grid")
            print("\n=== INFORME DE RESULTADOS ===")
            print(table)
        else:
            print("\nNo hay datos de simulación disponibles para generar un informe.")
        
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"Error al generar informe: {str(e)}")

def main():
    """Función principal del programa."""
    parser = argparse.ArgumentParser(description='Simulador de reservas concurrentes para PostgreSQL.')
    parser.add_argument('--users', type=int, default=DEFAULT_NUM_USERS, 
                        help=f'Número de usuarios concurrentes (default: {DEFAULT_NUM_USERS})')
    parser.add_argument('--isolation', choices=['read_committed', 'repeatable_read', 'serializable'], 
                        default=DEFAULT_ISOLATION_LEVEL,
                        help=f'Nivel de aislamiento (default: {DEFAULT_ISOLATION_LEVEL})')
    parser.add_argument('--reset', action='store_true', 
                        help='Restablecer los datos de simulación antes de ejecutar')
    parser.add_argument('--run-all', action='store_true',
                        help='Ejecutar todas las combinaciones de prueba (5, 10, 20, 30 usuarios con todos los niveles de aislamiento)')
    parser.add_argument('--report', action='store_true',
                        help='Generar un informe con los resultados de las simulaciones')
    
    args = parser.parse_args()
    
    if args.report:
        generate_report()
        return
    
    if args.reset:
        reset_simulation_data()
        if not args.run_all:
            return
    
    all_results = []
    
    if args.run_all:
        user_counts = [5, 10, 20, 30]
        isolation_levels = list(ISOLATION_LEVELS.keys())
        
        for user_count in user_counts:
            for isolation_level in isolation_levels:
                reset_simulation_data()  # Restablecer datos antes de cada simulación
                simulator = ReservationSimulator(user_count, ISOLATION_LEVELS[isolation_level])
                result = simulator.run_simulation()
                all_results.append(result)
        
        # Guardar todos los resultados en un archivo CSV
        save_results_to_csv(all_results)
        
        # Generar informe final
        generate_report()
    else:
        simulator = ReservationSimulator(args.users, ISOLATION_LEVELS[args.isolation])
        simulator.run_simulation()

if __name__ == "__main__":
    main()