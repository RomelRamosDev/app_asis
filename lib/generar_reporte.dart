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

class GenerarReporte extends StatefulWidget {
  @override
  _GenerarReporteState createState() => _GenerarReporteState();
}

class _GenerarReporteState extends State<GenerarReporte> {
  final _filtroReporteController =
      TextEditingController(); // Controlador para el reporte
  final _filtroEliminarController =
      TextEditingController(); // Controlador para eliminar
  String _filtroSeleccionadoReporte =
      'Cédula'; // Filtro predeterminado para el reporte
  String _filtroSeleccionadoEliminar =
      'Cédula'; // Filtro predeterminado para eliminar
  final fechaInicialReporteController = TextEditingController();
  final fechaFinalReporteController = TextEditingController();
  final fechaInicialEliminarController = TextEditingController();
  final fechaFinalEliminarController = TextEditingController();
  bool _filtrarPorAtrasos = false; // Nuevo filtro para atrasos
  bool _filtrarPorTarjetas = false; // Nuevo filtro para llevar tarjetas

  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Generar Reporte de Asistencias'),
      ),
      body: SingleChildScrollView(
        // Evitar desbordamiento
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Primer bloque: Filtros y botones para generar reporte
            Container(
              decoration: BoxDecoration(
                color: Colors.green[50], // Fondo verde claro
                borderRadius: BorderRadius.circular(10), // Bordes redondeados
                border: Border.all(color: Colors.green),
              ), // Borde verde
              padding: EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Columna izquierda: Campos de entrada
                  Expanded(
                    child: Column(
                      children: [
                        if (_filtroSeleccionadoReporte == 'Fecha')
                          _buildRangoFechas(fechaInicialReporteController,
                              fechaFinalReporteController) // Mostrar campos de rango de fechas
                        else
                          TextFormField(
                            controller: _filtroReporteController,
                            decoration: InputDecoration(
                              labelStyle: const TextStyle(fontSize: 12.5),
                              labelText: 'Ingrese el valor para filtrar',
                              hintText: _filtroSeleccionadoReporte == 'Cédula'
                                  ? 'Ej: 123456789'
                                  : _filtroSeleccionadoReporte == 'Nombre'
                                      ? 'Ej: Juan Pérez'
                                      : 'Ej: Gerente',
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20), // Espacio entre columnas
                  // Columna derecha: Botones
                  Column(
                    children: [
                      DropdownButton<String>(
                        value: _filtroSeleccionadoReporte,
                        onChanged: (String? nuevoValor) {
                          setState(() {
                            _filtroSeleccionadoReporte = nuevoValor!;
                            _filtroReporteController
                                .clear(); // Borrar el campo de texto
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
                      SizedBox(height: 20),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenPalette[
                              500], // Color de fondo del botón (antes primary)
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
                            final fechaFinal = fechaFinalReporteController.text;

                            if (fechaInicial.isEmpty || fechaFinal.isEmpty) {
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
            ),
            SizedBox(height: 20), // Espacio para el segundo bloque
            // Segundo bloque: Eliminar asistencias
            Container(
              decoration: BoxDecoration(
                color: Colors.green[50], // Fondo verde claro
                borderRadius: BorderRadius.circular(10), // Bordes redondeados
                border: Border.all(color: Colors.green), // Borde verde
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
                        _filtroEliminarController
                            .clear(); // Borrar el campo de texto
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
                  if (_filtroSeleccionadoEliminar == 'Fecha')
                    _buildRangoFechas(fechaInicialEliminarController,
                        fechaFinalEliminarController) // Mostrar campos de rango de fechas
                  else
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
                  SizedBox(height: 20),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: greenPalette[
                          500], // Color de fondo del botón (antes primary)
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

                        await asistenciaProvider.eliminarAsistenciasPorFecha(
                            fechaInicialDate, fechaFinalDate);
                      } else {
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
                      }

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Asistencias eliminadas correctamente')),
                      );
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

  // Método para construir los campos de rango de fechas
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
        ),
        SizedBox(height: 10),
        TextFormField(
          controller: fechaFinalController,
          decoration: InputDecoration(
            labelText: 'Fecha final (dd-MM-yyyy)',
            hintText: 'Ej: 01-05-2025',
          ),
        ),
      ],
    );
  }

  // Método para filtrar asistencias
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
        ),
      );

      return {
        'nombre': '${empleado.nombre} ${empleado.apellido}',
        'cedula': empleado.cedula,
        'cargo': empleado.cargo,
        'horaEntrada': asistencia.horaEntrada,
        'horaSalida': asistencia.horaSalida,
      };
    }).where((asistencia) {
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

  // Método para verificar si una fecha está en un rango
  bool _estaEnRangoFechas(String fechaAsistencia, String rango) {
    try {
      final partes = rango.split(' - ');
      if (partes.length != 2) return false;

      final formatoEntrada = DateFormat('dd-MM-yyyy');
      final fechaInicial = formatoEntrada.parse(partes[0]);
      final fechaFinal = formatoEntrada.parse(partes[1]);

      // Convertir la fecha de la asistencia a `DateTime`
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

  // Método para generar el archivo Excel
  Future<String> _generarExcel(List<Map<String, dynamic>> asistencias) async {
    final excelFile = excel.Excel.createExcel(); // Usar 'excel.' como prefijo
    final sheet = excelFile['Asistencias'];

    // Encabezados
    sheet.appendRow(
        ['Nombre', 'Cédula', 'Cargo', 'Hora Entrada', 'Hora Salida']);

    // Datos
    asistencias.forEach((asistencia) {
      sheet.appendRow([
        asistencia['nombre'],
        asistencia['cedula'],
        asistencia['cargo'],
        asistencia['horaEntrada'].toString(),
        asistencia['horaSalida']?.toString() ?? 'No registrada',
      ]);
    });

    // Guardar el archivo
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/reporte_asistencias.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excelFile.encode()!);

    return filePath;
  }

  // Método para abrir el archivo generado
  Future<void> _abrirArchivo(String filePath) async {
    final result = await OpenFile.open(filePath);
    print(result.message); // Muestra el resultado de la operación
  }
}
