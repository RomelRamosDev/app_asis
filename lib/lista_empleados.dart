import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'empleado_model.dart';
import 'empleado_provider.dart';
import 'sede_provider.dart';
import 'area_provider.dart';
import 'area_model.dart';
import 'main.dart';
import 'themes.dart';
import 'auth_provider.dart';
import 'pin_auth_screen.dart';

class ListaEmpleados extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final sedeProvider = Provider.of<SedeProvider>(context);
    final areaProvider = Provider.of<AreaProvider>(context);
    final empleadoProvider = Provider.of<EmpleadoProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    if (!authProvider.isAuthenticated) {
      return PinAuthScreen(
        moduleName: 'Empleados',
        destination: ListaEmpleados(),
        areaId: areaProvider.areaActual?.id,
      );
    }

    if (sedeProvider.sedeActual == null) {
      return _buildNoSedeSelected(context);
    }

    if (areaProvider.areaActual == null) {
      return _buildNoAreaSelected(context);
    }
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
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (authProvider.currentRole == 'admin')
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        Navigator.pushNamed(context, '/empleado_form');
                      },
                      tooltip: 'Agregar nuevo empleado',
                    ),
                  if (authProvider.isAuthenticated)
                    IconButton(
                      icon: Icon(Icons.logout),
                      onPressed: () async {
                        await authProvider.logout();
                        Navigator.pushReplacementNamed(
                            context, '/seleccionar_sede');
                      },
                      tooltip: 'Cerrar sesión',
                    ),
                ],
              );
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
      floatingActionButton:
          sedeProvider.sedeActual != null && authProvider.currentRole == 'admin'
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
              if (empleado.enVacaciones || empleado.enPermisoMedico) ...[
                SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    if (empleado.enVacaciones)
                      Chip(
                        label: Text('EN VACACIONES',
                            style: TextStyle(fontSize: 12)),
                        backgroundColor: Colors.blue[100],
                      ),
                    if (empleado.enPermisoMedico)
                      Chip(
                        label: Text('PERMISO MÉDICO',
                            style: TextStyle(fontSize: 12)),
                        backgroundColor: Colors.orange[100],
                      ),
                  ],
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
