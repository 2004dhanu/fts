class Donor {
  final int? id;
  final String indicompFtsId; // Added this field
  final String title;
  final String fullName;
  final String fatherName;
  final String motherName;
  final String gender;
  final String spouseName;
  final String dateOfBirth;
  final String dateOfAnniversary;
  final String panNumber;
  final String remarks;
  final String isPromoter;
  final String promoter;
  final String belongTo;
  final String source;
  final String donorType;
  final String type;
  final String mobilePhone;
  final String whatsapp;
  final String email;
  final String website;
  final String resHouseStreet;
  final String resArea;
  final String resLandmark;
  final String resCity;
  final String resState;
  final String resPincode;
  final String offHouseStreet;
  final String offArea;
  final String offLandmark;
  final String offCity;
  final String offState;
  final String offPincode;
  final String correspondencePref;
  final String imageUrl;
  final String imageBaseUrl;
  final String imageLogo;
  final String csr;
  final String contactName;
  final String contactDesignation;
  final String chapterName;
  
  Donor({
    this.id,
    required this.indicompFtsId, // Added required parameter
    required this.title,
    required this.fullName,
    required this.fatherName,
    required this.motherName,
    required this.gender,
    required this.spouseName,
    required this.dateOfBirth,
    required this.dateOfAnniversary,
    required this.panNumber,
    required this.remarks,
    required this.isPromoter,
    required this.promoter,
    required this.belongTo,
    required this.source,
    required this.donorType,
    required this.type,
    required this.mobilePhone,
    required this.whatsapp,
    required this.email,
    required this.website,
    required this.resHouseStreet,
    required this.resArea,
    required this.resLandmark,
    required this.resCity,
    required this.resState,
    required this.resPincode,
    required this.offHouseStreet,
    required this.offArea,
    required this.offLandmark,
    required this.offCity,
    required this.offState,
    required this.offPincode,
    required this.correspondencePref,
    required this.imageUrl,
    required this.imageBaseUrl,
    required this.imageLogo,
    required this.csr,
    required this.contactName,
    required this.contactDesignation,
    required this.chapterName,
  });
  
  // Main factory method with optional base URL
  factory Donor.fromJson(Map<String, dynamic> json, {String baseUrl = ''}) {
    final imageLogoValue = json['indicomp_image_logo']?.toString() ?? '';
    final imageUrlValue = json['image_url']?.toString() ?? '';
    
    return Donor(
      id: json['id'],
      indicompFtsId: json['indicomp_fts_id']?.toString() ?? '', // Added this line
      title: json['title'] ?? '',
      fullName: json['indicomp_full_name'] ?? json['full_name'] ?? '',
      fatherName: json['indicomp_father_name'] ?? '',
      motherName: json['indicomp_mother_name'] ?? '',
      gender: json['indicomp_gender'] ?? '',
      spouseName: json['indicomp_spouse_name'] ?? '',
      dateOfBirth: json['indicomp_dob_annualday'] ?? '',
      dateOfAnniversary: json['indicomp_doa'] ?? '',
      panNumber: json['indicomp_pan_no'] ?? '',
      remarks: json['indicomp_remarks'] ?? '',
      isPromoter: json['indicomp_is_promoter'] ?? '',
      promoter: json['indicomp_promoter'] ?? '',
      belongTo: json['indicomp_belongs_to'] ?? '',
      source: json['indicomp_source'] ?? '',
      donorType: json['indicomp_donor_type'] ?? '',
      type: json['indicomp_type'] ?? 'Individual',
      mobilePhone: json['indicomp_mobile_phone'] ?? '',
      whatsapp: json['indicomp_mobile_whatsapp'] ?? '',
      email: json['indicomp_email'] ?? '',
      website: json['indicomp_website'] ?? '',
      resHouseStreet: json['indicomp_res_reg_address'] ?? '',
      resArea: json['indicomp_res_reg_area'] ?? '',
      resLandmark: json['indicomp_res_reg_ladmark'] ?? '',
      resCity: json['indicomp_res_reg_city'] ?? '',
      resState: json['indicomp_res_reg_state'] ?? '',
      resPincode: json['indicomp_res_reg_pin_code'] ?? '',
      offHouseStreet: json['indicomp_off_branch_address'] ?? '',
      offArea: json['indicomp_off_branch_area'] ?? '',
      offLandmark: json['indicomp_off_branch_ladmark'] ?? '',
      offCity: json['indicomp_off_branch_city'] ?? '',
      offState: json['indicomp_off_branch_state'] ?? '',
      offPincode: json['indicomp_off_branch_pin_code'] ?? '',
      correspondencePref: json['indicomp_corr_preffer'] ?? 'Residence',
      imageUrl: imageUrlValue,
      imageBaseUrl: baseUrl,
      imageLogo: imageLogoValue,
      csr: json['indicomp_csr'] ?? '',
      contactName: json['indicomp_com_contact_name'] ?? '',
      contactDesignation: json['indicomp_com_contact_designation'] ?? '',
      chapterName: json['chapter_name'] ?? '',
    );
  }
  
  // Convenience method for when you have image base URL
  factory Donor.fromJsonWithImageUrl(Map<String, dynamic> json, String baseUrl) {
    return Donor.fromJson(json, baseUrl: baseUrl);
  }
  
  Map<String, dynamic> toApiMap() {
    return {
      'title': title,
      'indicomp_full_name': fullName,
      'indicomp_father_name': fatherName,
      'indicomp_mother_name': motherName,
      'indicomp_gender': gender,
      'indicomp_spouse_name': spouseName,
      'indicomp_dob_annualday': dateOfBirth,
      'indicomp_doa': dateOfAnniversary,
      'indicomp_pan_no': panNumber,
      'indicomp_remarks': remarks,
      'indicomp_is_promoter': isPromoter,
      'indicomp_promoter': promoter,
      'indicomp_belongs_to': belongTo,
      'indicomp_source': source,
      'indicomp_donor_type': donorType,
      'indicomp_type': type,
      'indicomp_mobile_phone': mobilePhone,
      'indicomp_mobile_whatsapp': whatsapp,
      'indicomp_email': email,
      'indicomp_website': website,
      'indicomp_res_reg_address': resHouseStreet,
      'indicomp_res_reg_area': resArea,
      'indicomp_res_reg_ladmark': resLandmark,
      'indicomp_res_reg_city': resCity,
      'indicomp_res_reg_state': resState,
      'indicomp_res_reg_pin_code': resPincode,
      'indicomp_off_branch_address': offHouseStreet,
      'indicomp_off_branch_area': offArea,
      'indicomp_off_branch_ladmark': offLandmark,
      'indicomp_off_branch_city': offCity,
      'indicomp_off_branch_state': offState,
      'indicomp_off_branch_pin_code': offPincode,
      'indicomp_corr_preffer': correspondencePref,
      'indicomp_csr': csr,
      'indicomp_com_contact_name': contactName,
      'indicomp_com_contact_designation': contactDesignation,
    };
  }
  
  // Get full image URL
  String get fullImageUrl {
    if (imageLogo.isNotEmpty && imageLogo != 'null' && imageLogo != '') {
      if (imageBaseUrl.isNotEmpty) {
        return '$imageBaseUrl$imageLogo';
      }
      return 'https://agstest.in/api2/public/assets/images/donor_images/$imageLogo';
    }
    if (imageUrl.isNotEmpty && imageUrl != 'null' && imageUrl != '') {
      return imageUrl;
    }
    return 'https://agstest.in/api2/public/assets/images/no_image.jpg';
  }
  
  String get displayName {
    String name = fullName;
    // Remove prefixes for cleaner display
    List<String> prefixes = ['Dr.', 'Mr.', 'Mrs.', 'Prof.', 'Miss', 'Ms.', 'MD', 'DVM', 'PhD', 'DDS'];
    for (var prefix in prefixes) {
      if (name.startsWith(prefix)) {
        name = name.substring(prefix.length).trim();
        break;
      }
    }
    // Remove suffixes like Jr., Sr., IV, III, II
    List<String> suffixes = ['Jr.', 'Sr.', 'IV', 'III', 'II', 'V'];
    for (var suffix in suffixes) {
      if (name.endsWith(suffix)) {
        name = name.substring(0, name.length - suffix.length).trim();
        break;
      }
    }
    return '$title $name'.trim();
  }
  
  String get shortName {
    List<String> parts = fullName.split(' ');
    if (parts.length >= 2) {
      return '$title ${parts[0]} ${parts[1][0]}.';
    }
    return '$title $fullName';
  }
  
  String get uniqueId => id != null ? 'DON-${id.toString().padLeft(6, '0')}' : 'NEW';
  
  // Get FTS ID for API calls
  String get ftsId => indicompFtsId.isNotEmpty ? indicompFtsId : (id?.toString() ?? '');
  
  String get maskedPhone {
    String phone = mobilePhone.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.length >= 10) {
      return '${phone.substring(0, 4)}****${phone.substring(phone.length - 3)}';
    } else if (phone.length >= 8) {
      return '${phone.substring(0, 4)}******';
    }
    return mobilePhone;
  }
  
  String get contactPerson => contactName.isNotEmpty ? contactName : spouseName;
  
  // Get formatted address for registered address
  String get formattedResAddress {
    List<String> parts = [];
    if (resHouseStreet.isNotEmpty) parts.add(resHouseStreet);
    if (resArea.isNotEmpty) parts.add(resArea);
    if (resLandmark.isNotEmpty) parts.add(resLandmark);
    if (resCity.isNotEmpty) parts.add(resCity);
    if (resState.isNotEmpty) parts.add(resState);
    if (resPincode.isNotEmpty) parts.add(resPincode);
    return parts.join(', ');
  }
  
  // Get formatted address for office address
  String get formattedOffAddress {
    List<String> parts = [];
    if (offHouseStreet.isNotEmpty) parts.add(offHouseStreet);
    if (offArea.isNotEmpty) parts.add(offArea);
    if (offLandmark.isNotEmpty) parts.add(offLandmark);
    if (offCity.isNotEmpty) parts.add(offCity);
    if (offState.isNotEmpty) parts.add(offState);
    if (offPincode.isNotEmpty) parts.add(offPincode);
    return parts.join(', ');
  }
  
  // Get preferred address based on correspondence preference
  String get preferredAddress {
    switch (correspondencePref.toLowerCase()) {
      case 'office':
        return formattedOffAddress;
      case 'residence':
      default:
        return formattedResAddress;
    }
  }
  
  // Check if donor has complete information
  bool get isComplete {
    return fullName.isNotEmpty &&
           mobilePhone.isNotEmpty &&
           resCity.isNotEmpty &&
           resState.isNotEmpty &&
           resPincode.isNotEmpty;
  }
  
  // Create a copy of donor with updated fields
  Donor copyWith({
    int? id,
    String? indicompFtsId,
    String? title,
    String? fullName,
    String? fatherName,
    String? motherName,
    String? gender,
    String? spouseName,
    String? dateOfBirth,
    String? dateOfAnniversary,
    String? panNumber,
    String? remarks,
    String? isPromoter,
    String? promoter,
    String? belongTo,
    String? source,
    String? donorType,
    String? type,
    String? mobilePhone,
    String? whatsapp,
    String? email,
    String? website,
    String? resHouseStreet,
    String? resArea,
    String? resLandmark,
    String? resCity,
    String? resState,
    String? resPincode,
    String? offHouseStreet,
    String? offArea,
    String? offLandmark,
    String? offCity,
    String? offState,
    String? offPincode,
    String? correspondencePref,
    String? imageUrl,
    String? imageBaseUrl,
    String? imageLogo,
    String? csr,
    String? contactName,
    String? contactDesignation,
    String? chapterName,
  }) {
    return Donor(
      id: id ?? this.id,
      indicompFtsId: indicompFtsId ?? this.indicompFtsId,
      title: title ?? this.title,
      fullName: fullName ?? this.fullName,
      fatherName: fatherName ?? this.fatherName,
      motherName: motherName ?? this.motherName,
      gender: gender ?? this.gender,
      spouseName: spouseName ?? this.spouseName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      dateOfAnniversary: dateOfAnniversary ?? this.dateOfAnniversary,
      panNumber: panNumber ?? this.panNumber,
      remarks: remarks ?? this.remarks,
      isPromoter: isPromoter ?? this.isPromoter,
      promoter: promoter ?? this.promoter,
      belongTo: belongTo ?? this.belongTo,
      source: source ?? this.source,
      donorType: donorType ?? this.donorType,
      type: type ?? this.type,
      mobilePhone: mobilePhone ?? this.mobilePhone,
      whatsapp: whatsapp ?? this.whatsapp,
      email: email ?? this.email,
      website: website ?? this.website,
      resHouseStreet: resHouseStreet ?? this.resHouseStreet,
      resArea: resArea ?? this.resArea,
      resLandmark: resLandmark ?? this.resLandmark,
      resCity: resCity ?? this.resCity,
      resState: resState ?? this.resState,
      resPincode: resPincode ?? this.resPincode,
      offHouseStreet: offHouseStreet ?? this.offHouseStreet,
      offArea: offArea ?? this.offArea,
      offLandmark: offLandmark ?? this.offLandmark,
      offCity: offCity ?? this.offCity,
      offState: offState ?? this.offState,
      offPincode: offPincode ?? this.offPincode,
      correspondencePref: correspondencePref ?? this.correspondencePref,
      imageUrl: imageUrl ?? this.imageUrl,
      imageBaseUrl: imageBaseUrl ?? this.imageBaseUrl,
      imageLogo: imageLogo ?? this.imageLogo,
      csr: csr ?? this.csr,
      contactName: contactName ?? this.contactName,
      contactDesignation: contactDesignation ?? this.contactDesignation,
      chapterName: chapterName ?? this.chapterName,
    );
  }
}