import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'main.dart';
import 'sede_provider.dart';

class ListaEmpleados extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sedeActual = Provider.of<SedeProvider>(context).sedeActual;
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);

    // Filtrar empleados por la sede actual
    final empleados = empleadoProvider.empleados
        .where((empleado) => empleado.sedeId == sedeActual?.id)
        .toList();

    print('Empleados filtrados: ${empleados.length}');

    return Scaffold(
      appBar: AppBar(
        title: Text('Empleados - ${sedeActual?.nombre ?? 'Sin sede'}'),
        actions: [
          IconButton(
            icon: Icon(Icons.business),
            tooltip: 'Sede actual',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Sede actual: ${sedeActual?.nombre ?? 'No seleccionada'}'),
                ),
              );
            },
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (sedeActual == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No se ha seleccionado sede',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
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

          if (empleados.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No hay empleados en esta sede',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: empleados.length,
            itemBuilder: (context, index) {
              final empleado = empleados[index];
              return _buildEmpleadoItem(context, empleado, empleadoProvider);
            },
          );
        },
      ),
      floatingActionButton: sedeActual != null
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
      EmpleadoProvider empleadoProvider) {
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
