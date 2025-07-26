class Church {
  final int id;
  final String name;
  final String knownName;
  final String settlement;
  final double lat;
  final double lon;


  Church({
    required this.id,
    required this.name,
    required this.knownName,
    required this.settlement,
    required this.lat,
    required this.lon,
  });

  factory Church.fromJson(Map<String, dynamic> json) {
    return Church(
      id: json['id'] as int,
      name: json['nev'] as String,
      knownName: json['ismertnev'] as String,
      settlement: json['varos'] as String,
      lat: double.tryParse(json['lat'].toString()) ?? 0,
      lon: double.tryParse(json['lon'].toString()) ?? 0,
    );
  }
}
