import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'asistencia_provider.dart';
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
      appBar: AppBar(
        title: const Text('Motorizados Procontacto'),
      ),
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
                    ),
                  );
                  if (empleado.cedula.isNotEmpty) {
                    final haRegistradoEntrada =
                        await asistenciaProvider.haRegistradoEntrada(cedula);
                    final haRegistradoSalida =
                        await asistenciaProvider.haRegistradoSalida(cedula);

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetalleAsistencia(
                          empleado: empleado,
                          haRegistradoEntrada: haRegistradoEntrada,
                          haRegistradoSalida: haRegistradoSalida,
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
  final bool haRegistradoEntrada;
  final bool haRegistradoSalida;

  DetalleAsistencia({
    required this.empleado,
    required this.haRegistradoEntrada,
    required this.haRegistradoSalida,
  });

  @override
  Widget build(BuildContext context) {
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Asistencia de ${empleado.nombre}'),
      ),
      body: Center(
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
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
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
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _marcarEntrada(BuildContext context) async {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
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
    Navigator.pop(context); // Regresar a la pantalla anterior
  }

  void _marcarSalida(BuildContext context) async {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
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
    Navigator.pop(context); // Regresar a la pantalla anterior
  }
}
