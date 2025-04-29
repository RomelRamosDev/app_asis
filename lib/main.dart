import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'asistencia_provider.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'home_navigation.dart';
import 'key.dart';
import 'marcacion_automatica_service.dart';
import 'seleccionar_sede.dart';
import 'sede_provider.dart';
import 'themes.dart';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  // Inicializar providers
  final empleadoProvider = EmpleadoProvider();
  final asistenciaProvider = AsistenciaProvider();
  final sedeProvider = SedeProvider();

  // Cargar datos iniciales
  await sedeProvider.cargarSedes();
  await empleadoProvider.cargarEmpleados();
  await asistenciaProvider.cargarAsistencias();

  await MarcacionAutomaticaService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => sedeProvider),
        ChangeNotifierProvider(create: (_) => empleadoProvider),
        ChangeNotifierProvider(create: (_) => asistenciaProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    _iniciarServicioMarcacionAutomatica(context);
    final sedeActual = Provider.of<SedeProvider>(context).sedeActual;

    return MaterialApp(
      title: 'Registro de Empleados',
      theme: ThemeData(
        primarySwatch: greenPalette,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          color: greenPalette[800],
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      home: sedeActual == null ? SeleccionarSedeScreen() : HomeNavigation(),
      debugShowCheckedModeBanner: false,
      routes: {
        '/seleccionar_sede': (context) => SeleccionarSedeScreen(),
        '/empleado_form': (context) => const EmpleadoFormWrapper(),
      },
    );
  }

  void _iniciarServicioMarcacionAutomatica(BuildContext context) {
    Timer.periodic(const Duration(minutes: 1), (timer) {
      MarcacionAutomaticaService.verificarMarcacionesAutomaticas(context);
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      MarcacionAutomaticaService.verificarMarcacionesAutomaticas(context);
    });
  }
}

class EmpleadoFormWrapper extends StatelessWidget {
  const EmpleadoFormWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final sedeActual = Provider.of<SedeProvider>(context).sedeActual;

    if (sedeActual == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SeleccionarSedeScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return EmpleadoForm(sedeId: sedeActual.id);
  }
}

class EmpleadoForm extends StatefulWidget {
  final String sedeId;
  final Empleado? empleado;

  const EmpleadoForm({
    super.key,
    required this.sedeId,
    this.empleado,
  });

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
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el nombre';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _apellidoController,
                decoration: const InputDecoration(labelText: 'Apellido'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa el apellido';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _cedulaController,
                decoration: const InputDecoration(labelText: 'Cédula'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingresa la cédula';
                  }
                  if (!RegExp(r'^[0-9]{10}$').hasMatch(value)) {
                    return 'La cédula debe tener 10 dígitos numéricos';
                  }
                  if (widget.empleado == null &&
                      empleadoProvider.empleados
                          .any((emp) => emp.cedula == value)) {
                    return 'La cédula ya está registrada';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _cargoSeleccionado,
                decoration: const InputDecoration(labelText: 'Cargo'),
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
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: greenPalette[500],
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    final empleado = Empleado(
                      id: widget.empleado?.id,
                      nombre: _nombreController.text,
                      apellido: _apellidoController.text,
                      cedula: _cedulaController.text,
                      cargo: _cargoSeleccionado,
                      sedeId:
                          widget.sedeId, // Asignamos la sede automáticamente
                    );

                    if (widget.empleado == null) {
                      await empleadoProvider.agregarEmpleado(empleado);
                    } else {
                      await empleadoProvider.actualizarEmpleado(empleado);
                    }

                    if (mounted) Navigator.pop(context);
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
