class Parking {
  final int? parking_id;
  final double parking_lat;
  final double parking_lng;
  final String parking_name;
  final int parking_max;

  const Parking({
    this.parking_id,
    required this.parking_lat,
    required this.parking_lng,
    required this.parking_name,
    required this.parking_max,
  });

  factory Parking.fromJson(Map<String, dynamic> json) {
    final rawId = json['parking_id'] ?? json['parkinglot_id'];
    final rawLat = json['parking_lat'] ?? json['parkinglot_lat'];
    final rawLng =
        json['parking_lng'] ?? json['parking_long'] ?? json['parkinglot_long'];
    final rawName = json['parking_name'] ?? json['parkinglot_name'];
    final rawMax = json['parking_max'] ?? json['parkinglot_max'];

    return Parking(
      parking_id: int.tryParse(rawId?.toString() ?? ''),
      parking_lat: double.tryParse(rawLat?.toString() ?? '') ?? 37.526603,
      parking_lng: double.tryParse(rawLng?.toString() ?? '') ?? 126.934866,
      parking_name: rawName?.toString() ?? '',
      parking_max: int.tryParse(rawMax?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'parking_id': parking_id ?? 0,
      'parking_lat': parking_lat,
      'parking_lng': parking_lng,
      'parking_name': parking_name,
      'parking_max': parking_max,
    };
  }
}
