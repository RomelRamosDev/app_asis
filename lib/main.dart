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
import 'area_model.dart';
import 'area_provider.dart';
import 'seleccionar_area.dart';
import 'snackbar_service.dart';

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
  final areaProvider = AreaProvider();

  // Cargar datos iniciales
  await areaProvider.cargarAreas();
  await sedeProvider.cargarSedes();
  await empleadoProvider.cargarEmpleados();
  await asistenciaProvider.cargarAsistencias();

  if (sedeProvider.sedeActual != null && areaProvider.areas.isNotEmpty) {
    final areasDeSede = areaProvider.areasPorSede(sedeProvider.sedeActual!.id);
    if (areasDeSede.isNotEmpty) {
      areaProvider.seleccionarArea(areasDeSede.first);
    }
  }

  await MarcacionAutomaticaService.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => areaProvider),
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
    final areaActual = Provider.of<AreaProvider>(context).areaActual;

    return MaterialApp(
      scaffoldMessengerKey: NotificationService.key,
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
        '/seleccionar_area': (context) => SeleccionarAreaScreen(),
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
  String _areaId = ''; // Inicializado como string vacío

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final areaProvider = Provider.of<AreaProvider>(context, listen: false);
    final sedeProvider = Provider.of<SedeProvider>(context, listen: false);

    if (widget.empleado != null) {
      _nombreController.text = widget.empleado!.nombre;
      _apellidoController.text = widget.empleado!.apellido;
      _cedulaController.text = widget.empleado!.cedula;
      _cargoSeleccionado = widget.empleado!.cargo;
      _areaId = widget.empleado!.areaId;
    } else {
      // Asignar área actual por defecto
      _areaId = areaProvider.areaActual?.id ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final areaProvider = Provider.of<AreaProvider>(context);
    final sedeProvider = Provider.of<SedeProvider>(context);

    final areas = areaProvider.areas
        .where((area) => area.sedeId == sedeProvider.sedeActual?.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            widget.empleado == null ? 'Registrar Empleado' : 'Editar Empleado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.work_outline),
            tooltip:
                'Área actual: ${areaProvider.areaActual?.nombre ?? 'No seleccionada'}',
            onPressed: () {
              Navigator.pushNamed(context, '/seleccionar_area');
            },
          ),
        ],
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
              DropdownButtonFormField<String>(
                value: _areaId.isEmpty ? null : _areaId,
                decoration: const InputDecoration(labelText: 'Área'),
                items: [
                  const DropdownMenuItem<String>(
                    value: '',
                    child: Text('Seleccione un área',
                        style: TextStyle(color: Colors.grey)),
                  ),
                  ...areas
                      .map((area) => DropdownMenuItem<String>(
                            value: area.id,
                            child: Text(area.nombre),
                          ))
                      .toList(),
                ],
                onChanged: (value) {
                  setState(() => _areaId = value ?? '');
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, seleccione un área';
                  }
                  return null;
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
                      sedeId: widget.sedeId,
                      areaId: _areaId, // Usamos el valor actual
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
