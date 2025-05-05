import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:workmanager/workmanager.dart';
import 'package:intl/intl.dart';
import 'empleado_provider.dart';
import 'asistencia_provider.dart';
import 'sede_provider.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);

      // Necesitamos inicializar los providers manualmente en background
      final empleadoProvider = EmpleadoProvider();
      final asistenciaProvider = AsistenciaProvider();
      final sedeProvider = SedeProvider();

      // Cargar datos necesarios
      await empleadoProvider.cargarEmpleados();
      await asistenciaProvider.cargarAsistencias();
      await sedeProvider.cargarSedes();

      if (ahora.hour == 10 && ahora.minute == 0) {
        await MarcacionAutomaticaService.marcarEntradasAutomaticas(
            empleadoProvider, asistenciaProvider, sedeProvider, hoy);
      } else if (ahora.hour == 19 && ahora.minute == 30) {
        await MarcacionAutomaticaService.marcarSalidasAutomaticas(
            empleadoProvider, asistenciaProvider, sedeProvider, hoy);
      }
    } catch (e) {
      debugPrint('Error en ejecución background: $e');
    }
    return true;
  });
}

class MarcacionAutomaticaService {
  static Future<void> init() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false,
    );

    await Workmanager().registerPeriodicTask(
      'marcacion-automatica',
      'marcacionAutomaticaTask',
      frequency: Duration(hours: 1),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }

  static Future<void> verificarMarcacionesAutomaticas(
      BuildContext context) async {
    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);

    final empleadoProvider =
        Provider.of<EmpleadoProvider>(context, listen: false);
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
    final sedeProvider = Provider.of<SedeProvider>(context, listen: false);

    if (ahora.hour == 10 && ahora.minute == 0) {
      await marcarEntradasAutomaticas(
          empleadoProvider, asistenciaProvider, sedeProvider, hoy);
    } else if (ahora.hour == 19 && ahora.minute == 30) {
      await marcarSalidasAutomaticas(
          empleadoProvider, asistenciaProvider, sedeProvider, hoy);
    }
  }

  static Future<void> marcarEntradasAutomaticas(
      EmpleadoProvider empleadoProvider,
      AsistenciaProvider asistenciaProvider,
      SedeProvider sedeProvider,
      DateTime hoy) async {
    try {
      debugPrint('Iniciando marcación automática de entradas...');

      final empleados = empleadoProvider.empleados
          .where((e) => e.enVacaciones || e.enPermisoMedico)
          .toList();

      for (final empleado in empleados) {
        try {
          // Verificar si ya tiene entrada hoy
          final asistencias = await asistenciaProvider
              .getAsistenciasPorEmpleado(empleado.cedula);

          final tieneEntradaHoy = asistencias.any((a) =>
              a.horaEntrada.year == hoy.year &&
              a.horaEntrada.month == hoy.month &&
              a.horaEntrada.day == hoy.day);

          if (!tieneEntradaHoy) {
            final horaEntrada = DateTime(hoy.year, hoy.month, hoy.day, 8, 30);
            final sedeId = empleado.sedeId; // Obtenemos la sede del empleado

            await asistenciaProvider.registrarEntradaAutomatica(
              empleado.cedula,
              horaEntrada,
              "Entrada automática - ${empleado.enVacaciones ? 'Vacaciones' : 'Permiso médico'}",
              sedeId, // Pasamos el sedeId
            );
            debugPrint('Entrada automática registrada para ${empleado.nombre}');
          }
        } catch (e) {
          debugPrint(
              'Error marcando entrada automática para ${empleado.nombre}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error en marcación automática de entradas: $e');
    }
  }

  static Future<void> marcarSalidasAutomaticas(
      EmpleadoProvider empleadoProvider,
      AsistenciaProvider asistenciaProvider,
      SedeProvider sedeProvider,
      DateTime hoy) async {
    try {
      debugPrint('Iniciando marcación automática de salidas...');

      final empleados = empleadoProvider.empleados;

      for (final empleado in empleados) {
        try {
          final asistencias = await asistenciaProvider
              .getAsistenciasPorEmpleado(empleado.cedula);

          final asistenciasHoy = asistencias
              .where((a) =>
                  a.horaEntrada.year == hoy.year &&
                  a.horaEntrada.month == hoy.month &&
                  a.horaEntrada.day == hoy.day)
              .toList();

          if (asistenciasHoy.isNotEmpty) {
            final asistencia = asistenciasHoy.first;
            if (asistencia.horaSalida == null) {
              final horaSalida = DateTime(hoy.year, hoy.month, hoy.day, 17, 0);
              await asistenciaProvider.registrarSalidaAutomatica(
                asistencia.id!,
                horaSalida,
                "Salida automática",
              );
              debugPrint(
                  'Salida automática registrada para ${empleado.nombre}');
            }
          }
        } catch (e) {
          debugPrint(
              'Error marcando salida automática para ${empleado.nombre}: $e');
        }
      }
    } catch (e) {
      debugPrint('Error en marcación automática de salidas: $e');
    }
  }
}
