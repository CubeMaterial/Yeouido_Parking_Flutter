class Facility {
  final int? facility_id;
  final double facility_lat;
  final double facility_lng;
  final String facility_info;
  final String facility_name;
  final String facility_image;


const Facility({
  this.facility_id,
  required this.facility_lat,
  required this.facility_lng,
  required this.facility_info,
  required this.facility_name,
  required this.facility_image,

  });

  factory Facility.fromJson(Map<String, dynamic> json) {
    return Facility(
      facility_id: int.tryParse(json['facility_id']?.toString() ?? ''),
      facility_lat: double.tryParse(json['facility_lat']?.toString() ?? '') ?? 37.526603,
      facility_lng: double.tryParse(json['facility_lng']?.toString() ?? '') ?? 126.934866,
      facility_name: json['facility_name']?.toString() ?? '', 
      facility_info: json['facility_info']?.toString() ?? '',
      facility_image: json['facility_image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'facility_id': facility_id ?? 0,
      'facility_lat': facility_lat,
      'facility_lng': facility_lng,
      'facility_name': facility_name,
      'facility_info' : facility_info,
      'facility_image' : facility_image
    };
  }
}