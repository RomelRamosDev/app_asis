import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'asistencia_provider.dart';
import 'aistencia_model.dart';
import 'themes.dart';
import 'sede_provider.dart';
import 'area_provider.dart';
import 'package:intl/intl.dart';

const motorizadosAreaIdQuito = '96af2e36-cd65-42c1-b22e-47a5e53a7f9d';
const motorizadosAreaIdGYE = 'f08b8d0d-ee48-4c36-91e8-723cb87e8986';
final areasMotorizados = {motorizadosAreaIdQuito, motorizadosAreaIdGYE};

class BuscarEmpleado extends StatefulWidget {
  @override
  _BuscarEmpleadoState createState() => _BuscarEmpleadoState();
}

class _BuscarEmpleadoState extends State<BuscarEmpleado> {
  final _cedulaController = TextEditingController();

  bool _esAreaMotorizados(String areaId) {
    return areasMotorizados.contains(areaId);
  }

  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);
    final sedeProvider = Provider.of<SedeProvider>(context);
    final areaProvider = Provider.of<AreaProvider>(context);

    // Verificar primero si hay sede seleccionada
    if (sedeProvider.sedeActual == null) {
      return _buildNoSedeSelected(context);
    }

    // Verificar si hay área seleccionada
    if (areaProvider.areaActual == null) {
      return _buildNoAreaSelected(context);
    }

    final sedeActualId = sedeProvider.sedeActual!.id;
    final areaActualId = areaProvider.areaActual!.id;
    final areaActualNombre = areaProvider.areaActual?.nombre ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(_esAreaMotorizados(areaActualId)
            ? 'Motorizados Procontacto'
            : areaActualNombre),
        actions: [
          IconButton(
            icon: Icon(Icons.business),
            tooltip: 'Cambiar sede',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/seleccionar_sede');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _esAreaMotorizados(areaActualId)
                  ? Image.asset(
                      'assets/Logotrns.png',
                      width: 225,
                      height: 225,
                      fit: BoxFit.contain,
                    )
                  : Text(
                      areaActualNombre,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: greenPalette[700],
                      ),
                    ),
              const SizedBox(height: 20),
              const Text(
                'Ingresa tu número de cédula',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                width: 300,
                child: TextFormField(
                  controller: _cedulaController,
                  decoration: const InputDecoration(
                    labelText: 'Cédula',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                ),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  final cedula = _cedulaController.text;
                  if (cedula.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Ingrese un número de cédula')),
                    );
                    return;
                  }

                  final empleado = empleadoProvider.empleados.firstWhere(
                    (emp) =>
                        emp.cedula == cedula &&
                        emp.sedeId == sedeActualId &&
                        emp.areaId == areaActualId,
                    orElse: () => Empleado(
                      nombre: '',
                      apellido: '',
                      cedula: '',
                      cargo: '',
                      sedeId: '',
                      areaId: '',
                    ),
                  );

                  if (empleado.cedula.isNotEmpty) {
                    final haRegistradoEntrada =
                        await asistenciaProvider.haRegistradoEntradaHoy(
                            empleado.cedula, sedeActualId, areaActualId);
                    final haRegistradoSalida =
                        await asistenciaProvider.haRegistradoSalidaHoy(
                            empleado.cedula, sedeActualId, areaActualId);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalleAsistencia(
                          empleado: empleado,
                          haRegistradoEntrada: haRegistradoEntrada,
                          haRegistradoSalida: haRegistradoSalida,
                          sedeId: sedeActualId,
                          areaId: areaActualId,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Empleado no encontrado en esta área')),
                    );
                  }
                },
                child:
                    Text('Buscar por cédula', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenPalette[500],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
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
}

class DetalleAsistencia extends StatelessWidget {
  final Empleado empleado;
  final bool haRegistradoEntrada;
  final bool haRegistradoSalida;
  final String sedeId;
  final String areaId;

  const DetalleAsistencia({
    required this.empleado,
    required this.haRegistradoEntrada,
    required this.haRegistradoSalida,
    required this.sedeId,
    required this.areaId,
  });

  @override
  Widget build(BuildContext context) {
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);
    final areaProvider = Provider.of<AreaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Asistencia de ${empleado.nombre}'),
      ),
      body: FutureBuilder<List<Asistencia>>(
        future: asistenciaProvider.getAsistenciasPorEmpleadoYSedeYArea(
            empleado.cedula, sedeId, areaId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar las asistencias'));
          }

          // Filtrar asistencias del día actual
          final hoy = DateTime.now();
          final asistenciasHoy = snapshot.data
                  ?.where((a) =>
                      a.horaEntrada.year == hoy.year &&
                      a.horaEntrada.month == hoy.month &&
                      a.horaEntrada.day == hoy.day)
                  .toList() ??
              [];

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!haRegistradoEntrada)
                  ElevatedButton(
                    onPressed: () => _marcarEntrada(context),
                    child: Text('Marcar entrada'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenPalette[500],
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                if (haRegistradoEntrada && !haRegistradoSalida)
                  ElevatedButton(
                    onPressed: () => _marcarSalida(context),
                    child: Text('Marcar salida'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenPalette[500],
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                if (asistenciasHoy.isNotEmpty &&
                    asistenciasHoy.first.horaEntrada != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Entrada: ${DateFormat('hh:mm a').format(asistenciasHoy.first.horaEntrada)}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                if (asistenciasHoy.isNotEmpty &&
                    asistenciasHoy.first.horaSalida != null)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Salida: ${DateFormat('hh:mm a').format(asistenciasHoy.first.horaSalida!)}',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _marcarEntrada(BuildContext context) async {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
    final areaProvider = Provider.of<AreaProvider>(context, listen: false);

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

    final area = areaProvider.areas.firstWhere((a) => a.id == areaId);
    final horaActual = DateTime.now();
    bool atrasoEntrada = false;

    // Calcular atraso según horario del área
    if (area.hora_entrada_area != null) {
      final diferencia = horaActual.difference(area.hora_entrada_area!);
      atrasoEntrada = diferencia.inMinutes > 15;
    }

    final observaciones = await _mostrarDialogoObservaciones(context);
    if (observaciones == null) return;

    if (atrasoEntrada) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Entrada tardía'),
          content: Text(
              '${empleado.nombre} ha llegado después del horario establecido.'),
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
      context, // Necesario para acceder al AreaProvider
      empleado.cedula,
      observaciones,
      sedeId,
      areaId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entrada registrada para ${empleado.nombre}')),
    );
    Navigator.pop(context);
  }

  void _marcarSalida(BuildContext context) async {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
    final areaProvider = Provider.of<AreaProvider>(context, listen: false);

    final area = areaProvider.areas.firstWhere((a) => a.id == areaId);
    final horaActual = DateTime.now();
    bool atrasoSalida = false;

    // Calcular atraso según horario del área
    if (area.hora_salida_area != null) {
      final diferencia = horaActual.difference(area.hora_salida_area!);
      atrasoSalida = diferencia.inMinutes > 15;
    }

    final observaciones = await _mostrarDialogoObservaciones(context);
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
          content: Text(
              '${empleado.nombre} ha salido después del horario establecido.'),
          backgroundColor: Colors.green,
        ),
      );
    }

    await asistenciaProvider.registrarSalida(
      context, // Necesario para acceder al AreaProvider
      empleado.cedula,
      llevaTarjetas,
      observaciones,
      sedeId,
      areaId,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salida registrada para ${empleado.nombre}')),
    );
    Navigator.pop(context);
  }

  Future<String?> _mostrarDialogoObservaciones(BuildContext context) async {
    final controller = TextEditingController();
    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observaciones (opcional)'),
        content: TextFormField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Ingrese alguna observación',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.green,
                width: 2.0,
              ),
            ),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: greenPalette[500],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: greenPalette[500],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
