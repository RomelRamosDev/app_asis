class Area {
  final String id;
  final String nombre;
  final String? descripcion;
  final List<String>? cargos;
  DateTime? hora_entrada_area;
  DateTime? hora_salida_area;
  final String sedeId; // Relación con la sede

  Area({
    required this.id,
    required this.nombre,
    required this.sedeId,
    this.cargos,
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
      'cargos': cargos,
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
      cargos: map['cargos'] != null ? List<String>.from(map['cargos']) : null,
      hora_entrada_area: map['hora_entrada_area'] != null
          ? _parseTime(map['hora_entrada_area'])
          : null,
      hora_salida_area: map['hora_salida_area'] != null
          ? _parseTime(map['hora_salida_area'])
          : null,
    );
  }

  static DateTime? _parseTime(dynamic time) {
    if (time is DateTime) return time;
    if (time is String) {
      try {
        return DateTime.parse('1970-01-01 $time');
      } catch (_) {
        return null;
      }
    }
    return null;
  }
}
