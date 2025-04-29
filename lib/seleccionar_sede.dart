import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_asis/sede_model.dart';
import 'package:app_asis/sede_provider.dart';
import 'home_navigation.dart';

class SeleccionarSedeScreen extends StatefulWidget {
  @override
  _SeleccionarSedeScreenState createState() => _SeleccionarSedeScreenState();
}

class _SeleccionarSedeScreenState extends State<SeleccionarSedeScreen>
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

  void _onSedeSelected(int index, Sede sede, BuildContext context) {
    setState(() => _selectedIndex = index);
    _controller.forward().then((_) {
      Provider.of<SedeProvider>(context, listen: false).seleccionarSede(sede);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeNavigation()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sedes = Provider.of<SedeProvider>(context).sedes;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Selecciona tu Sede'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 20,
          runSpacing: 20,
          children: List.generate(sedes.length, (index) {
            final isSelected = _selectedIndex == index;
            final scale = isSelected
                ? Tween<double>(begin: 1.0, end: 0.9).animate(
                    CurvedAnimation(parent: _controller, curve: Curves.easeOut))
                : AlwaysStoppedAnimation(1.0);

            return ScaleTransition(
              scale: scale,
              child: _SedeCard(
                sede: sedes[index],
                isSelected: isSelected,
                onTap: () => _onSedeSelected(index, sedes[index], context),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _SedeCard extends StatelessWidget {
  final Sede sede;
  final bool isSelected;
  final VoidCallback onTap;

  const _SedeCard({
    required this.sede,
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
            Icon(Icons.location_city, size: 50, color: Colors.green[800]),
            SizedBox(height: 10),
            Text(
              sede.nombre,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.green[900],
              ),
            ),
            if (sede.direccion != null) ...[
              SizedBox(height: 5),
              Text(
                sede.direccion!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
