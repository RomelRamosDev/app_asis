import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'asistencia_provider.dart';

class ListaAsistencia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);
    final empleados = empleadoProvider.empleados;

    // Obtener la fecha actual (sin la hora)
    final fechaActual = DateTime.now();
    final fechaActualFormateada =
        "${fechaActual.year}-${fechaActual.month.toString().padLeft(2, '0')}-${fechaActual.day.toString().padLeft(2, '0')}";

    // Filtrar empleados que no han registrado su entrada o salida hoy
    final empleadosSinAsistenciaHoy = empleados.where((empleado) {
      final asistenciasHoy = asistenciaProvider.asistencias.where((asistencia) {
        final fechaAsistencia = asistencia.horaEntrada
            .toString()
            .split(' ')[0]; // Obtener solo la fecha
        return fechaAsistencia == fechaActualFormateada &&
            asistencia.cedulaEmpleado == empleado.cedula;
      }).toList();

      // Verificar si el empleado no ha registrado su entrada hoy
      final noHaRegistradoEntradaHoy = asistenciasHoy.isEmpty;

      // Verificar si el empleado ha registrado su entrada pero no su salida hoy
      final haRegistradoEntradaPeroNoSalida = asistenciasHoy.any((asistencia) =>
          asistencia.horaEntrada != null && asistencia.horaSalida == null);

      return noHaRegistradoEntradaHoy || haRegistradoEntradaPeroNoSalida;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Empleados sin asistencia hoy'),
      ),
      body: ListView.builder(
        itemCount: empleadosSinAsistenciaHoy.length,
        itemBuilder: (context, index) {
          final empleado = empleadosSinAsistenciaHoy[index];
          return ListTile(
            title: Text('${empleado.nombre} ${empleado.apellido}'),
            subtitle:
                Text('Cédula: ${empleado.cedula} - Cargo: ${empleado.cargo}'),
            trailing: _buildBotonesAsistencia(context, empleado),
          );
        },
      ),
    );
  }

  // Método para construir los botones de asistencia
  Widget _buildBotonesAsistencia(BuildContext context, Empleado empleado) {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);

    return FutureBuilder<bool>(
      future: asistenciaProvider.haRegistradoEntrada(empleado.cedula),
      builder: (context, entradaSnapshot) {
        if (!entradaSnapshot.hasData) {
          return CircularProgressIndicator(); // Mostrar un indicador de carga mientras se obtiene el resultado
        }

        final haRegistradoEntrada = entradaSnapshot.data!;

        return FutureBuilder<bool>(
          future: asistenciaProvider.haRegistradoSalida(empleado.cedula),
          builder: (context, salidaSnapshot) {
            if (!salidaSnapshot.hasData) {
              return CircularProgressIndicator();
            }

            final haRegistradoSalida = salidaSnapshot.data!;

            if (!haRegistradoEntrada) {
              return ElevatedButton(
                onPressed: () => _marcarEntrada(context, empleado),
                child: Text('Marcar entrada'),
              );
            } else if (!haRegistradoSalida) {
              return ElevatedButton(
                onPressed: () => _marcarSalida(context, empleado),
                child: Text('Marcar salida'),
              );
            } else {
              return SizedBox
                  .shrink(); // No mostrar botones si ya registró entrada y salida
            }
          },
        );
      },
    );
  }

  // Método para marcar la entrada
  void _marcarEntrada(BuildContext context, Empleado empleado) {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
    asistenciaProvider.registrarEntrada(empleado.cedula);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entrada registrada para ${empleado.nombre}')),
    );
  }

  // Método para marcar la salida
  void _marcarSalida(BuildContext context, Empleado empleado) {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
    asistenciaProvider.registrarSalida(empleado.cedula);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salida registrada para ${empleado.nombre}')),
    );
  }
}
