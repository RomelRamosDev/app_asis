import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'asistencia_provider.dart';
import 'aistencia_model.dart';
import 'sede_provider.dart';
import 'area_provider.dart';
import 'snackbar_service.dart';
import 'themes.dart';
import 'auth_provider.dart';
import 'pin_auth_screen.dart';

const motorizadosAreaIdQuito = '96af2e36-cd65-42c1-b22e-47a5e53a7f9d';

const motorizadosAreaIdGYE = 'f08b8d0d-ee48-4c36-91e8-723cb87e8986';

final areasMotorizados = {motorizadosAreaIdQuito, motorizadosAreaIdGYE};

class ListaAsistencia extends StatefulWidget {
  @override
  _ListaAsistenciaState createState() => _ListaAsistenciaState();
}

class _ListaAsistenciaState extends State<ListaAsistencia> {
  @override
  Widget build(BuildContext context) {
    final sedeProvider = Provider.of<SedeProvider>(context);
    final areaProvider = Provider.of<AreaProvider>(context);
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return PinAuthScreen(
        moduleName: 'Asistencia',
        destination: ListaAsistencia(),
        areaId: areaProvider.areaActual?.id,
      );
    }

    if (sedeProvider.sedeActual == null) {
      return _buildNoSedeSelected(context);
    }

    if (areaProvider.areaActual == null) {
      return _buildNoAreaSelected(context);
    }

    final sedeActualId = sedeProvider.sedeActual!.id;
    final areaActualId = areaProvider.areaActual!.id;

    final empleados = empleadoProvider.empleados.where((e) {
      return e.sedeId == sedeActualId && e.areaId == areaActualId;
    }).toList();

    final fechaActual = DateTime.now();
    final fechaActualFormateada = DateFormat('yyyy-MM-dd').format(fechaActual);

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Asistencia - ${sedeProvider.sedeActual?.nombre ?? ''} - ${areaProvider.areaActual?.nombre ?? ''}',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today),
            onPressed: () => _mostrarResumenVacaciones(context, empleados),
          ),
          IconButton(
            icon: Icon(Icons.business),
            tooltip: 'Sede actual',
            onPressed: () {
              NotificationService.showInfo(
                  'Sede: ${sedeProvider.sedeActual?.nombre ?? 'No seleccionada'}\n'
                  'Área: ${areaProvider.areaActual?.nombre ?? 'No seleccionada'}');
            },
          ),
          if (authProvider.isAuthenticated)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await authProvider.logout();
                setState(() {
                  Navigator.pushReplacementNamed(context,
                      '/seleccionar_sede'); // Volver a pantalla de búsqueda
                });
              },
              tooltip: 'Cerrar sesión',
            ),
          if (authProvider.currentRole == 'supervisor')
            IconButton(
              icon: Icon(Icons.autorenew),
              onPressed: () async {
                await _actualizarDatos();
                NotificationService.showSuccess('Datos actualizados');
              },
              tooltip: 'Actualizar datos',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await asistenciaProvider.cargarAsistencias();
          await empleadoProvider.cargarEmpleados();
        },
        child: empleados.isEmpty
            ? _buildNoEmployeesInArea()
            : FutureBuilder<List<Asistencia>>(
                future: asistenciaProvider.getAsistenciasPorSedeYArea(
                    sedeActualId, areaActualId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                        child: Text('Error al cargar las asistencias'));
                  }

                  final asistencias = snapshot.data ?? [];
                  return ListView.builder(
                    itemCount: empleados.length,
                    itemBuilder: (context, index) {
                      final empleado = empleados[index];
                      return _buildEmpleadoTile(
                        context,
                        empleado,
                        asistencias,
                        fechaActualFormateada,
                        sedeActualId,
                        areaActualId,
                      );
                    },
                  );
                },
              ),
      ),
    );
  }

  Widget _buildNoSedeSelected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business,
              size: 64, color: greenPalette[500]), // Verde medio
          SizedBox(height: 20),
          Text(
            'No se ha seleccionado sede',
            style: TextStyle(
              fontSize: 18,
              color: greenPalette[700], // Verde oscuro para texto
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/seleccionar_sede');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: greenPalette[500], // Verde principal
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            child: Text(
              'SELECCIONAR SEDE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoAreaSelected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.work_outline,
              size: 64, color: greenPalette[500]), // Verde medio
          SizedBox(height: 20),
          Text(
            'No se ha seleccionado área',
            style: TextStyle(
              fontSize: 18,
              color: greenPalette[700], // Verde oscuro para texto
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/seleccionar_area');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: greenPalette[500], // Verde principal
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 3,
            ),
            child: Text(
              'SELECCIONAR ÁREA',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoEmployeesInArea() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('No hay empleados en esta área', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }

  Widget _buildEmpleadoTile(
    BuildContext context,
    Empleado empleado,
    List<Asistencia> asistencias,
    String fechaActual,
    String sedeId,
    String areaId,
  ) {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
    final areaProvider = Provider.of<AreaProvider>(context, listen: false);

    final asistenciasHoy = asistencias.where((a) {
      final fechaAsistencia = DateFormat('yyyy-MM-dd').format(a.horaEntrada);
      return fechaAsistencia == fechaActual &&
          a.cedulaEmpleado == empleado.cedula &&
          a.sedeId == sedeId &&
          a.areaId == areaId;
    }).toList();

    if ((empleado.enVacaciones || empleado.enPermisoMedico) &&
        empleado.fechaInicioEstado != null &&
        empleado.fechaFinEstado != null &&
        DateTime.now().isAfter(empleado.fechaInicioEstado!) &&
        DateTime.now().isBefore(empleado.fechaFinEstado!)) {
      return _buildVacacionesTile(context, empleado, sedeId, areaId);
    }

    if (asistenciasHoy.isEmpty) {
      return _buildEntradaTile(
          context, empleado, asistenciaProvider, sedeId, areaId);
    }

    final ultimaAsistencia = asistenciasHoy.last;
    final horaEntrada =
        DateFormat('hh:mm a').format(ultimaAsistencia.horaEntrada);

    if (ultimaAsistencia.horaSalida == null) {
      return _buildSalidaTile(
        context,
        empleado,
        asistenciaProvider,
        ultimaAsistencia,
        horaEntrada,
        sedeId,
        areaId,
      );
    }

    return SizedBox.shrink();
  }

  Widget _buildVacacionesTile(
      BuildContext context, Empleado empleado, String sedeId, String areaId) {
    final estado = empleado.enVacaciones ? 'VACACIONES' : 'PERMISO MÉDICO';
    final fechaFin = DateFormat('dd/MM/yyyy').format(empleado.fechaFinEstado!);

    return _buildTileBase(
      context,
      empleado: empleado,
      backgroundColor:
          empleado.enVacaciones ? Colors.blue[100] : Colors.orange[100],
      message: '$estado hasta $fechaFin',
      showEntryAction: false,
      showExitAction: false,
      sedeId: sedeId,
      areaId: areaId,
    );
  }

  Widget _buildEntradaTile(
    BuildContext context,
    Empleado empleado,
    AsistenciaProvider asistenciaProvider,
    String sedeId,
    String areaId,
  ) {
    return Dismissible(
      key: Key('entrada_${empleado.cedula}_$sedeId$areaId'),
      direction: DismissDirection.startToEnd,
      background: _buildDismissibleBackground(
        color: Colors.green,
        icon: Icons.login,
        alignment: Alignment.centerLeft,
      ),
      confirmDismiss: (direction) async {
        if (empleado.enVacaciones) {
          NotificationService.showWarning(
              '${empleado.nombre} está de vacaciones');
          return false;
        }
        return true;
      },
      onDismissed: (_) =>
          _marcarEntrada(empleado, asistenciaProvider, sedeId, areaId),
      child: _buildTileBase(
        context,
        empleado: empleado,
        backgroundColor: Colors.red[100],
        message: 'No ha registrado entrada',
        showEntryAction: true,
        showExitAction: false,
        sedeId: sedeId,
        areaId: areaId,
      ),
    );
  }

  Widget _buildSalidaTile(
    BuildContext context,
    Empleado empleado,
    AsistenciaProvider asistenciaProvider,
    Asistencia asistencia,
    String horaEntrada,
    String sedeId,
    String areaId,
  ) {
    return Dismissible(
      key: Key('salida_${empleado.cedula}_$sedeId$areaId'),
      direction: DismissDirection.endToStart,
      background: _buildDismissibleBackground(
        color: Colors.red,
        icon: Icons.logout,
        alignment: Alignment.centerRight,
      ),
      onDismissed: (_) =>
          _marcarSalida(empleado, asistenciaProvider, sedeId, areaId),
      child: Container(
        color: Colors.green[100],
        child: ListTile(
          title: Text('${empleado.nombre} ${empleado.apellido}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Entrada: $horaEntrada'),
              if (asistencia.atrasoEntrada)
                Text('Atraso en entrada',
                    style: TextStyle(color: Colors.red, fontSize: 12)),
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
                onPressed: () => _marcarSalida(
                    empleado,
                    Provider.of<AsistenciaProvider>(context, listen: false),
                    sedeId,
                    areaId),
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

  Widget _buildTileBase(
    BuildContext context, {
    required Empleado empleado,
    required Color? backgroundColor,
    required String message,
    required bool showEntryAction,
    required bool showExitAction,
    required String sedeId,
    required String areaId,
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
                onPressed: () => _marcarEntrada(
                    empleado,
                    Provider.of<AsistenciaProvider>(context, listen: false),
                    sedeId,
                    areaId),
              ),
            if (showExitAction)
              IconButton(
                icon: Icon(Icons.logout, color: Colors.red),
                onPressed: () => _marcarSalida(
                    empleado,
                    Provider.of<AsistenciaProvider>(context, listen: false),
                    sedeId,
                    areaId),
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

  Future<void> _marcarEntrada(
    Empleado empleado,
    AsistenciaProvider asistenciaProvider,
    String sedeId,
    String areaId,
  ) async {
    try {
      if (empleado.enVacaciones &&
          empleado.fechaInicioEstado != null &&
          empleado.fechaFinEstado != null &&
          DateTime.now().isAfter(empleado.fechaInicioEstado!) &&
          DateTime.now().isBefore(empleado.fechaFinEstado!)) {
        NotificationService.showWarning(
            '${empleado.nombre} está de vacaciones');
        return;
      }

      final areaProvider = Provider.of<AreaProvider>(context, listen: false);
      final area = areaProvider.areas.firstWhere((a) => a.id == areaId);
      final horaActual = DateTime.now();
      bool atrasoEntrada = false;

      if (area.hora_entrada_area != null) {
        final diferencia = horaActual.difference(area.hora_entrada_area!);
        atrasoEntrada = diferencia.inMinutes > 15;
      }

      final observaciones =
          await _mostrarDialogo(context, 'Observaciones (opcional)');
      if (observaciones == null) return;

      if (atrasoEntrada) {
        NotificationService.showWarning('${empleado.nombre} ha llegado tarde');
      }

      await asistenciaProvider.registrarEntrada(
        context,
        empleado.cedula,
        observaciones,
        sedeId,
        areaId,
      );

      await _actualizarDatos();
      NotificationService.showSuccess(
          'Entrada registrada para ${empleado.nombre}');
    } catch (e) {
      NotificationService.showError(
          'Error al registrar entrada: ${e.toString()}');
    }
  }

  Future<void> _marcarSalida(
    Empleado empleado,
    AsistenciaProvider asistenciaProvider,
    String sedeId,
    String areaId,
  ) async {
    try {
      final areaProvider = Provider.of<AreaProvider>(context, listen: false);
      final area = areaProvider.areas.firstWhere((a) => a.id == areaId);
      final horaActual = DateTime.now();
      bool atrasoSalida = false;

      if (area.hora_salida_area != null) {
        final diferencia = horaActual.difference(area.hora_salida_area!);
        atrasoSalida = diferencia.inMinutes > 15;
      }

      final observaciones =
          await _mostrarDialogo(context, 'Observaciones (opcional)');
      if (observaciones == null) return;

      bool? llevaTarjetas = false;
      if (areasMotorizados.contains(areaId)) {
        llevaTarjetas = await _mostrarConfirmacion(
            context, '¿El empleado lleva tarjetas fuera del horario laboral?');
      }

      if (atrasoSalida) {
        NotificationService.showWarning('${empleado.nombre} ha salido tarde');
      }

      await asistenciaProvider.registrarSalida(
        context,
        empleado.cedula,
        llevaTarjetas,
        observaciones,
        sedeId,
        areaId,
      );

      await _actualizarDatos();
      NotificationService.showSuccess(
          'Salida registrada para ${empleado.nombre}');
    } catch (e) {
      NotificationService.showError(
          'Error al registrar salida: ${e.toString()}');
    }
  }

  Future<String?> _mostrarDialogo(BuildContext context, String titulo) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(titulo),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }

  Future<bool> _mostrarConfirmacion(
      BuildContext context, String mensaje) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(mensaje),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sí'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _actualizarDatos() async {
    final empleadoProvider =
        Provider.of<EmpleadoProvider>(context, listen: false);
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
    await Future.wait([
      empleadoProvider.cargarEmpleados(),
      asistenciaProvider.cargarAsistencias(),
    ]);
  }

  Future<void> _mostrarDialogoVacaciones(
      BuildContext context, Empleado empleado) async {
    DateTime? fechaInicio = empleado.fechaInicioEstado;
    DateTime? fechaFin = empleado.fechaFinEstado;

    bool esVacaciones = empleado.enVacaciones;
    bool esPermisoMedico = empleado.enPermisoMedico;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(empleado.enVacaciones || empleado.enPermisoMedico
                  ? 'Editar estado'
                  : 'Marcar estado'),
              content: SingleChildScrollView(
                // Añade desplazamiento
                child: Container(
                  width: double.maxFinite, // Aprovecha el ancho disponible
                  child: Column(
                    mainAxisSize: MainAxisSize.min, // Tamaño mínimo necesario
                    children: [
                      // Selector de tipo de estado - versión compacta
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ChoiceChip(
                            label: Text('Vacaciones'),
                            selected: esVacaciones,
                            onSelected: (selected) {
                              setState(() {
                                esVacaciones = selected;
                                esPermisoMedico = !selected;
                              });
                            },
                          ),
                          ChoiceChip(
                            label: Text('Permiso Médico'),
                            selected: esPermisoMedico,
                            onSelected: (selected) {
                              setState(() {
                                esPermisoMedico = selected;
                                esVacaciones = !selected;
                              });
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                      // Selector de fechas más compacto
                      Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text('Fecha inicio:'),
                              ),
                              TextButton(
                                child: Text(
                                  fechaInicio != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(fechaInicio!)
                                      : 'Seleccionar',
                                  style: TextStyle(color: Colors.blue),
                                ),
                                onPressed: () async {
                                  final selectedDate = await showDatePicker(
                                    context: context,
                                    initialDate: fechaInicio ?? DateTime.now(),
                                    firstDate: DateTime.now(),
                                    lastDate:
                                        DateTime.now().add(Duration(days: 365)),
                                  );
                                  if (selectedDate != null) {
                                    setState(() => fechaInicio = selectedDate);
                                  }
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text('Fecha fin:'),
                              ),
                              TextButton(
                                child: Text(
                                  fechaFin != null
                                      ? DateFormat('dd/MM/yyyy')
                                          .format(fechaFin!)
                                      : 'Seleccionar',
                                  style: TextStyle(color: Colors.blue),
                                ),
                                onPressed: () async {
                                  final selectedDate = await showDatePicker(
                                    context: context,
                                    initialDate: fechaFin ??
                                        (fechaInicio ?? DateTime.now())
                                            .add(Duration(days: 7)),
                                    firstDate: fechaInicio ?? DateTime.now(),
                                    lastDate:
                                        DateTime.now().add(Duration(days: 365)),
                                  );
                                  if (selectedDate != null) {
                                    setState(() => fechaFin = selectedDate);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (empleado.enVacaciones || empleado.enPermisoMedico)
                  TextButton(
                    onPressed: () async {
                      final empleadoProvider =
                          Provider.of<EmpleadoProvider>(context, listen: false);
                      empleado.enVacaciones = false;
                      empleado.enPermisoMedico = false;
                      empleado.fechaInicioEstado = null;
                      empleado.fechaFinEstado = null;
                      await empleadoProvider.actualizarEmpleado(empleado);

                      if (mounted) {
                        setState(() {});
                      }

                      Navigator.pop(context);
                      NotificationService.showSuccess(
                          'Estado cancelado para ${empleado.nombre}');
                    },
                    child: Text('Cancelar estado',
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
                        NotificationService.showError(
                            'La fecha fin debe ser posterior a la fecha inicio');
                        return;
                      }

                      final empleadoProvider =
                          Provider.of<EmpleadoProvider>(context, listen: false);
                      empleado.enVacaciones = esVacaciones;
                      empleado.enPermisoMedico = esPermisoMedico;
                      empleado.fechaInicioEstado = fechaInicio;
                      empleado.fechaFinEstado = fechaFin;

                      await empleadoProvider.actualizarEmpleado(empleado);

                      // Forzar la actualización del estado
                      if (mounted) {
                        setState(
                            () {}); // Esto hace que el widget se reconstruya
                      }

                      Navigator.pop(context);
                      NotificationService.showSuccess(
                          'Estado registrado para ${empleado.nombre}');
                    } else {
                      NotificationService.showError('Seleccione ambas fechas');
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
    final empleadosConEstado = empleados
        .where((e) =>
            (e.enVacaciones || e.enPermisoMedico) &&
            e.fechaInicioEstado != null &&
            e.fechaFinEstado != null)
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Empleados con estado especial'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: empleadosConEstado.length,
            itemBuilder: (context, index) {
              final empleado = empleadosConEstado[index];
              final estado =
                  empleado.enVacaciones ? 'Vacaciones' : 'Permiso Médico';
              final colorEstado =
                  empleado.enVacaciones ? Colors.blue : Colors.orange;

              return ListTile(
                leading: Icon(
                  empleado.enVacaciones
                      ? Icons.beach_access
                      : Icons.medical_services,
                  color: colorEstado,
                ),
                title: Text('${empleado.nombre} ${empleado.apellido}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estado,
                      style: TextStyle(
                          color: colorEstado, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${DateFormat('dd/MM/yyyy').format(empleado.fechaInicioEstado!)} '
                      '- ${DateFormat('dd/MM/yyyy').format(empleado.fechaFinEstado!)}',
                    ),
                  ],
                ),
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
}
