import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'asistencia_provider.dart';
import 'aistencia_model.dart';
import 'marcacion_automatica_service.dart';

class ListaAsistencia extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);
    final empleados = empleadoProvider.empleados;
    final fechaActual = DateTime.now();
    final fechaActualFormateada = DateFormat('yyyy-MM-dd').format(fechaActual);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      MarcacionAutomaticaService.verificarMarcacionesAutomaticas(context);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text('Registro de Asistencia'),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _mostrarResumenVacaciones(context, empleados),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await asistenciaProvider.cargarAsistencias();
          await empleadoProvider.cargarEmpleados();
        },
        child: ListView.builder(
          itemCount: empleados.length,
          itemBuilder: (context, index) {
            final empleado = empleados[index];
            return _buildEmpleadoTile(
                context, empleado, asistenciaProvider, fechaActualFormateada);
          },
        ),
      ),
    );
  }

  Widget _buildEmpleadoTile(BuildContext context, Empleado empleado,
      AsistenciaProvider asistenciaProvider, String fechaActual) {
    return FutureBuilder<List<Asistencia>>(
      future: asistenciaProvider.getAsistenciasPorEmpleado(empleado.cedula),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildTileBase(
            context,
            empleado: empleado,
            backgroundColor: Colors.grey[200],
            message: 'Cargando...',
            showEntryAction: false,
            showExitAction: false,
          );
        }

        if (snapshot.hasError) {
          return _buildTileBase(
            context,
            empleado: empleado,
            backgroundColor: Colors.orange[100],
            message: 'Error al cargar datos',
            showEntryAction: false,
            showExitAction: false,
          );
        }

        final asistencias = snapshot.data ?? [];
        final asistenciasHoy = asistencias.where((a) {
          final fechaAsistencia =
              DateFormat('yyyy-MM-dd').format(a.horaEntrada);
          return fechaAsistencia == fechaActual;
        }).toList();

        // Verificar si está de vacaciones
        if (empleado.enVacaciones &&
            empleado.fechaInicioEstado != null &&
            empleado.fechaFinEstado != null &&
            DateTime.now().isAfter(empleado.fechaInicioEstado!) &&
            DateTime.now().isBefore(empleado.fechaFinEstado!)) {
          return _buildVacacionesTile(context, empleado);
        }

        // Si no hay registros hoy
        if (asistenciasHoy.isEmpty) {
          return _buildEntradaTile(context, empleado, asistenciaProvider);
        }

        final ultimaAsistencia = asistenciasHoy.last;
        final horaEntrada =
            DateFormat('hh:mm a').format(ultimaAsistencia.horaEntrada);

        // Si no ha registrado salida
        if (ultimaAsistencia.horaSalida == null) {
          return _buildSalidaTile(context, empleado, asistenciaProvider,
              ultimaAsistencia, horaEntrada);
        }

        // Si ya registró entrada y salida, no mostrar
        return SizedBox.shrink();
      },
    );
  }

  // Método modificado para aceptar la asistencia completa
  Widget _buildSalidaTile(
      BuildContext context,
      Empleado empleado,
      AsistenciaProvider asistenciaProvider,
      Asistencia asistencia,
      String horaEntrada) {
    return Dismissible(
      key: Key('salida_${empleado.cedula}'),
      direction: DismissDirection.endToStart,
      background: _buildDismissibleBackground(
        color: Colors.red,
        icon: Icons.logout,
        alignment: Alignment.centerRight,
      ),
      onDismissed: (_) => _marcarSalida(context, empleado, asistenciaProvider),
      child: Container(
        color: Colors.green[100],
        child: ListTile(
          title: Text('${empleado.nombre} ${empleado.apellido}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Entrada: $horaEntrada'),
              if (asistencia.entradaAutomatica)
                Text('Entrada automática',
                    style: TextStyle(color: Colors.orange, fontSize: 12)),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.logout, color: Colors.red),
                onPressed: () => _marcarSalida(context, empleado,
                    Provider.of<AsistenciaProvider>(context, listen: false)),
              ),
              IconButton(
                icon: Icon(Icons.beach_access, color: Colors.blue),
                onPressed: () => _mostrarDialogoVacaciones(context, empleado),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /* 
   *  A PARTIR DE AQUÍ TODOS LOS MÉTODOS SE MANTIENEN EXACTAMENTE IGUAL 
   *  A COMO LOS TENÍAS EN TU CÓDIGO ORIGINAL
   */

  Widget _buildVacacionesTile(BuildContext context, Empleado empleado) {
    return _buildTileBase(
      context,
      empleado: empleado,
      backgroundColor: Colors.blue[100],
      message:
          'De vacaciones hasta ${DateFormat('dd/MM/yyyy').format(empleado.fechaFinEstado!)}',
      showEntryAction: false,
      showExitAction: false,
    );
  }

  Widget _buildEntradaTile(BuildContext context, Empleado empleado,
      AsistenciaProvider asistenciaProvider) {
    return Dismissible(
      key: Key('entrada_${empleado.cedula}'),
      direction: DismissDirection.startToEnd,
      background: _buildDismissibleBackground(
        color: Colors.green,
        icon: Icons.login,
        alignment: Alignment.centerLeft,
      ),
      confirmDismiss: (direction) async {
        if (empleado.enVacaciones) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${empleado.nombre} está de vacaciones')),
          );
          return false;
        }
        return true;
      },
      onDismissed: (_) => _marcarEntrada(context, empleado, asistenciaProvider),
      child: _buildTileBase(
        context,
        empleado: empleado,
        backgroundColor: Colors.red[100],
        message: 'No ha registrado entrada',
        showEntryAction: true,
        showExitAction: false,
      ),
    );
  }

  Widget _buildTileBase(
    BuildContext context, {
    required Empleado empleado,
    required Color? backgroundColor,
    required String message,
    required bool showEntryAction,
    required bool showExitAction,
  }) {
    return Container(
      color: backgroundColor,
      child: ListTile(
        title: Text('${empleado.nombre} ${empleado.apellido}'),
        subtitle: Text(message),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showEntryAction)
              IconButton(
                icon: Icon(Icons.login, color: Colors.green),
                onPressed: () => _marcarEntrada(context, empleado,
                    Provider.of<AsistenciaProvider>(context, listen: false)),
              ),
            if (showExitAction)
              IconButton(
                icon: Icon(Icons.logout, color: Colors.red),
                onPressed: () => _marcarSalida(context, empleado,
                    Provider.of<AsistenciaProvider>(context, listen: false)),
              ),
            IconButton(
              icon: Icon(Icons.beach_access, color: Colors.blue),
              onPressed: () => _mostrarDialogoVacaciones(context, empleado),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDismissibleBackground({
    required Color color,
    required IconData icon,
    required Alignment alignment,
  }) {
    return Container(
      color: color,
      alignment: alignment,
      padding: EdgeInsets.symmetric(horizontal: 20),
      child: Icon(icon, color: Colors.white, size: 30),
    );
  }

  Future<void> _mostrarDialogoVacaciones(
      BuildContext context, Empleado empleado) async {
    DateTime? fechaInicio = empleado.fechaInicioEstado;
    DateTime? fechaFin = empleado.fechaFinEstado;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(empleado.enVacaciones
                  ? 'Editar vacaciones o Permiso Medico'
                  : 'Marcar vacaciones o Permiso Medico'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text('Fecha de inicio'),
                    subtitle: Text(fechaInicio != null
                        ? DateFormat('dd/MM/yyyy').format(fechaInicio!)
                        : 'No seleccionada'),
                    trailing: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: fechaInicio ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            fechaInicio = selectedDate;
                          });
                        }
                      },
                    ),
                  ),
                  ListTile(
                    title: Text('Fecha de fin'),
                    subtitle: Text(fechaFin != null
                        ? DateFormat('dd/MM/yyyy').format(fechaFin!)
                        : 'No seleccionada'),
                    trailing: IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () async {
                        final selectedDate = await showDatePicker(
                          context: context,
                          initialDate: fechaFin ??
                              (fechaInicio ?? DateTime.now())
                                  .add(Duration(days: 7)),
                          firstDate: fechaInicio ?? DateTime.now(),
                          lastDate: DateTime.now().add(Duration(days: 365)),
                        );
                        if (selectedDate != null) {
                          setState(() {
                            fechaFin = selectedDate;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                if (empleado.enVacaciones)
                  TextButton(
                    onPressed: () async {
                      final empleadoProvider =
                          Provider.of<EmpleadoProvider>(context, listen: false);
                      empleado.enVacaciones = false;
                      empleado.fechaInicioEstado = null;
                      empleado.fechaFinEstado = null;
                      await empleadoProvider.actualizarEmpleado(empleado);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Vacaciones canceladas para ${empleado.nombre}')),
                      );
                    },
                    child: Text('Cancelar vacaciones',
                        style: TextStyle(color: Colors.red)),
                  ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (fechaInicio != null && fechaFin != null) {
                      if (fechaFin!.isBefore(fechaInicio!)) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'La fecha fin debe ser posterior a la fecha inicio')),
                        );
                        return;
                      }

                      final empleadoProvider =
                          Provider.of<EmpleadoProvider>(context, listen: false);
                      empleado.enVacaciones = true;
                      empleado.fechaInicioEstado = fechaInicio;
                      empleado.fechaFinEstado = fechaFin;
                      await empleadoProvider.actualizarEmpleado(empleado);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Vacaciones registradas para ${empleado.nombre}')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Seleccione ambas fechas')),
                      );
                    }
                  },
                  child: Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _mostrarResumenVacaciones(
      BuildContext context, List<Empleado> empleados) {
    final empleadosEnVacaciones =
        empleados.where((e) => e.enVacaciones).toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Empleados de vacaciones o con Permiso Medico'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: empleadosEnVacaciones.length,
            itemBuilder: (context, index) {
              final empleado = empleadosEnVacaciones[index];
              return ListTile(
                title: Text('${empleado.nombre} ${empleado.apellido}'),
                subtitle: Text(
                    '${DateFormat('dd/MM/yyyy').format(empleado.fechaInicioEstado!)} '
                    '- ${DateFormat('dd/MM/yyyy').format(empleado.fechaFinEstado!)}'),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _marcarEntrada(BuildContext context, Empleado empleado,
      AsistenciaProvider asistenciaProvider) async {
    // Verificar si está de vacaciones
    if (empleado.enVacaciones &&
        empleado.fechaInicioEstado != null &&
        empleado.fechaFinEstado != null &&
        DateTime.now().isAfter(empleado.fechaInicioEstado!) &&
        DateTime.now().isBefore(empleado.fechaFinEstado!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${empleado.nombre} está de vacaciones')),
      );
      return;
    }

    final horaActual = DateTime.now();
    final horaLimiteEntrada =
        DateTime(horaActual.year, horaActual.month, horaActual.day, 8, 31);

    bool atrasoEntrada = horaActual.isAfter(horaLimiteEntrada);

    final observaciones = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Observaciones (opcional)'),
          content: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Ingrese alguna observación',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (observaciones == null) return;

    if (atrasoEntrada) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Entrada tardía'),
          content:
              Text('${empleado.nombre} ha llegado después de las 8:31 AM.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Aceptar'),
            ),
          ],
        ),
      );
    }

    await asistenciaProvider.registrarEntrada(
        empleado.cedula, atrasoEntrada, observaciones);

    // Actualizar datos
    final empleadoProvider =
        Provider.of<EmpleadoProvider>(context, listen: false);
    await empleadoProvider.cargarEmpleados();
    await asistenciaProvider.cargarAsistencias();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entrada registrada para ${empleado.nombre}')),
    );
  }

  void _marcarSalida(BuildContext context, Empleado empleado,
      AsistenciaProvider asistenciaProvider) async {
    final horaActual = DateTime.now();
    final horaLimiteSalida =
        DateTime(horaActual.year, horaActual.month, horaActual.day, 17, 00);

    bool atrasoSalida = horaActual.isAfter(horaLimiteSalida);

    final observaciones = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text('Observaciones (opcional)'),
          content: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Ingrese alguna observación',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, controller.text);
              },
              child: Text('Aceptar'),
            ),
          ],
        );
      },
    );

    if (observaciones == null) return;

    final llevaTarjetas = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('¿Lleva tarjetas?'),
            content: Text(
                '¿El empleado lleva tarjetas para entregar fuera del horario laboral?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Sí'),
              ),
            ],
          ),
        ) ??
        false;

    if (atrasoSalida) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('${empleado.nombre} ha salido después de las 17:00 PM.'),
          backgroundColor: Colors.green,
        ),
      );
    }

    await asistenciaProvider.registrarSalida(
        empleado.cedula, atrasoSalida, llevaTarjetas, observaciones);

    // Actualizar datos
    final empleadoProvider =
        Provider.of<EmpleadoProvider>(context, listen: false);
    await empleadoProvider.cargarEmpleados();
    await asistenciaProvider.cargarAsistencias();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salida registrada para ${empleado.nombre}')),
    );
  }
}
