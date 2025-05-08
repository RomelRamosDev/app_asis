import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'sede_provider.dart';
import 'area_provider.dart';
import 'area_model.dart';
import 'main.dart';
import 'themes.dart';

class ListaEmpleados extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sedeProvider = Provider.of<SedeProvider>(context);
    final areaProvider = Provider.of<AreaProvider>(context);
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);

    // Filtrar empleados por sede y área actual
    final empleados = empleadoProvider.empleados.where((empleado) {
      final cumpleSede = empleado.sedeId == sedeProvider.sedeActual?.id;
      final cumpleArea = areaProvider.areaActual == null ||
          empleado.areaId == areaProvider.areaActual?.id;
      return cumpleSede && cumpleArea;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Empleados - ${sedeProvider.sedeActual?.nombre ?? 'Sin sede'}'),
        actions: [
          // Mostrar área actual
          IconButton(
            icon: Tooltip(
              child: Icon(Icons.work_outline),
              message: 'Área: ${areaProvider.areaActual?.nombre ?? 'Todas'}',
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Sede: ${sedeProvider.sedeActual?.nombre ?? 'No seleccionada'}\n'
                      'Área: ${areaProvider.areaActual?.nombre ?? 'Todas'}'),
                ),
              );
            },
          ),
          // Botón para cambiar sede
          IconButton(
            icon: Icon(Icons.business),
            tooltip: 'Cambiar sede',
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/seleccionar_sede');
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (sedeProvider.sedeActual == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey),
                  SizedBox(height: 20),
                  Text('No se ha seleccionado sede',
                      style: TextStyle(fontSize: 18)),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                          context, '/seleccionar_sede');
                    },
                    child: Text('Seleccionar sede'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await empleadoProvider.cargarEmpleados();
            },
            child: empleados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          areaProvider.areaActual == null
                              ? 'No hay empleados en esta sede'
                              : 'No hay empleados en esta área',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: empleados.length,
                    itemBuilder: (context, index) {
                      final empleado = empleados[index];
                      return _buildEmpleadoItem(
                          context, empleado, empleadoProvider, areaProvider);
                    },
                  ),
          );
        },
      ),
      floatingActionButton: sedeProvider.sedeActual != null
          ? FloatingActionButton(
              onPressed: () {
                Navigator.pushNamed(context, '/empleado_form');
              },
              child: Icon(Icons.add),
              tooltip: 'Agregar nuevo empleado',
            )
          : null,
    );
  }

  Widget _buildEmpleadoItem(BuildContext context, Empleado empleado,
      EmpleadoProvider empleadoProvider, AreaProvider areaProvider) {
    final areaEmpleado = areaProvider.areas.firstWhere(
      (a) => a.id == empleado.areaId,
      orElse: () => Area(id: '', nombre: 'Sin área', sedeId: ''),
    );

    return Dismissible(
      key: Key(empleado.id!),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Icon(Icons.delete, color: Colors.white),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Eliminar empleado'),
            content: Text(
                '¿Estás seguro de eliminar a ${empleado.nombre} ${empleado.apellido}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        empleadoProvider.eliminarEmpleado(empleado.id!);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Empleado eliminado: ${empleado.nombre}'),
            action: SnackBarAction(
              label: 'Deshacer',
              onPressed: () {
                // Implementar lógica para recuperar empleado si es necesario
              },
            ),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: ListTile(
          title: Text('${empleado.nombre} ${empleado.apellido}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cédula: ${empleado.cedula}'),
              Text('Cargo: ${empleado.cargo}'),
              Text('Área: ${areaEmpleado.nombre}'),
              if (empleado.enVacaciones) ...[
                SizedBox(height: 4),
                Chip(
                  label: Text('EN VACACIONES', style: TextStyle(fontSize: 12)),
                  backgroundColor: Colors.blue[100],
                ),
              ],
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/empleado_form',
                    arguments: empleado,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
