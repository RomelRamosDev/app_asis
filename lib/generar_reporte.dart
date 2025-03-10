import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'dart:io';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'aistencia_model.dart';
import 'asistencia_provider.dart';

class GenerarReporte extends StatefulWidget {
  @override
  _GenerarReporteState createState() => _GenerarReporteState();
}

class _GenerarReporteState extends State<GenerarReporte> {
  final _filtroController = TextEditingController();
  String _filtroSeleccionado = 'Cédula'; // Filtro predeterminado

  @override
  Widget build(BuildContext context) {
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final asistenciaProvider = Provider.of<AsistenciaProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Generar Reporte de Asistencias'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _filtroSeleccionado,
              onChanged: (String? nuevoValor) {
                setState(() {
                  _filtroSeleccionado = nuevoValor!;
                  _filtroController
                      .clear(); // Borrar el contenido del campo de texto
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
            if (_filtroSeleccionado == 'Fecha')
              _buildRangoFechas() // Mostrar campos de rango de fechas
            else
              TextFormField(
                controller: _filtroController,
                decoration: InputDecoration(
                  labelText: 'Ingrese el valor para filtrar',
                  hintText: _filtroSeleccionado == 'Cédula'
                      ? 'Ej: 123456789'
                      : _filtroSeleccionado == 'Nombre'
                          ? 'Ej: Juan Pérez'
                          : 'Ej: Gerente',
                ),
              ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final filtro = _filtroController.text;
                final asistenciasFiltradas = _filtrarAsistencias(
                  empleadoProvider.empleados,
                  asistenciaProvider.asistencias,
                  _filtroSeleccionado,
                  filtro,
                );

                if (asistenciasFiltradas.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'No se encontraron asistencias con el filtro aplicado')),
                  );
                } else {
                  final filePath = await _generarExcel(asistenciasFiltradas);
                  await _abrirArchivo(filePath);
                }
              },
              child: Text('Generar Reporte'),
            ),
          ],
        ),
      ),
    );
  }

  // Método para construir los campos de rango de fechas
  Widget _buildRangoFechas() {
    return Column(
      children: [
        TextFormField(
          controller: _filtroController,
          decoration: InputDecoration(
            labelText: 'Fecha inicial (dd-MM-yyyy)',
            hintText: 'Ej: 25-02-2023',
          ),
        ),
        SizedBox(height: 10),
        TextFormField(
          decoration: InputDecoration(
            labelText: 'Fecha final (dd-MM-yyyy)',
            hintText: 'Ej: 01-05-2025',
          ),
          onChanged: (value) {
            // Aquí puedes capturar la fecha final si es necesario
          },
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
  bool _estaEnRangoFechas(String fecha, String rango) {
    final partes = rango.split(' - ');
    if (partes.length != 2) return false;

    final fechaInicial = DateTime.parse(partes[0]);
    final fechaFinal = DateTime.parse(partes[1]);
    final fechaActual = DateTime.parse(fecha);

    return fechaActual.isAfter(fechaInicial) &&
        fechaActual.isBefore(fechaFinal);
  }

  // Método para generar el archivo Excel
  Future<String> _generarExcel(List<Map<String, dynamic>> asistencias) async {
    final excel = Excel.createExcel();
    final sheet = excel['Asistencias'];

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
    await file.writeAsBytes(excel.encode()!);

    return filePath;
  }

  // Método para abrir el archivo generado
  Future<void> _abrirArchivo(String filePath) async {
    final result = await OpenFile.open(filePath);
    print(result.message); // Muestra el resultado de la operación
  }
}
