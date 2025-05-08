class Area {
  final String id;
  final String nombre;
  final String? descripcion;
  DateTime? hora_entrada_area;
  DateTime? hora_salida_area;
  final String sedeId; // Relación con la sede

  Area({
    required this.id,
    required this.nombre,
    required this.sedeId,
    this.descripcion,
    this.hora_entrada_area,
    this.hora_salida_area,
  });

  // Convertir un Area a Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'sede_id': sedeId,
      'descripcion': descripcion,
      'hora_entrada_area': hora_entrada_area,
      'hora_salida_area': hora_salida_area
    };
  }

  // Convertir un Map a Area

  factory Area.fromMap(Map<String, dynamic> map, String id) {
    return Area(
      id: id,
      nombre: map['nombre'] ?? '',
      sedeId: map['sede_id'] ?? '',
      descripcion: map['descripcion'],
    );
  }
}
