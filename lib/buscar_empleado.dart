import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'asistencia_provider.dart';
import 'facial_recognition_service.dart';
import 'dart:io';

class BuscarEmpleado extends StatefulWidget {
  @override
  _BuscarEmpleadoState createState() => _BuscarEmpleadoState();
}

class _BuscarEmpleadoState extends State<BuscarEmpleado> {
  final _cedulaController = TextEditingController();
  final FacialRecognitionService _facialRecognitionService =
      FacialRecognitionService();

  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Buscar empleado por cédula o reconocimiento facial'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ingresa la cédula del empleado',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Container(
                width: 300,
                child: TextFormField(
                  controller: _cedulaController,
                  decoration: InputDecoration(
                    labelText: 'Cédula',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.search),
                  ),
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                ),
              ),
              SizedBox(height: 20),
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
                      SnackBar(content: Text('Empleado no encontrado')),
                    );
                  }
                },
                child:
                    Text('Buscar por cédula', style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final empleado = await _validarConReconocimientoFacial(
                      context, empleadoProvider);
                  if (empleado != null) {
                    final haRegistradoEntrada = await asistenciaProvider
                        .haRegistradoEntrada(empleado.cedula);
                    final haRegistradoSalida = await asistenciaProvider
                        .haRegistradoSalida(empleado.cedula);

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
                  }
                },
                child: Text('Validar con reconocimiento facial',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
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

  Future<Empleado?> _validarConReconocimientoFacial(
      BuildContext context, EmpleadoProvider empleadoProvider) async {
    final cameras = await availableCameras();

    // Busca la cámara frontal
    final CameraDescription? frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () =>
          cameras[0], // Si no encuentra la frontal, usa la primera disponible
    );

    final cameraController =
        CameraController(frontCamera!, ResolutionPreset.medium);
    await cameraController.initialize();

    // Verifica si el widget está montado
    if (!mounted) return null;

    Empleado? empleadoValidado;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: CameraPreview(cameraController),
          actions: [
            TextButton(
              onPressed: () async {
                final image = await cameraController.takePicture();
                final faces = await _facialRecognitionService
                    .detectFaces(File(image.path));
                if (faces.isNotEmpty) {
                  for (final empleado in empleadoProvider.empleados) {
                    if (empleado.facialDataPath != null) {
                      final savedImage = File(empleado.facialDataPath!);
                      final isMatch = await _facialRecognitionService
                          .compareFaces(File(image.path), savedImage);
                      if (isMatch) {
                        empleadoValidado = empleado;
                        break;
                      }
                    }
                  }
                }
                Navigator.pop(context);
              },
              child: Text('Capturar y validar'),
            ),
          ],
        );
      },
    );

    await cameraController.dispose();

    if (empleadoValidado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo validar el empleado')),
      );
    }

    return empleadoValidado;
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
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
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
    await asistenciaProvider.registrarEntrada(empleado.cedula);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Entrada registrada para ${empleado.nombre}')),
    );
    Navigator.pop(context); // Regresar a la pantalla anterior
  }

  void _marcarSalida(BuildContext context) async {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
    await asistenciaProvider.registrarSalida(empleado.cedula);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Salida registrada para ${empleado.nombre}')),
    );
    Navigator.pop(context); // Regresar a la pantalla anterior
  }
}
