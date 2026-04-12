class Reservation {
  final int? reservation_id;
  final String reservation_start_date;
  final String reservation_end_date;
  final String reservation_date;
  final int reservation_state;
  final int user_id;
  final int facility_id;


const Reservation({
  this.reservation_id,
  required this.reservation_start_date,
  required this.reservation_end_date,
  required this.reservation_date,
  required this.reservation_state,
  required this.user_id,
  required this.facility_id

  });

  factory Reservation.fromJson(Map<String, dynamic> json) {
    return Reservation(
      reservation_id: int.tryParse(json['reservation_id']?.toString() ?? ''),
      reservation_start_date: json['reservation_start_date']?.toString() ?? '', 
      reservation_end_date: json['reservation_end_date']?.toString() ?? '',
      reservation_state: int.tryParse(json['reservation_state']?.toString() ?? '') ?? 0,
      reservation_date: json['reservation_date']?.toString() ?? '',
      user_id: int.tryParse(json['user_id']?.toString() ?? '') ?? 0,
      facility_id: int.tryParse(json['facility_id']?.toString() ?? '') ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'reservation_id': reservation_id ?? 0,
      'reservation_start_date': reservation_start_date,
      'reservation_end_date': reservation_end_date,
      'reservation_state': reservation_state,
      'reservation_date': reservation_date,
      'user_id' : user_id,
      'facility_id' : facility_id
    };
  }
}