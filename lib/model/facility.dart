class Facility {
  final int? facility_id;
  final double facility_lat;
  final double facility_lng;
  final String facility_info;
  final String facility_name;
  final String facility_image;
  final int facility_possible;

const Facility({
  this.facility_id,
  required this.facility_lat,
  required this.facility_lng,
  required this.facility_info,
  required this.facility_name,
  required this.facility_image,
  required this.facility_possible

  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    final rawId = json['facility_id'] ?? json['f_id'];
    final rawLat = json['facility_lat'] ?? json['f_lat'];
    final rawLng = json['facility_lng'] ?? json['f_long'] ?? json['f_lng'];
    final rawName = json['facility_name'] ?? json['f_name'];
    final rawInfo = json['facility_info'] ?? json['f_info'];
    final rawImage = json['facility_image'] ?? json['f_image'];
    final rawPossible = json['facility_possible'] ?? json['f_possible'];

    return Facility(
      facility_id: int.tryParse(rawId?.toString() ?? ''),
      facility_lat: double.tryParse(rawLat?.toString() ?? '') ?? 37.526603,
      facility_lng: double.tryParse(rawLng?.toString() ?? '') ?? 126.934866,
      facility_name: rawName?.toString() ?? '',
      facility_info: rawInfo?.toString() ?? '',
      facility_image: rawImage?.toString() ?? '',
      facility_possible: int.tryParse(rawPossible?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'facility_id': facility_id ?? 0,
      'facility_lat': facility_lat,
      'facility_lng': facility_lng,
      'facility_name': facility_name,
      'facility_info' : facility_info,
      'facility_image' : facility_image,
      'facility_possible' : facility_possible
    };
  }
}
