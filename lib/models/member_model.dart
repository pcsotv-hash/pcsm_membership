class Member {
  final String name;
  final String cnic;
  final String phone;
  final String address;
  final String province;
  final String division;
  final String district;
  final String tehsil;
  final String city;
  final String uc;
  final String education;
  final String profession;
  final String designation;
  final String designationArea;

  Member({
    required this.name,
    required this.cnic,
    required this.phone,
    required this.address,
    required this.province,
    required this.division,
    required this.district,
    required this.tehsil,
    required this.city,
    required this.uc,
    required this.education,
    required this.profession,
    required this.designation,
    required this.designationArea,
  });

  Map<String, dynamic> toJson() => {
        "name": name,
        "cnic": cnic,
        "phone": phone,
        "address": address,
        "province": province,
        "division": division,
        "district": district,
        "tehsil": tehsil,
        "city": city,
        "uc": uc,
        "education": education,
        "profession": profession,
        "designation": designation,
        "designationArea": designationArea,
      };
}
