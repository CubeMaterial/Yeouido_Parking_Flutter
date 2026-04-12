class Festival {
  final int? festival_id;
  final String festival_name;
  final String festival_start_at;
  final String festival_end_at;
  final String festival_info;


const Festival({
  this.festival_id,
  required this.festival_name,
  required this.festival_start_at,
  required this.festival_end_at,
  required this.festival_info,
  });

  factory Festival.fromJson(Map<String, dynamic> json) {
    return Festival(
      festival_id: int.tryParse(json['festival_id']?.toString() ?? ''),
      festival_name: json['festival_name']?.toString() ?? '', 
      festival_start_at: json['festival_start_at']?.toString() ?? '', 
      festival_end_at: json['festival_end_at']?.toString() ?? '',
      festival_info: json['festival_info']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'festival_id': festival_id ?? 0,
      'festival_name': festival_name,
      'festival_end_at': festival_end_at,
      'festival_start_at': festival_start_at,
      'festival_info' : festival_info,
    };
  }
}