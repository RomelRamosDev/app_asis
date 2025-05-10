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

  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);
    final sedeProvider = Provider.of<SedeProvider>(context);
    final areaProvider = Provider.of<AreaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Generar Reporte de Asistencias'),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  DropdownButton<String>(
                    value: _filtroSeleccionadoEliminar,
                    onChanged: (String? nuevoValor) {
                      setState(() {
                        _filtroSeleccionadoEliminar = nuevoValor!;
                        _filtroEliminarController.clear();
                        _cedulaParaEliminar = null;
                        _asistenciasFiltradasParaEliminar = [];
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
                      onChanged: (value) {
                        if (_filtroSeleccionadoEliminar == 'Cédula') {
                          setState(() {
                            _cedulaParaEliminar = value;
                          });
                        }
                      },
                    ),
                  if (_cedulaParaEliminar != null &&
                      _cedulaParaEliminar!.isNotEmpty)
                    Column(
                      children: [
                        SizedBox(height: 10),
                        Text('Filtrando por cédula: $_cedulaParaEliminar'),
                      ],
                    ),
                  if (_filtroSeleccionadoEliminar == 'Fecha')
                    _buildRangoFechas(
                      fechaInicialEliminarController,
                      fechaFinalEliminarController,
                    ),
                  SizedBox(height: 10),
                  if (_asistenciasFiltradasParaEliminar.isNotEmpty)
                    Text(
                      '${_asistenciasFiltradasParaEliminar.length} asistencias encontradas',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  SizedBox(height: 10),
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
                      if (_filtroSeleccionadoEliminar == 'Fecha') {
                        final fechaInicial =
                            fechaInicialEliminarController.text;
                        final fechaFinal = fechaFinalEliminarController.text;

                        if (fechaInicial.isEmpty || fechaFinal.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content:
                                    Text('Por favor, ingresa ambas fechas')),
                          );
                          return;
                        }

                        final formatoEntrada = DateFormat('dd-MM-yyyy');
                        final fechaInicialDate =
                            formatoEntrada.parse(fechaInicial);
                        final fechaFinalDate = formatoEntrada.parse(fechaFinal);

                        if (_cedulaParaEliminar == null &&
                            _filtroSeleccionadoEliminar != 'Cédula') {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                                content: Text(
                                    'Primero filtra por cédula/nombre/cargo')),
                          );
                          return;
                        }

                        // Filtrar asistencias
                        _asistenciasFiltradasParaEliminar =
                            asistenciaProvider.asistencias.where((a) {
                          final cumpleCedula = _cedulaParaEliminar == null ||
                              a.cedulaEmpleado == _cedulaParaEliminar;
                          final cumpleFecha =
                              a.horaEntrada.isAfter(fechaInicialDate) &&
                                  a.horaEntrada.isBefore(fechaFinalDate);
                          final cumpleSede = a.sedeId == _sedeId;
                          final cumpleArea = a.areaId == _areaId;

                          return cumpleCedula &&
                              cumpleFecha &&
                              cumpleSede &&
                              cumpleArea;
                        }).toList();

                        // Mostrar diálogo de confirmación
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Confirmar eliminación'),
                            content: Text(
                                '¿Eliminar ${_asistenciasFiltradasParaEliminar.length} asistencias?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  for (final asistencia
                                      in _asistenciasFiltradasParaEliminar) {
                                    await asistenciaProvider
                                        .eliminarAsistencia(asistencia.id!);
                                  }
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Asistencias eliminadas correctamente')),
                                  );
                                  setState(() {
                                    _asistenciasFiltradasParaEliminar = [];
                                  });
                                },
                                child: Text('Eliminar',
                                    style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      } else {
                        // Lógica para otros filtros (similar a la original)
                        final filtro = _filtroEliminarController.text;
                        if (_filtroSeleccionadoEliminar == 'Cédula') {
                          await asistenciaProvider
                              .eliminarAsistenciasPorCedula(filtro);
                        } else if (_filtroSeleccionadoEliminar == 'Nombre') {
                          final empleado =
                              empleadoProvider.empleados.firstWhere(
                            (emp) => emp.nombre
                                .toLowerCase()
                                .contains(filtro.toLowerCase()),
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
                            await asistenciaProvider
                                .eliminarAsistenciasPorCedula(empleado.cedula);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Empleado no encontrado')),
                            );
                            return;
                          }
                        } else if (_filtroSeleccionadoEliminar == 'Cargo') {
                          final empleadosFiltrados = empleadoProvider.empleados
                              .where((emp) => emp.cargo
                                  .toLowerCase()
                                  .contains(filtro.toLowerCase()))
                              .toList();

                          if (empleadosFiltrados.isNotEmpty) {
                            for (final empleado in empleadosFiltrados) {
                              await asistenciaProvider
                                  .eliminarAsistenciasPorCedula(
                                      empleado.cedula);
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'No se encontraron empleados con ese cargo')),
                            );
                            return;
                          }
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Asistencias eliminadas correctamente')),
                        );
                      }
                    },
                    child: Text('Eliminar Asistencias'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
}
