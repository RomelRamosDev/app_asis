import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:camera/camera.dart';
import 'facial_recognition_service.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'home_navigation.dart';
import 'asistencia_provider.dart';
import 'package:path/path.dart' as pth;
import 'package:sqflite/sqflite.dart';

Future<void> deleteDatabase() async {
  final dbPath = await getDatabasesPath();
  final path = pth.join(dbPath, 'empleados.db');
  await databaseFactory
      .deleteDatabase(path); // Usa databaseFactory.deleteDatabase
  print('Base de datos eliminada: $path');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await deleteDatabase();

  final empleadoProvider = EmpleadoProvider();
  final asistenciaProvider = AsistenciaProvider();

  // Cargar datos al iniciar
  await empleadoProvider.cargarEmpleados();
  await asistenciaProvider.cargarAsistencias();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => empleadoProvider),
        ChangeNotifierProvider(create: (_) => asistenciaProvider),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Registro de Empleados',
      home: HomeNavigation(), // Usar la navegación principal
    );
  }
}

class EmpleadoForm extends StatefulWidget {
  @override
  _EmpleadoFormState createState() => _EmpleadoFormState();
}

class _EmpleadoFormState extends State<EmpleadoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _cedulaController = TextEditingController();
  String _cargoSeleccionado = 'Mensajero';
  String? _facialDataPath;
  CameraController? _cameraController;
  final FacialRecognitionService _facialRecognitionService =
      FacialRecognitionService();

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _captureFacialData() async {
    final cameras = await availableCameras();

    // Busca la cámara frontal
    final CameraDescription? frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () =>
          cameras[0], // Si no encuentra la frontal, usa la primera disponible
    );

    _cameraController = CameraController(frontCamera!, ResolutionPreset.medium);
    await _cameraController!.initialize();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: CameraPreview(_cameraController!),
          actions: [
            TextButton(
              onPressed: () async {
                final image = await _cameraController!.takePicture();
                final faces = await _facialRecognitionService
                    .detectFaces(File(image.path));
                if (faces.isNotEmpty) {
                  _facialDataPath = await _facialRecognitionService
                      .saveFacialData(File(image.path));
                }
                Navigator.pop(context);
              },
              child: Text('Capturar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Empleado'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _apellidoController,
                decoration: InputDecoration(labelText: 'Apellido'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el apellido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cedulaController,
                decoration: InputDecoration(labelText: 'Cédula'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa la cédula';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _cargoSeleccionado,
                decoration: InputDecoration(labelText: 'Cargo'),
                items: <String>['Mensajero', 'Supervisor', 'Call Center']
                    .map<DropdownMenuItem<String>>((String valor) {
                  return DropdownMenuItem<String>(
                    value: valor,
                    child: Text(valor),
                  );
                }).toList(),
                onChanged: (String? nuevoValor) {
                  setState(() {
                    _cargoSeleccionado = nuevoValor!;
                  });
                },
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _captureFacialData,
                child: Text('Capturar datos faciales'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final empleado = Empleado(
                      nombre: _nombreController.text,
                      apellido: _apellidoController.text,
                      cedula: _cedulaController.text,
                      cargo: _cargoSeleccionado,
                      facialDataPath: _facialDataPath,
                    );
                    empleadoProvider.agregarEmpleado(empleado);
                    Navigator.pop(context);
                  }
                },
                child: Text('Registrar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
