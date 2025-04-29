import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'asistencia_provider.dart';
import 'aistencia_model.dart';
import 'themes.dart';

class BuscarEmpleado extends StatefulWidget {
  @override
  _BuscarEmpleadoState createState() => _BuscarEmpleadoState();
}

class _BuscarEmpleadoState extends State<BuscarEmpleado> {
  final _cedulaController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Motorizados Procontacto'), actions: [
        IconButton(
          icon: Icon(Icons.business),
          tooltip: 'Sede actual',
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/seleccionar_sede');
          },
        ),
      ]),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/Logotrns.png', // Ruta de la imagen
                width: 225, // Ancho de la imagen
                height: 225, // Alto de la imagen
                fit: BoxFit.contain, // Ajustar la imagen
              ),
              const SizedBox(height: 5), // Espacio entre la imagen y el texto
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
                  final empleado = empleadoProvider.empleados.firstWhere(
                    (emp) => emp.cedula == cedula,
                    orElse: () => Empleado(
                      nombre: '',
                      apellido: '',
                      cedula: '',
                      cargo: '',
                      sedeId: '',
                    ),
                  );
                  if (empleado.cedula.isNotEmpty) {
                    final haRegistradoEntrada =
                        await asistenciaProvider.haRegistradoEntrada(cedula);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalleAsistencia(
                          empleado: empleado,
                          haRegistradoEntrada: haRegistradoEntrada,
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Empleado no encontrado')),
                    );
                  }
                },
                child:
                    Text('Buscar por cédula', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenPalette[
                      500], // Color de fondo del botón (antes primary)
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
}

class DetalleAsistencia extends StatelessWidget {
  final Empleado empleado;
  final haRegistradoEntrada;

  DetalleAsistencia({
    required this.empleado,
    required this.haRegistradoEntrada,
  });

  @override
  Widget build(BuildContext context) {
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Asistencia de ${empleado.nombre}'),
      ),
      body: FutureBuilder<List<Asistencia>>(
        future: asistenciaProvider.getAsistenciasPorEmpleado(empleado.cedula),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error al cargar las asistencias'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No hay registros de asistencia'));
          }

          final asistencias = snapshot.data!;
          final ultimaAsistencia = asistencias.last;

          final haRegistradoSalida = ultimaAsistencia.horaSalida != null;

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
    final horaActual = DateTime.now();
    final horaLimiteEntrada =
        DateTime(horaActual.year, horaActual.month, horaActual.day, 8, 31);

    bool atrasoEntrada =
        horaActual.isAfter(horaLimiteEntrada); // Verificar atraso

    // Controlador para el campo de texto de observaciones
    final observacionesController = TextEditingController();

    // Mostrar diálogo para ingresar observaciones
    final observaciones = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Observaciones (opcional)'),
        content: TextFormField(
          controller: observacionesController, // Asignar el controlador
          decoration: const InputDecoration(
            hintText: 'Ingrese alguna observación',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.green, // Color del borde cuando está enfocado
                width: 2.0, // Grosor del borde
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
            onPressed: () => Navigator.pop(context), // Cancelar
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
            onPressed: () {
              // Obtener el valor del campo de texto y cerrar el diálogo
              Navigator.pop(context, observacionesController.text);
            },
            child: Text('Aceptar'),
          ),
        ],
      ),
    );

    // Si el usuario hizo clic en "Cancelar", no registrar la entrada
    if (observaciones == null) {
      return; // Salir del método sin hacer nada
    }

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

    // Registrar la entrada con el campo observaciones
    await asistenciaProvider.registrarEntrada(
        empleado.cedula, atrasoEntrada, observaciones);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entrada registrada para ${empleado.nombre}')),
    );
    Navigator.pop(context); // Regresar a la pantalla anterior
  }

  void _marcarSalida(BuildContext context) async {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
    final horaActual = DateTime.now();
    final horaLimiteSalida =
        DateTime(horaActual.year, horaActual.month, horaActual.day, 17, 00);

    bool atrasoSalida =
        horaActual.isAfter(horaLimiteSalida); // Verificar atraso

    // Controlador para el campo de texto de observaciones
    final observacionesController = TextEditingController();

    // Mostrar diálogo para ingresar observaciones
    final observaciones = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Observaciones (opcional)'),
        content: TextFormField(
          controller: observacionesController, // Asignar el controlador
          decoration: const InputDecoration(
            hintText: 'Ingrese alguna observación',
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: Colors.green, // Color del borde cuando está enfocado
                width: 2.0, // Grosor del borde
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
            onPressed: () => Navigator.pop(context), // Cancelar
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
            onPressed: () {
              // Obtener el valor del campo de texto y cerrar el diálogo
              Navigator.pop(context, observacionesController.text);
            },
            child: Text('Aceptar'),
          ),
        ],
      ),
    );

    // Si el usuario hizo clic en "Cancelar", no registrar la salida
    if (observaciones == null) {
      return; // Salir del método sin hacer nada
    }

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
              Text('${empleado.nombre} ha salido después de las 17:00 PM.'),
          backgroundColor: Colors.green,
        ),
      );
    }

    // Registrar la salida con el campo observaciones
    await asistenciaProvider.registrarSalida(
        empleado.cedula, atrasoSalida, llevaTarjetas, observaciones);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salida registrada para ${empleado.nombre}')),
    );
    Navigator.pop(context); // Regresar a la pantalla anterior
  }
}
