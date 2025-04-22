import 'package:flutter/material.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'facial_recognition_service.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'home_navigation.dart';
import 'asistencia_provider.dart';
import 'package:path/path.dart' as pth;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'conexion_helper.dart';
import 'themes.dart';
import 'key.dart';
import 'marcacion_automatica_service.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // final tieneConexion = await ConexionHelper.tieneConexionInternet();

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  final empleadoProvider = EmpleadoProvider();
  final asistenciaProvider = AsistenciaProvider();

  // Cargar datos al iniciar
  await empleadoProvider.cargarEmpleados();
  await asistenciaProvider.cargarAsistencias();

  await MarcacionAutomaticaService.init();

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
    _iniciarServicioMarcacionAutomatica(context);

    return MaterialApp(
      title: 'Registro de Empleados',
      theme: ThemeData(
        primarySwatch: greenPalette, // Usamos la paleta de colores verdes
        scaffoldBackgroundColor: Colors.white, // Fondo de las pantallas
        appBarTheme: AppBarTheme(
          color: greenPalette[800], // Color del AppBar
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: HomeNavigation(),
      debugShowCheckedModeBanner: false, // Usar la navegación principal
    );
  }

  void _iniciarServicioMarcacionAutomatica(BuildContext context) {
    // Verificar cada minuto si hay marcaciones automáticas pendientes
    Timer.periodic(const Duration(minutes: 1), (timer) {
      MarcacionAutomaticaService.verificarMarcacionesAutomaticas(context);
    });

    // Verificar inmediatamente al iniciar la app
    WidgetsBinding.instance.addPostFrameCallback((_) {
      MarcacionAutomaticaService.verificarMarcacionesAutomaticas(context);
    });
  }
}
// class MyApp extends StatelessWidget {
//   // final bool tieneConexion;

//   MyApp({required this.tieneConexion});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Registro de Empleados',
//       home: tieneConexion ? HomeNavigation() : SinConexionScreen(),
//     );
//   }
// }

// class SinConexionScreen extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.signal_wifi_off, size: 64, color: Colors.red),
//             SizedBox(height: 20),
//             Text(
//               'Sin conexión a Internet',
//               style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//             ),
//             SizedBox(height: 10),
//             Text(
//               'Conéctate a una red Wi-Fi o usa datos móviles para continuar.',
//               textAlign: TextAlign.center,
//               style: TextStyle(fontSize: 16),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class EmpleadoForm extends StatefulWidget {
  final Empleado? empleado;

  EmpleadoForm({this.empleado});

  @override
  _EmpleadoFormState createState() => _EmpleadoFormState();
}

class _EmpleadoFormState extends State<EmpleadoForm> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _cedulaController = TextEditingController();
  String _cargoSeleccionado = 'Mensajero';

  @override
  void initState() {
    super.initState();
    if (widget.empleado != null) {
      // Si se está editando un empleado, llenar los campos con sus datos
      _nombreController.text = widget.empleado!.nombre;
      _apellidoController.text = widget.empleado!.apellido;
      _cedulaController.text = widget.empleado!.cedula;
      _cargoSeleccionado = widget.empleado!.cargo;
    }
  }

  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.empleado == null ? 'Registrar Empleado' : 'Editar Empleado'),
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
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'La cédula debe tener 10 dígitos numéricos';
                  }
                  if (empleadoProvider.empleados
                      .any((emp) => emp.cedula == value)) {
                    return 'La cédula ya está registrada';
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
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenPalette[
                      500], // Color de fondo del botón (antes primary)
                  foregroundColor: Colors
                      .white, // Color del texto del botón (antes onPrimary)
                ),
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    final empleado = Empleado(
                      id: widget
                          .empleado?.id, // Mantener el ID si se está editando
                      nombre: _nombreController.text,
                      apellido: _apellidoController.text,
                      cedula: _cedulaController.text,
                      cargo: _cargoSeleccionado,
                    );

                    if (widget.empleado == null) {
                      // Agregar nuevo empleado
                      empleadoProvider.agregarEmpleado(empleado);
                    } else {
                      // Actualizar empleado existente
                      empleadoProvider.actualizarEmpleado(empleado);
                    }

                    Navigator.pop(context);
                  }
                },
                child:
                    Text(widget.empleado == null ? 'Registrar' : 'Actualizar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
