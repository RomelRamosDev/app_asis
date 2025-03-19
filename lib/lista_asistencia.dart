import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'asistencia_provider.dart';
import 'aistencia_model.dart';
import 'package:intl/intl.dart';

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
          return _buildEmpleadoTile(context, empleado, asistenciaProvider);
        },
      ),
    );
  }

  // Método para construir el ListTile de cada empleado
  Widget _buildEmpleadoTile(BuildContext context, Empleado empleado,
      AsistenciaProvider asistenciaProvider) {
    return FutureBuilder<List<Asistencia>>(
      future: asistenciaProvider.getAsistenciasPorEmpleado(empleado.cedula),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return ListTile(
            title: Text('${empleado.nombre} ${empleado.apellido}'),
            subtitle: Text('Cargando...'),
          );
        } else if (snapshot.hasError) {
          return ListTile(
            title: Text('${empleado.nombre} ${empleado.apellido}'),
            subtitle: Text('Error al cargar asistencias'),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          // Si no hay asistencias, el empleado no ha registrado entrada
          return Dismissible(
            key: Key(empleado.cedula), // Clave única para el empleado
            direction:
                DismissDirection.endToStart, // Deslizar de derecha a izquierda
            background: Container(
              color: Colors.green,
              alignment: Alignment.centerRight,
              padding: EdgeInsets.only(right: 20),
              child: Icon(Icons.check, color: Colors.white),
            ),
            onDismissed: (direction) {
              _marcarEntrada(context, empleado, asistenciaProvider);
            },
            child: ListTile(
              title: Text('${empleado.nombre} ${empleado.apellido}'),
              subtitle: Text('No ha registrado entrada hoy'),
            ),
          );
        } else {
          final asistenciasHoy = snapshot.data!;
          final ultimaAsistencia = asistenciasHoy.last;

          // Formatear la hora de entrada
          final horaEntradaFormateada = DateFormat('dd/MM/yyyy hh:mm a')
              .format(ultimaAsistencia.horaEntrada);

          if (ultimaAsistencia.horaSalida == null) {
            // Si no ha registrado salida, permitir marcar salida
            return Dismissible(
              key: Key(empleado.cedula), // Clave única para el empleado
              direction: DismissDirection
                  .endToStart, // Deslizar de derecha a izquierda
              background: Container(
                color: Colors.red,
                alignment: Alignment.centerRight,
                padding: EdgeInsets.only(right: 20),
                child: Icon(Icons.exit_to_app, color: Colors.white),
              ),
              onDismissed: (direction) {
                _marcarSalida(context, empleado, asistenciaProvider);
              },
              child: ListTile(
                title: Text('${empleado.nombre} ${empleado.apellido}'),
                subtitle: Text('Entrada: $horaEntradaFormateada'),
              ),
            );
          } else {
            // Si ya registró entrada y salida, no mostrar en la lista
            return SizedBox.shrink();
          }
        }
      },
    );
  }

  void _marcarEntrada(BuildContext context, Empleado empleado,
      AsistenciaProvider asistenciaProvider) async {
    final horaActual = DateTime.now();
    final horaLimiteEntrada =
        DateTime(horaActual.year, horaActual.month, horaActual.day, 8, 30);

    bool atrasoEntrada =
        horaActual.isAfter(horaLimiteEntrada); // Verificar atraso

    if (atrasoEntrada) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Entrada tardía'),
          content:
              Text('${empleado.nombre} ha llegado después de las 8:30 AM.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Aceptar'),
            ),
          ],
        ),
      );
    }

    // Registrar la entrada con el campo atrasoEntrada
    await asistenciaProvider.registrarEntrada(empleado.cedula, atrasoEntrada);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entrada registrada para ${empleado.nombre}')),
    );
  }

  void _marcarSalida(BuildContext context, Empleado empleado,
      AsistenciaProvider asistenciaProvider) async {
    final horaActual = DateTime.now();
    final horaLimiteSalida =
        DateTime(horaActual.year, horaActual.month, horaActual.day, 17, 30);

    bool atrasoSalida =
        horaActual.isAfter(horaLimiteSalida); // Verificar atraso

    // Preguntar si lleva tarjetas
    final llevaTarjetas = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('¿Lleva tarjetas?'),
            content: Text(
                '¿El empleado lleva tarjetas para entregar fuera del horario laboral?'),
            actions: [
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, false), // No lleva tarjetas
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true), // Lleva tarjetas
                child: Text('Sí'),
              ),
            ],
          ),
        ) ??
        false; // Valor predeterminado: false

    if (atrasoSalida) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${empleado.nombre} ha salido después de las 17:30 PM.'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Registrar la salida con el campo atrasoSalida y llevaTarjetas
    await asistenciaProvider.registrarSalida(
        empleado.cedula, atrasoSalida, llevaTarjetas);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salida registrada para ${empleado.nombre}')),
    );
  }
}
