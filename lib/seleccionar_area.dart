import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_asis/area_model.dart';
import 'package:app_asis/area_provider.dart';
import 'package:app_asis/sede_provider.dart';
import 'package:app_asis/home_navigation.dart';
import 'package:app_asis/themes.dart';
import 'package:uuid/uuid.dart';

class SeleccionarAreaScreen extends StatefulWidget {
  @override
  _SeleccionarAreaScreenState createState() => _SeleccionarAreaScreenState();
}

class _SeleccionarAreaScreenState extends State<SeleccionarAreaScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _mostrarFormulario = false;
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _cargoController = TextEditingController();
  List<String> _cargos = [];

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _cargoController.dispose();
    super.dispose();
  }

  void _agregarCargo() {
    if (_cargoController.text.isNotEmpty) {
      setState(() {
        _cargos.add(_cargoController.text);
        _cargoController.clear();
      });
    }
  }

  void _eliminarCargo(int index) {
    setState(() {
      _cargos.removeAt(index);
    });
  }

  Future<void> _guardarArea() async {
    if (_formKey.currentState!.validate() && _cargos.isNotEmpty) {
      final areaProvider = Provider.of<AreaProvider>(context, listen: false);
      final sedeProvider = Provider.of<SedeProvider>(context, listen: false);
      final uuid = Uuid(); // Instancia de Uuid

      final nuevaArea = Area(
        id: uuid.v4(), // Genera un UUID válido
        nombre: _nombreController.text,
        sedeId: sedeProvider.sedeActual!.id,
        descripcion: _descripcionController.text,
        cargos: _cargos,
      );

      await areaProvider.agregarArea(nuevaArea);

      setState(() {
        _nombreController.clear();
        _descripcionController.clear();
        _cargoController.clear();
        _cargos.clear();
        _mostrarFormulario = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Área creada exitosamente')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Debe agregar al menos un cargo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final sedeProvider = Provider.of<SedeProvider>(context);
    final areaProvider = Provider.of<AreaProvider>(context);
    final areas = areaProvider.areas
        .where((area) => area.sedeId == sedeProvider.sedeActual?.id)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Áreas - ${sedeProvider.sedeActual?.nombre ?? ''}'),
        actions: [
          IconButton(
            icon: Icon(_mostrarFormulario ? Icons.close : Icons.add),
            onPressed: () {
              setState(() {
                _mostrarFormulario = !_mostrarFormulario;
                if (!_mostrarFormulario) {
                  _nombreController.clear();
                  _descripcionController.clear();
                  _cargoController.clear();
                  _cargos.clear();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_mostrarFormulario) _buildFormularioArea(),
          Expanded(
            child: areas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.work_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No hay áreas disponibles',
                          style: TextStyle(fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _mostrarFormulario = true;
                            });
                          },
                          child: Text('Crear primera área'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: EdgeInsets.all(16),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: areas.length,
                    itemBuilder: (context, index) {
                      final area = areas[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            areaProvider.seleccionarArea(area);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => HomeNavigation()),
                            );
                          },
                          child: Container(
                            constraints: const BoxConstraints(
                              minHeight:
                                  150, // Altura mínima para todas las cards
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  greenPalette[100]!,
                                  greenPalette[300]!,
                                ],
                              ),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.work_outline,
                                    size: 48,
                                    color: greenPalette[800],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    area.nombre,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: greenPalette[900],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2, // Limita a 2 líneas
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (area.cargos != null &&
                                      area.cargos!.isNotEmpty)
                                    Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Container(
                                        constraints: BoxConstraints(
                                          maxHeight:
                                              60, // Altura máxima para la lista de cargos
                                        ),
                                        child: SingleChildScrollView(
                                          // Permite scroll si hay muchos cargos
                                          physics:
                                              AlwaysScrollableScrollPhysics(),
                                          child: Wrap(
                                            spacing: 4,
                                            runSpacing: 4,
                                            alignment: WrapAlignment.center,
                                            children: area.cargos!
                                                .take(
                                                    3) // Mostrar máximo 3 cargos inicialmente
                                                .map((cargo) => Chip(
                                                      label: Text(
                                                        cargo,
                                                        style: TextStyle(
                                                            fontSize: 10),
                                                      ),
                                                      backgroundColor:
                                                          Colors.green[100],
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (area.cargos != null &&
                                      area.cargos!.length > 3)
                                    Text(
                                      '+${area.cargos!.length - 3} más',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: greenPalette[700],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormularioArea() {
    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nueva Área',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: greenPalette[800],
                ),
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _nombreController,
                decoration: InputDecoration(
                  labelText: 'Nombre del área',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Ingrese un nombre para el área';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _descripcionController,
                decoration: InputDecoration(
                  labelText: 'Descripción (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              SizedBox(height: 16),
              Text(
                'Cargos del área:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              if (_cargos.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: List.generate(
                    _cargos.length,
                    (index) => Chip(
                      label: Text(_cargos[index]),
                      onDeleted: () => _eliminarCargo(index),
                      deleteIconColor: Colors.red,
                    ),
                  ),
                ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cargoController,
                      decoration: InputDecoration(
                        labelText: 'Agregar cargo',
                        border: OutlineInputBorder(),
                      ),
                      onFieldSubmitted: (_) => _agregarCargo(),
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _agregarCargo,
                    style: ElevatedButton.styleFrom(
                      shape: CircleBorder(),
                      padding: EdgeInsets.all(16),
                    ),
                    child: Icon(Icons.add),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  onPressed: _guardarArea,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: greenPalette[500],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text('Guardar Área'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
