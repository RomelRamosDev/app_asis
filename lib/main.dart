import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
import 'auth_provider.dart';
import 'pin_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: url,
    anonKey: anonKey,
  );

  await SharedPreferences.getInstance();
  // Inicializar providers
  final empleadoProvider = EmpleadoProvider();
  final asistenciaProvider = AsistenciaProvider();
  final sedeProvider = SedeProvider();
  final areaProvider = AreaProvider();
  final authProvider = AuthProvider();

  // Cargar datos iniciales
  await areaProvider.cargarAreas();
  await sedeProvider.cargarSedes();
  await empleadoProvider.cargarEmpleados();
  await asistenciaProvider.cargarAsistencias();
  await authProvider.autoLogin();

  if (authProvider.isAuthenticated && authProvider.currentAreaId != null) {
    try {
      final area = areaProvider.areas.firstWhere(
        (a) => a.id == authProvider.currentAreaId,
      );
      areaProvider.seleccionarArea(area);

      final sede = sedeProvider.sedes.firstWhere(
        (s) => s.id == area.sedeId,
      );
      sedeProvider.seleccionarSede(sede);
    } catch (e) {
      debugPrint('Error configurando sede/área desde auth: $e');
    }
  } else if (sedeProvider.sedeActual != null && areaProvider.areas.isNotEmpty) {
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
        ChangeNotifierProvider(create: (_) => authProvider),
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
    final authProvider = Provider.of<AuthProvider>(context);

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
      home: sedeActual == null
          ? SeleccionarSedeScreen()
          : authProvider.isAuthenticated
              ? HomeNavigation()
              : PinAuthScreen(
                  moduleName: 'Inicio',
                  destination: HomeNavigation(),
                ),
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
    final authProvider = Provider.of<AuthProvider>(context);

    if (sedeActual == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SeleccionarSedeScreen()),
        );
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return authProvider.isAuthenticated
        ? EmpleadoForm(sedeId: sedeActual.id)
        : PinAuthScreen(
            moduleName: 'Formulario de Empleado',
            destination: EmpleadoForm(sedeId: sedeActual.id),
          );
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
  String? _cargoSeleccionado;
  late String
      _areaId; // Cambiamos a late ya que siempre se inicializa en didChangeDependencies

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
      // Si estamos creando nuevo empleado, cargamos el primer cargo disponible
      if (_areaId.isNotEmpty && _cargoSeleccionado == null) {
        final area = areaProvider.areas.firstWhere(
          (a) => a.id == _areaId,
          orElse: () => Area(id: '', nombre: '', sedeId: ''),
        );
        if (area.cargos != null && area.cargos!.isNotEmpty) {
          _cargoSeleccionado = area.cargos!.first;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final areaProvider = Provider.of<AreaProvider>(context);
    final sedeProvider = Provider.of<SedeProvider>(context);

    // Obtenemos el área actual para mostrar su nombre
    final areaActual = areaProvider.areas.firstWhere(
      (a) => a.id == _areaId,
      orElse: () => Area(id: '', nombre: 'Área no seleccionada', sedeId: ''),
    );

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text(
            widget.empleado == null ? 'Registrar Empleado' : 'Editar Empleado'),
        actions: [
          IconButton(
            icon: const Icon(Icons.work_outline),
            tooltip: 'Área actual: ${areaActual.nombre}',
            onPressed: () {
              Navigator.pushNamed(context, '/seleccionar_area');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            shrinkWrap: true,
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

              // Campo de Área (solo lectura)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Área',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor:
                      Colors.grey[200], // Fondo gris para indicar solo lectura
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    areaActual.nombre,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              SizedBox(height: 10),

              // Dropdown de Cargos (solo se muestra si hay área seleccionada)
              _areaId.isNotEmpty
                  ? DropdownButtonFormField<String>(
                      value: _cargoSeleccionado,
                      decoration: const InputDecoration(
                        labelText: 'Cargo*',
                        border: OutlineInputBorder(),
                      ),
                      items: areaProvider.areas
                              .firstWhere(
                                (a) => a.id == _areaId,
                                orElse: () =>
                                    Area(id: '', nombre: '', sedeId: ''),
                              )
                              .cargos
                              ?.map<DropdownMenuItem<String>>(
                                (cargo) => DropdownMenuItem<String>(
                                  value: cargo,
                                  child: Text(cargo),
                                ),
                              )
                              .toList() ??
                          [],
                      onChanged: (String? value) {
                        setState(() => _cargoSeleccionado = value);
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return 'Seleccione un cargo';
                        return null;
                      },
                    )
                  : const Text(
                      'No hay área seleccionada. Seleccione un área primero.',
                      style: TextStyle(color: Colors.grey),
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
                      cargo: _cargoSeleccionado ?? '',
                      sedeId: widget.sedeId,
                      areaId: _areaId,
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
