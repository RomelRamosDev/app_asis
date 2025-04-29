class Sede {
  final String id;
  final String nombre;
  final String? direccion;

  Sede({
    required this.id,
    required this.nombre,
    this.direccion,
  });

  factory Sede.fromMap(Map<String, dynamic> map, String id) {
    return Sede(
      id: id,
      nombre: map['nombre'],
      direccion: map['direccion'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'direccion': direccion,
    };
  }
}
