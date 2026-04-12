class Admin {
  final int? admin_id;
  final String admin_email;
  final String admin_password;
  final String admin_name;


const Admin({
  this.admin_id,
  required this.admin_email,
  required this.admin_password,
  required this.admin_name,

  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      admin_id: int.tryParse(json['admin_id']?.toString() ?? ''),
      admin_email: json['admin_email']?.toString() ?? '',
      admin_password: json['admin_password']?.toString() ?? '',
      admin_name: json['admin_name']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'admin_id': admin_id ?? 0,
      'admin_email': admin_email,
      'admin_name': admin_name,
      'admin_password': admin_password
    };
  }
}