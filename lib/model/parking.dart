class Parking {
  final int? parking_id;
  final double parking_lat;
  final double parking_lng;
  final String parking_info;
  final String parking_name;
  final String parking_image;


const Parking({
  this.parking_id,
  required this.parking_lat,
  required this.parking_lng,
  required this.parking_info,
  required this.parking_name,
  required this.parking_image,

  });

  factory Parking.fromJson(Map<String, dynamic> json) {
    return Parking(
      parking_id: int.tryParse(json['parking_id']?.toString() ?? ''),
      parking_lat: double.tryParse(json['parking_lat']?.toString() ?? '') ?? 37.526603,
      parking_lng: double.tryParse(json['parking_lng']?.toString() ?? '') ?? 126.934866,
      parking_name: json['parking_name']?.toString() ?? '', 
      parking_info: json['parking_info']?.toString() ?? '',
      parking_image: json['parking_image']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'parking_id': parking_id ?? 0,
      'parking_lat': parking_lat,
      'parking_lng': parking_lng,
      'parking_name': parking_name,
      'parking_info' : parking_info,
      'parking_image' : parking_image
    };
  }
}