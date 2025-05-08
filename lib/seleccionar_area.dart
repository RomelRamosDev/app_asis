import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_asis/area_model.dart';
import 'package:app_asis/area_provider.dart';
import 'package:app_asis/sede_provider.dart';
import 'package:app_asis/home_navigation.dart';

class SeleccionarAreaScreen extends StatefulWidget {
  @override
  _SeleccionarAreaScreenState createState() => _SeleccionarAreaScreenState();
}

class _SeleccionarAreaScreenState extends State<SeleccionarAreaScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onAreaSelected(int index, Area area, BuildContext context) {
    final areaProvider = Provider.of<AreaProvider>(context, listen: false);

    setState(() => _selectedIndex = index);
    _controller.forward().then((_) {
      areaProvider.seleccionarArea(area);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeNavigation()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sedeProvider = Provider.of<SedeProvider>(context);
    final areaProvider = Provider.of<AreaProvider>(context);
    final areas = areaProvider.areas
        .where((area) => area.sedeId == sedeProvider.sedeActual?.id)
        .toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Selecciona tu Área'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: List.generate(areas.length, (index) {
            final isSelected = _selectedIndex == index;
            final scale = isSelected
                ? Tween<double>(begin: 1.0, end: 0.9).animate(
                    CurvedAnimation(parent: _controller, curve: Curves.easeOut))
                : AlwaysStoppedAnimation(1.0);

            return ScaleTransition(
              scale: scale,
              child: _AreaCard(
                area: areas[index],
                isSelected: isSelected,
                onTap: () => _onAreaSelected(index, areas[index], context),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  final Area area;
  final bool isSelected;
  final VoidCallback onTap;

  const _AreaCard({
    required this.area,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        width: 150,
        height: 150,
        decoration: BoxDecoration(
          color: isSelected ? Colors.green[300] : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.work_outline, size: 50, color: Colors.green[800]),
            SizedBox(height: 10),
            Text(
              area.nombre,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
