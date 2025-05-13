import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'aistencia_model.dart';
import 'asistencia_provider.dart';
import 'package:intl/intl.dart';
import 'themes.dart';
import 'sede_provider.dart';
import 'area_provider.dart';
import 'snackbar_service.dart';
import 'auth_provider.dart';
import 'pin_auth_screen.dart';

class GenerarReporte extends StatefulWidget {
  @override
  _GenerarReporteState createState() => _GenerarReporteState();
}

class _GenerarReporteState extends State<GenerarReporte> {
  final _filtroReporteController = TextEditingController();
  final _filtroEliminarController = TextEditingController();
  String _filtroSeleccionadoReporte = 'Cédula';
  String _filtroSeleccionadoEliminar = 'Cédula';
  final fechaInicialReporteController = TextEditingController();
  final fechaFinalReporteController = TextEditingController();
  final fechaInicialEliminarController = TextEditingController();
  final fechaFinalEliminarController = TextEditingController();

  bool _filtrarPorAtrasos = false;
  bool _filtrarPorTarjetas = false;
  bool _modoEliminacionCombinada = true;
  // Nuevas variables para el proceso de eliminación
  String? _cedulaParaEliminar;
  List<Asistencia> _asistenciasFiltradasParaEliminar = [];
  String? _sedeId;
  String? _areaId;

  @override
  void initState() {
    super.initState();
    final sedeProvider = Provider.of<SedeProvider>(context, listen: false);
    final areaProvider = Provider.of<AreaProvider>(context, listen: false);
    _sedeId = sedeProvider.sedeActual?.id;
    _areaId = areaProvider.areaActual?.id;
  }

  Future<void> _eliminarAsistenciasCombinado() async {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
    final empleadoProvider =
        Provider.of<EmpleadoProvider>(context, listen: false);

    // Validaciones
    if (_cedulaParaEliminar == null || _cedulaParaEliminar!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese una cédula válida')),
      );
      return;
    }

    if (fechaInicialEliminarController.text.isEmpty ||
        fechaFinalEliminarController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un rango de fechas')),
      );
      return;
    }

    try {
      final formatoEntrada = DateFormat('dd-MM-yyyy');
      final fechaInicial =
          formatoEntrada.parse(fechaInicialEliminarController.text);
      final fechaFinal =
          formatoEntrada.parse(fechaFinalEliminarController.text);

      if (fechaFinal.isBefore(fechaInicial)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('La fecha final debe ser posterior a la inicial')),
        );
        return;
      }

      // Obtener empleado
      final empleado = empleadoProvider.empleados.firstWhere(
        (e) => e.cedula == _cedulaParaEliminar,
        orElse: () => Empleado(
          nombre: 'Desconocido',
          apellido: '',
          cedula: '',
          cargo: '',
          sedeId: '',
          areaId: '',
        ),
      );

      // Obtener asistencias filtradas
      final asistenciasFiltradas = await asistenciaProvider
          .getAsistenciasPorEmpleado(
        _cedulaParaEliminar!,
        areaId: _areaId,
      )
          .then((asistencias) {
        return asistencias.where((a) {
          final fechaAsistencia = DateTime(
              a.horaEntrada.year, a.horaEntrada.month, a.horaEntrada.day);
          return (fechaAsistencia.isAfter(fechaInicial) ||
                  fechaAsistencia.isAtSameMomentAs(fechaInicial)) &&
              (fechaAsistencia.isBefore(fechaFinal) ||
                  fechaAsistencia.isAtSameMomentAs(fechaFinal));
        }).toList();
      });

      if (asistenciasFiltradas.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'No se encontraron asistencias con los filtros aplicados')),
        );
        return;
      }

      // Mostrar diálogo de confirmación
      final confirmado = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirmar eliminación'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Empleado: ${empleado.nombre} ${empleado.apellido}'),
                  Text('Cédula: ${empleado.cedula}'),
                  const SizedBox(height: 10),
                  Text(
                      'Período: ${fechaInicialEliminarController.text} - ${fechaFinalEliminarController.text}'),
                  Text(
                      'Asistencias a eliminar: ${asistenciasFiltradas.length}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (confirmado) {
        for (final asistencia in asistenciasFiltradas) {
          await asistenciaProvider.eliminarAsistencia(asistencia.id!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${asistenciasFiltradas.length} asistencias eliminadas')),
        );

        setState(() {
          _cedulaParaEliminar = null;
          _filtroEliminarController.clear();
          fechaInicialEliminarController.clear();
          fechaFinalEliminarController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);
    final sedeProvider = Provider.of<SedeProvider>(context);
    final areaProvider = Provider.of<AreaProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return PinAuthScreen(
        moduleName: 'Reportes',
        destination: GenerarReporte(),
        areaId: areaProvider.areaActual?.id,
      );
    }

    if (sedeProvider.sedeActual == null) {
      return _buildNoSedeSelected(context);
    }

    if (areaProvider.areaActual == null) {
      return _buildNoAreaSelected(context);
    }

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Reportes - ${sedeProvider.sedeActual?.nombre ?? ''} - ${areaProvider.areaActual?.nombre ?? ''}',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.business),
            tooltip: 'Sede actual',
            onPressed: () {
              NotificationService.showInfo(
                  'Sede: ${sedeProvider.sedeActual?.nombre ?? 'No seleccionada'}\n'
                  'Área: ${areaProvider.areaActual?.nombre ?? 'No seleccionada'}');
            },
          ),
          if (authProvider.currentRole == 'admin')
            IconButton(
              icon: Icon(Icons.settings),
              onPressed: () {
                // Configuración avanzada de reportes para admins
              },
            ),
          if (authProvider.isAuthenticated)
            IconButton(
              icon: Icon(Icons.logout),
              onPressed: () async {
                await authProvider.logout();
                Navigator.pushReplacementNamed(context, '/seleccionar_sede');
              },
              tooltip: 'Cerrar sesión',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Primer bloque: Filtros y botones para generar reporte
            Container(
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green),
              ),
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Generar Reporte',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            if (_filtroSeleccionadoReporte == 'Fecha')
                              _buildRangoFechas(
                                fechaInicialReporteController,
                                fechaFinalReporteController,
                              )
                            else
                              TextFormField(
                                controller: _filtroReporteController,
                                decoration: InputDecoration(
                                  labelText: 'Ingrese el valor para filtrar',
                                  hintText: _filtroSeleccionadoReporte ==
                                          'Cédula'
                                      ? 'Ej: 123456789'
                                      : _filtroSeleccionadoReporte == 'Nombre'
                                          ? 'Ej: Juan Pérez'
                                          : 'Ej: Gerente',
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 20),
                      Column(
                        children: [
                          DropdownButton<String>(
                            value: _filtroSeleccionadoReporte,
                            onChanged: (String? nuevoValor) {
                              setState(() {
                                _filtroSeleccionadoReporte = nuevoValor!;
                                _filtroReporteController.clear();
                              });
                            },
                            items: <String>[
                              'Cédula',
                              'Nombre',
                              'Cargo',
                              'Fecha'
                            ].map<DropdownMenuItem<String>>((String valor) {
                              return DropdownMenuItem<String>(
                                value: valor,
                                child: Text(valor),
                              );
                            }).toList(),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: greenPalette[500],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: () async {
                              if (_filtroSeleccionadoReporte == 'Fecha') {
                                final fechaInicial =
                                    fechaInicialReporteController.text;
                                final fechaFinal =
                                    fechaFinalReporteController.text;

                                if (fechaInicial.isEmpty ||
                                    fechaFinal.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Por favor, ingresa ambas fechas')),
                                  );
                                  return;
                                }

                                _filtroReporteController.text =
                                    '$fechaInicial - $fechaFinal';
                              }

                              final filtro = _filtroReporteController.text;
                              final asistenciasFiltradas = _filtrarAsistencias(
                                empleadoProvider.empleados,
                                asistenciaProvider.asistencias,
                                _filtroSeleccionadoReporte,
                                filtro,
                              );

                              if (asistenciasFiltradas.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(
                                          'No se encontraron asistencias con el filtro aplicado')),
                                );
                              } else {
                                final filePath =
                                    await _generarExcel(asistenciasFiltradas);
                                await _abrirArchivo(filePath);
                              }
                            },
                            child: Text('Generar Reporte'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Sede: ${sedeProvider.sedeActual?.nombre ?? 'No seleccionada'}',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  Text(
                    'Área: ${areaProvider.areaActual?.nombre ?? 'No seleccionada'}',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            if (authProvider.currentRole == 'admin')
              // Segundo bloque: Eliminar asistencias
              Container(
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.green),
                ),
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Eliminar Asistencias',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 10),

                    // Selector de modo
                    Row(
                      children: [
                        const Text('Modo:'),
                        SizedBox(width: 4), // Reducir espacio
                        ChoiceChip(
                          label: const Text('Combinado'), // Texto más corto
                          selected: _modoEliminacionCombinada,
                          onSelected: (selected) {
                            setState(() {
                              _modoEliminacionCombinada = true;
                              _cedulaParaEliminar = null;
                              _filtroEliminarController.clear();
                            });
                          },
                        ),
                        SizedBox(width: 4), // Reducir espacio
                        ChoiceChip(
                          label: const Text('Individual'),
                          selected: !_modoEliminacionCombinada,
                          onSelected: (selected) {
                            setState(() {
                              _modoEliminacionCombinada = false;
                            });
                          },
                        ),
                      ],
                    ),

                    SizedBox(height: 10),

                    // Contenido condicional según el modo
                    if (_modoEliminacionCombinada) ...[
                      // Modo combinado (cedula + fechas)
                      TextFormField(
                        controller: _filtroEliminarController,
                        decoration: const InputDecoration(
                          labelText: 'Cédula del empleado',
                          hintText: 'Ej: 1234567890',
                        ),
                        onChanged: (value) =>
                            setState(() => _cedulaParaEliminar = value),
                      ),
                      SizedBox(height: 10),
                      _buildRangoFechas(
                        fechaInicialEliminarController,
                        fechaFinalEliminarController,
                      ),
                      SizedBox(height: 10),
                      if (_cedulaParaEliminar != null &&
                          _cedulaParaEliminar!.isNotEmpty)
                        Text(
                          'Filtrando por cédula: $_cedulaParaEliminar',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                    ] else ...[
                      // Modo individual (mantener lógica original)
                      DropdownButton<String>(
                        value: _filtroSeleccionadoEliminar,
                        onChanged: (String? nuevoValor) {
                          setState(() {
                            _filtroSeleccionadoEliminar = nuevoValor!;
                            _filtroEliminarController.clear();
                          });
                        },
                        items: <String>['Cédula', 'Nombre', 'Cargo', 'Fecha']
                            .map<DropdownMenuItem<String>>((String valor) {
                          return DropdownMenuItem<String>(
                            value: valor,
                            child: Text(valor),
                          );
                        }).toList(),
                      ),
                      SizedBox(height: 10),
                      if (_filtroSeleccionadoEliminar != 'Fecha')
                        TextFormField(
                          controller: _filtroEliminarController,
                          decoration: InputDecoration(
                            labelText: 'Ingrese el valor para filtrar',
                            hintText: _filtroSeleccionadoEliminar == 'Cédula'
                                ? 'Ej: 123456789'
                                : _filtroSeleccionadoEliminar == 'Nombre'
                                    ? 'Ej: Juan Pérez'
                                    : 'Ej: Gerente',
                          ),
                        ),
                      if (_filtroSeleccionadoEliminar == 'Fecha')
                        _buildRangoFechas(
                          fechaInicialEliminarController,
                          fechaFinalEliminarController,
                        ),
                    ],

                    SizedBox(height: 20),

                    // Botón de eliminación
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                        minimumSize: Size(double.infinity, 50),
                      ),
                      onPressed: _modoEliminacionCombinada
                          ? _eliminarAsistenciasCombinado
                          : () async {
                              if (_filtroSeleccionadoEliminar == 'Fecha') {
                                final fechaInicial =
                                    fechaInicialEliminarController.text;
                                final fechaFinal =
                                    fechaFinalEliminarController.text;

                                if (fechaInicial.isEmpty ||
                                    fechaFinal.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Por favor, ingresa ambas fechas')),
                                  );
                                  return;
                                }

                                final formatoEntrada = DateFormat('dd-MM-yyyy');
                                final fechaInicialDate =
                                    formatoEntrada.parse(fechaInicial);
                                final fechaFinalDate =
                                    formatoEntrada.parse(fechaFinal);

                                _asistenciasFiltradasParaEliminar =
                                    asistenciaProvider.asistencias.where((a) {
                                  final fechaAsistencia = a.horaEntrada;
                                  return (fechaAsistencia
                                              .isAfter(fechaInicialDate) ||
                                          fechaAsistencia.isAtSameMomentAs(
                                              fechaInicialDate)) &&
                                      (fechaAsistencia
                                              .isBefore(fechaFinalDate) ||
                                          fechaAsistencia.isAtSameMomentAs(
                                              fechaFinalDate));
                                }).toList();

                                await _mostrarDialogoConfirmacionEliminacion();
                              } else {
                                final filtro = _filtroEliminarController.text;
                                if (filtro.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Ingrese un valor para filtrar')),
                                  );
                                  return;
                                }
                                await _eliminarPorFiltroIndividual();
                              }
                            },
                      child: const Text('ELIMINAR ASISTENCIAS',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Se requieren permisos de administrador para eliminar asistencias',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDialogoConfirmacionEliminacion() async {
    final confirmado = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text(
                '¿Estás seguro de eliminar ${_asistenciasFiltradasParaEliminar.length} asistencias?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child:
                    const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ) ??
        false;

    if (confirmado) {
      final asistenciaProvider =
          Provider.of<AsistenciaProvider>(context, listen: false);
      for (final asistencia in _asistenciasFiltradasParaEliminar) {
        await asistenciaProvider.eliminarAsistencia(asistencia.id!);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${_asistenciasFiltradasParaEliminar.length} asistencias eliminadas')),
      );

      setState(() {
        _asistenciasFiltradasParaEliminar = [];
      });
    }
  }

  Future<void> _eliminarPorFiltroIndividual() async {
    final asistenciaProvider =
        Provider.of<AsistenciaProvider>(context, listen: false);
    final empleadoProvider =
        Provider.of<EmpleadoProvider>(context, listen: false);
    final filtro = _filtroEliminarController.text;

    try {
      List<Asistencia> asistenciasAEliminar = [];

      if (_filtroSeleccionadoEliminar == 'Cédula') {
        asistenciasAEliminar =
            await asistenciaProvider.getAsistenciasPorEmpleado(
          filtro,
          areaId: _areaId,
        );
      } else {
        // Para otros filtros (Nombre, Cargo), primero buscamos los empleados que coincidan
        final empleadosFiltrados = empleadoProvider.empleados.where((empleado) {
          if (_filtroSeleccionadoEliminar == 'Nombre') {
            final nombreCompleto = '${empleado.nombre} ${empleado.apellido}';
            return nombreCompleto.toLowerCase().contains(filtro.toLowerCase());
          } else if (_filtroSeleccionadoEliminar == 'Cargo') {
            return empleado.cargo.toLowerCase().contains(filtro.toLowerCase());
          }
          return false;
        }).toList();

        // Obtenemos las asistencias de esos empleados
        for (final empleado in empleadosFiltrados) {
          final asistencias =
              await asistenciaProvider.getAsistenciasPorEmpleado(
            empleado.cedula,
            areaId: _areaId,
          );
          asistenciasAEliminar.addAll(asistencias);
        }
      }

      if (asistenciasAEliminar.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No se encontraron asistencias para eliminar')),
        );
        return;
      }

      final confirmado = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirmar eliminación'),
              content: Text(
                  '¿Estás seguro de eliminar ${asistenciasAEliminar.length} asistencias?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ) ??
          false;

      if (confirmado) {
        for (final asistencia in asistenciasAEliminar) {
          await asistenciaProvider.eliminarAsistencia(asistencia.id!);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${asistenciasAEliminar.length} asistencias eliminadas')),
        );

        setState(() {
          _filtroEliminarController.clear();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar: $e')),
      );
    }
  }

  Widget _buildRangoFechas(TextEditingController fechaInicialController,
      TextEditingController fechaFinalController) {
    return Column(
      children: [
        TextFormField(
          controller: fechaInicialController,
          decoration: InputDecoration(
            labelText: 'Fecha inicial (dd-MM-yyyy)',
            hintText: 'Ej: 25-02-2023',
          ),
          onTap: () async {
            final fecha = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (fecha != null) {
              fechaInicialController.text =
                  DateFormat('dd-MM-yyyy').format(fecha);
            }
          },
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: fechaFinalController,
          decoration: InputDecoration(
            labelText: 'Fecha final (dd-MM-yyyy)',
            hintText: 'Ej: 01-05-2025',
          ),
          onTap: () async {
            final fecha = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (fecha != null) {
              fechaFinalController.text =
                  DateFormat('dd-MM-yyyy').format(fecha);
            }
          },
        ),
      ],
    );
  }

  List<Map<String, dynamic>> _filtrarAsistencias(
    List<Empleado> empleados,
    List<Asistencia> asistencias,
    String filtro,
    String valor,
  ) {
    return asistencias.map((asistencia) {
      final empleado = empleados.firstWhere(
        (emp) => emp.cedula == asistencia.cedulaEmpleado,
        orElse: () => Empleado(
          nombre: '',
          apellido: '',
          cedula: '',
          cargo: '',
          sedeId: '',
          areaId: '',
        ),
      );

      return {
        'nombre': '${empleado.nombre} ${empleado.apellido}',
        'cedula': empleado.cedula,
        'cargo': empleado.cargo,
        'horaEntrada': asistencia.horaEntrada,
        'horaSalida': asistencia.horaSalida,
        'atrasoEntrada': asistencia.atrasoEntrada,
        'atrasoSalida': asistencia.atrasoSalida,
        'llevaTarjetas': asistencia.llevaTarjetas,
        'observaciones': asistencia.observaciones,
        'sedeId': asistencia.sedeId,
        'areaId': asistencia.areaId,
      };
    }).where((asistencia) {
      // Filtro por sede y área actual
      if (asistencia['sedeId'] != _sedeId || asistencia['areaId'] != _areaId) {
        return false;
      }

      switch (filtro) {
        case 'Cédula':
          return asistencia['cedula'] == valor;
        case 'Nombre':
          final nombre = (asistencia['nombre'] as String?)?.toLowerCase() ?? '';
          return nombre.contains(valor.toLowerCase());
        case 'Cargo':
          final cargo = (asistencia['cargo'] as String?)?.toLowerCase() ?? '';
          return cargo.contains(valor.toLowerCase());
        case 'Fecha':
          final fecha = asistencia['horaEntrada'].toString().split(' ')[0];
          return _estaEnRangoFechas(fecha, valor);
        default:
          return false;
      }
    }).toList();
  }

  bool _estaEnRangoFechas(String fechaAsistencia, String rango) {
    try {
      final partes = rango.split(' - ');
      if (partes.length != 2) return false;

      final formatoEntrada = DateFormat('dd-MM-yyyy');
      final fechaInicial = formatoEntrada.parse(partes[0]);
      final fechaFinal = formatoEntrada.parse(partes[1]);

      final fechaAsistenciaDate =
          DateFormat('yyyy-MM-dd').parse(fechaAsistencia);

      return fechaAsistenciaDate.isAfter(fechaInicial) ||
          fechaAsistenciaDate.isAtSameMomentAs(fechaInicial) &&
              (fechaAsistenciaDate.isBefore(fechaFinal) ||
                  fechaAsistenciaDate.isAtSameMomentAs(fechaFinal));
    } catch (e) {
      print("Error en el filtro de fechas: $e");
      return false;
    }
  }

  Future<String> _generarExcel(List<Map<String, dynamic>> asistencias) async {
    final excelFile = excel.Excel.createExcel();
    final sheet = excelFile['Asistencias'];
    final empleadoProvider =
        Provider.of<EmpleadoProvider>(context, listen: false);

    // Obtener empleados en vacaciones en el rango de fechas
    final empleadosVacaciones = empleadoProvider.empleados.where((emp) {
      return emp.enVacaciones &&
          emp.fechaInicioEstado != null &&
          emp.fechaFinEstado != null &&
          ((_filtroSeleccionadoReporte != 'Fecha') ||
              (_estaEnRangoVacaciones(
                  emp.fechaInicioEstado!, emp.fechaFinEstado!)));
    }).toList();

    // Encabezados
    sheet.appendRow([
      'Nombre',
      'Cédula',
      'Cargo',
      'Hora Entrada',
      'Hora Salida',
      'Atrasos',
      'Llevar Tarjetas',
      'Observaciones',
      'Área'
    ]);

    // Datos de asistencias
    asistencias.forEach((asistencia) {
      sheet.appendRow([
        asistencia['nombre'],
        asistencia['cedula'],
        asistencia['cargo'],
        DateFormat('hh:mm a').format(asistencia['horaEntrada']),
        asistencia['horaSalida'] != null
            ? DateFormat('hh:mm a').format(asistencia['horaSalida'])
            : 'No registrada',
        (asistencia['atrasoEntrada'] || asistencia['atrasoSalida'])
            ? 'Sí'
            : 'No',
        asistencia['llevaTarjetas'] ? 'Sí' : 'No',
        asistencia['observaciones'] ?? '',
        asistencia['areaId'] ?? '',
      ]);
    });

    // Hoja de vacaciones
    if (empleadosVacaciones.isNotEmpty) {
      final vacacionesSheet = excelFile['Vacaciones'];
      vacacionesSheet.appendRow(
          ['Nombre', 'Cédula', 'Cargo', 'Fecha Inicio', 'Fecha Fin', 'Días']);

      empleadosVacaciones.forEach((emp) {
        vacacionesSheet.appendRow([
          '${emp.nombre} ${emp.apellido}',
          emp.cedula,
          emp.cargo,
          DateFormat('dd/MM/yyyy').format(emp.fechaInicioEstado!),
          DateFormat('dd/MM/yyyy').format(emp.fechaFinEstado!),
          emp.fechaFinEstado!.difference(emp.fechaInicioEstado!).inDays
        ]);
      });
    }

    // Guardar el archivo
    final directory = await getApplicationDocumentsDirectory();
    final filePath =
        '${directory.path}/reporte_asistencias_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excelFile.encode()!);

    return filePath;
  }

  bool _estaEnRangoVacaciones(DateTime inicio, DateTime fin) {
    if (_filtroSeleccionadoReporte != 'Fecha') return true;

    try {
      final partes = _filtroReporteController.text.split(' - ');
      if (partes.length != 2) return false;

      final formatoEntrada = DateFormat('dd-MM-yyyy');
      final fechaInicial = formatoEntrada.parse(partes[0]);
      final fechaFinal = formatoEntrada.parse(partes[1]);

      return (inicio.isBefore(fechaFinal) && fin.isAfter(fechaInicial));
    } catch (e) {
      return false;
    }
  }

  Future<void> _abrirArchivo(String filePath) async {
    final result = await OpenFile.open(filePath);
    print(result.message);
  }

  Widget _buildNoSedeSelected(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.business, size: 64, color: greenPalette[500]),
          SizedBox(height: 20),
          Text(
            'No se ha seleccionado sede',
            style: TextStyle(
              fontSize: 18,
              color: greenPalette[700],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/seleccionar_sede');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: greenPalette[500],
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
          Icon(Icons.work_outline, size: 64, color: greenPalette[500]),
          SizedBox(height: 20),
          Text(
            'No se ha seleccionado área',
            style: TextStyle(
              fontSize: 18,
              color: greenPalette[700],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/seleccionar_area');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: greenPalette[500],
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
