class CenterModel {
  final String name;
  final String address;
  final String district;
  final String area;
  final String location;
  final String contact;
  final String status;
  final String history;
  final String page;

  const CenterModel({
    required this.name,
    required this.address,
    required this.district,
    required this.area,
    required this.location,
    required this.contact,
    required this.status,
    this.history = '',
    this.page = '',
  });

  factory CenterModel.fromMap(Map<String, dynamic> map) {
    return CenterModel(
      name: map['centername']?.toString().trim() ?? '',
      address: map['centeraddress']?.toString().trim() ?? '',
      district: map['centerdistrict']?.toString().trim() ?? '',
      area: map['centerarea']?.toString().trim() ?? '',
      location: map['centerlocation']?.toString().trim() ?? '',
      contact: map['centercontact']?.toString().trim() ?? '',
      status: map['centerstatus']?.toString().trim() ?? '',
      history: (map['centerhistory'] ?? map['history'])?.toString().trim() ?? '',
      page: (map['centerpage'] ?? map['page'] ?? map['facebookpage'])?.toString().trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'centername': name,
      'centeraddress': address,
      'centerdistrict': district,
      'centerarea': area,
      'centerlocation': location,
      'centercontact': contact,
      'centerstatus': status,
      'centerhistory': history,
      'centerpage': page,
    };
  }
}
