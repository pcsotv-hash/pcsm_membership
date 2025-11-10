// lib/screens/membership_form.dart
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:flutter_windowmanager/flutter_windowmanager.dart'; // Commented out due to compatibility issues
import '../services/api_service.dart';
import '../utils/constants.dart';
import '../main.dart';

class MembershipForm extends StatefulWidget {
  const MembershipForm({Key? key}) : super(key: key);

  @override
  State<MembershipForm> createState() => _MembershipFormState();
}

class _MembershipFormState extends State<MembershipForm> {
  final _formKey = GlobalKey<FormState>();
  final ApiService api = ApiService();
  bool isRtl = true;
  bool isDarkMode = false;

  // controllers
  final tcName = TextEditingController();
  final tcFather = TextEditingController();
  final tcCnic = TextEditingController();
  final tcPhone = TextEditingController();
  final tcAddress = TextEditingController();
  final tcTehsil = TextEditingController();
  final tcCity = TextEditingController();
  final tcUc = TextEditingController();
  final tcEducation = TextEditingController();
  final tcProfession = TextEditingController();
  final tcDesignation = TextEditingController();
  final tcDesignationArea = TextEditingController();

  // focus nodes (auto next)
  final fnName = FocusNode();
  final fnFather = FocusNode();
  final fnCnic = FocusNode();
  final fnPhone = FocusNode();
  final fnAddress = FocusNode();
  final fnTehsil = FocusNode();
  final fnCity = FocusNode();
  final fnUc = FocusNode();
  final fnEducation = FocusNode();
  final fnProfession = FocusNode();
  final fnDesignationArea = FocusNode();

  // image files
  File? filePhoto;
  File? fileCnicFront;
  File? fileCnicBack;

  // image previews
  Uint8List? photoBytes;
  Uint8List? cnicFrontBytes;
  Uint8List? cnicBackBytes;

  // location data
  Map<String, dynamic> locData = {};
  Map<String, dynamic> citiesData = {};
  List<String> provinces = [];
  List<String> divisions = [];
  List<String> districts = [];
  List<String> citiesForDistrict = [];
  List<String> tehsilsForDistrict = [];

  // designations from Form.html
  final List<String> designations = [
    'President',
    'Senior Vice President',
    'Vice President',
    'General Secretary',
    'Deputy General Secretary',
    'Additional General Secretary',
    'Joint Secretary',
    'Deputy Joint Secretary',
    'Information Secretary',
    'Office Secretary',
    'Labour Secretary',
    'Health Secretary',
    'Education Secretary',
    'Minority Secretary',
    'Finance Secretary',
    'Sports Secretary',
    'Coordinator',
    'Deputy Coordinator',
    'Media Coordinator',
    'Youth Coordinator',
    'Legal Coordinator',
    'Complaint Cell Incharge',
  ];

  String? selectedProvince;
  String? selectedDivision;
  String? selectedDistrict;

  // status
  bool submitting = false;
  double uploadProgress = 0.0;

  // CNIC validation
  bool isCnicValid = false;
  bool isCnicDuplicate = false;

  // picture validation
  bool isPhotoClear = true;
  bool showPhotoWarning = false;

  // date/time
  String dateTimeDisplay = "";

  @override
  void initState() {
    super.initState();
    _setDateTime();
    _loadLocationFiles();
    // _secureScreen(); // Commented out due to compatibility issues
  }

  // void _secureScreen() async {
  //   try {
  //     await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
  //   } catch (e) {
  //     // Handle screenshot prevention error
  //   }
  // }

  void _setDateTime() {
    final now = DateTime.now();
    dateTimeDisplay = DateFormat('yyyy-MM-dd HH:mm').format(now);
  }

  Future<void> _loadLocationFiles() async {
    try {
      final s1 = await rootBundle.loadString('assets/locations.json');
      final s2 = await rootBundle.loadString(
        'assets/pakistan_cities_complete.json',
      );
      final Map<String, dynamic> a = json.decode(s1);
      final Map<String, dynamic> b = json.decode(s2);
      setState(() {
        locData = a;
        citiesData = b;
        provinces = a.keys.map((e) => e.toString()).toList();
      });
    } catch (e) {
      // fallback: keep lists empty for manual input
      setState(() {
        locData = {};
        citiesData = {};
        provinces = [];
      });
      // optional: print(e);
    }
  }

  // Dropdown handlers
  void _onProvinceChanged(String? p) {
    if (p == null) return;
    setState(() {
      selectedProvince = p;
      selectedDivision = null;
      selectedDistrict = null;
      divisions = [];
      districts = [];
      citiesForDistrict = [];
    });

    final node = locData[p];
    if (node is Map<String, dynamic>) {
      setState(() {
        divisions = node.keys.map((e) => e.toString()).toList();
      });
    }
  }

  void _onDivisionChanged(String? d) {
    if (d == null) return;
    setState(() {
      selectedDivision = d;
      selectedDistrict = null;
      districts = [];
      citiesForDistrict = [];
      tehsilsForDistrict = [];
    });

    final divMap = locData[selectedProvince];
    if (divMap is Map<String, dynamic>) {
      final distNode = divMap[d];
      if (distNode is List) {
        setState(() {
          districts = distNode.map((e) => e.toString()).toList();
        });
      } else if (distNode is Map<String, dynamic>) {
        setState(() {
          districts = distNode.keys.map((e) => e.toString()).toList();
        });
      }
    }
  }

  void _onDistrictChanged(String? dist) {
    if (dist == null) return;
    setState(() {
      selectedDistrict = dist;
      citiesForDistrict = [];
      tehsilsForDistrict = [];
    });
    // populate tehsils from locations.json (nested structures supported)
    try {
      final provMap = locData[selectedProvince];
      if (provMap is Map<String, dynamic>) {
        final divMap = provMap[selectedDivision];
        if (divMap is Map<String, dynamic>) {
          final tehsilNode = divMap[dist];
          List<String> tList = [];
          if (tehsilNode is List) {
            tList = tehsilNode.map((e) => e.toString()).toList();
          } else if (tehsilNode is Map<String, dynamic>) {
            tList = tehsilNode.keys.map((e) => e.toString()).toList();
          }
          setState(() {
            tehsilsForDistrict = tList;
          });
        }
      }
    } catch (_) {}

    // populate cities from pakistan_cities_complete.json (nested fallback)
    try {
      // direct district key lookup first
      final direct = citiesData[dist];
      if (direct is List) {
        setState(() {
          citiesForDistrict = direct.map((e) => e.toString()).toList();
        });
        return;
      }
      // nested path: province -> division -> district -> {cities|towns}
      final provNode = citiesData[selectedProvince];
      if (provNode is Map<String, dynamic>) {
        final divNode = provNode[selectedDivision];
        if (divNode is Map<String, dynamic>) {
          final distNode = divNode[dist];
          if (distNode is Map<String, dynamic>) {
            final List<String> cityList = [];
            final c = distNode['cities'];
            final t = distNode['towns'];
            if (c is List) cityList.addAll(c.map((e) => e.toString()));
            if (t is List) cityList.addAll(t.map((e) => e.toString()));
            setState(() {
              citiesForDistrict = cityList;
            });
            return;
          }
        }
      }
    } catch (_) {}
    // fallback: manual typing
    setState(() {
      citiesForDistrict = [];
    });
  }

  // Image picker
  Future<void> _pickImage(String which) async {
    try {
      final picker = ImagePicker();
      final XFile? pick = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );
      if (pick == null) return;
      Uint8List bytes;
      File? f;
      if (kIsWeb) {
        bytes = await pick.readAsBytes();
        f = null; // File is not available on web
      } else {
        f = File(pick.path);
        bytes = await f.readAsBytes();
      }

      setState(() {
        if (which == 'photo') {
          filePhoto = f;
          photoBytes = bytes;
          _validatePhoto();
        }
        if (which == 'front') {
          fileCnicFront = f;
          cnicFrontBytes = bytes;
        }
        if (which == 'back') {
          fileCnicBack = f;
          cnicBackBytes = bytes;
        }
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Image pick error: ${e.toString()}");
    }
  }

  // Photo validation
  void _validatePhoto() {
    // Simple validation: check if photo has reasonable size and dimensions
    if (photoBytes != null && photoBytes!.isNotEmpty) {
      // Basic check: if file size is too small, it might be unclear
      if (photoBytes!.length < 10000) {
        // Less than 10KB
        setState(() {
          isPhotoClear = false;
          showPhotoWarning = true;
        });
        _showPhotoQualityDialog();
      } else {
        setState(() {
          isPhotoClear = true;
          showPhotoWarning = false;
        });
      }
    }
  }

  void _showPhotoQualityDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Picture Quality Warning'),
        content: const Text(
          'The uploaded picture appears to be of low quality. Please upload a clear, recent photograph for better identification.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Anyway'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _pickImage('photo'); // Re-pick image
            },
            child: const Text('Upload New Picture'),
          ),
        ],
      ),
    );
  }

  // CNIC validation (input handler)
  void _validateCnicInput(String value) {
    // CNIC format: 12345-1234567-1 or 1234512345671
    final cnicPattern = RegExp(r'^[0-9]{5}-?[0-9]{7}-?[0-9]{1}$');
    setState(() {
      isCnicValid = cnicPattern.hasMatch(value);
    });

    if (isCnicValid) {
      _checkCnicDuplication(value);
    }
  }

  void _checkCnicDuplication(String cnic) async {
    try {
      final response = await api.checkCnicDuplication(cnic);
      if (response['exists'] == true) {
        setState(() {
          isCnicDuplicate = true;
        });
        Fluttertoast.showToast(
          msg: "This CNIC is already registered!",
          backgroundColor: Colors.red,
        );
      } else {
        setState(() {
          isCnicDuplicate = false;
        });
      }
    } catch (e) {
      // Handle error silently or show message
      debugPrint("CNIC check error: $e");
    }
  }

  // preview modal
  Future<bool?> _showPreview() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text("Preview Submission"),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (filePhoto != null)
                      Image.file(
                        filePhoto!,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        width: 90,
                        height: 90,
                        color: Colors.grey[200],
                        child: const Icon(Icons.person),
                      ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Name: ${tcName.text}"),
                          Text("Father: ${tcFather.text}"),
                          Text("CNIC: ${tcCnic.text}"),
                          Text("Mobile: ${tcPhone.text}"),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (fileCnicFront != null)
                      Image.file(
                        fileCnicFront!,
                        width: 100,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        width: 100,
                        height: 60,
                        color: Colors.grey[200],
                      ),
                    const SizedBox(width: 8),
                    if (fileCnicBack != null)
                      Image.file(
                        fileCnicBack!,
                        width: 100,
                        height: 60,
                        fit: BoxFit.cover,
                      )
                    else
                      Container(
                        width: 100,
                        height: 60,
                        color: Colors.grey[200],
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Text("Province: ${selectedProvince ?? ''}"),
                Text("Division: ${selectedDivision ?? ''}"),
                Text("District: ${selectedDistrict ?? ''}"),
                Text("Tehsil: ${tcTehsil.text}"),
                Text("City: ${tcCity.text}"),
                Text("UC: ${tcUc.text}"),
                Text("Address: ${tcAddress.text}"),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Edit"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text("Confirm & Submit"),
            ),
          ],
        );
      },
    );
  }

  // validation helpers
  String? _validateRequired(String? v) =>
      (v == null || v.trim().isEmpty) ? "Required" : null;

  String? _validateCnic(String? v) {
    if (v == null || v.trim().isEmpty) return "Required";
    final digits = v.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 13) return "CNIC must be 13 digits";
    return null;
  }

  String? _validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return "Required";
    final digits = v.replaceAll(RegExp(r'[^0-9+]'), '');
    if (digits.length < 10) return "Enter valid phone";
    return null;
  }

  // CNIC formatter: 12345-1234567-1
  String _formatCnicWithDashes(String digits) {
    final only = digits.replaceAll(RegExp(r'[^0-9]'), '');
    final b = StringBuffer();
    for (int i = 0; i < only.length && i < 13; i++) {
      b.write(only[i]);
      if (i == 4 && only.length > 5) b.write('-');
      if (i == 11 && only.length > 12) b.write('-');
    }
    return b.toString();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate CNIC
    if (!isCnicValid) {
      Fluttertoast.showToast(msg: "Please enter a valid CNIC");
      return;
    }

    // Check CNIC duplication
    if (isCnicDuplicate) {
      Fluttertoast.showToast(msg: "This CNIC is already registered");
      return;
    }

    // Validate images
    if (photoBytes == null && filePhoto == null) {
      Fluttertoast.showToast(msg: "Please upload your photo");
      return;
    }
    if (cnicFrontBytes == null && fileCnicFront == null) {
      Fluttertoast.showToast(msg: "Please upload CNIC front side");
      return;
    }
    if (cnicBackBytes == null && fileCnicBack == null) {
      Fluttertoast.showToast(msg: "Please upload CNIC back side");
      return;
    }

    final confirmed = await _showPreview();
    if (confirmed != true) return;

    final fields = {
      "name": tcName.text.trim(),
      "father": tcFather.text.trim(),
      "cnic": tcCnic.text.trim(),
      "mobile": tcPhone.text.trim(),
      "address": tcAddress.text.trim(),
      "province": selectedProvince ?? "",
      "division": selectedDivision ?? "",
      "district": selectedDistrict ?? "",
      "tehsil": tcTehsil.text.trim(),
      "city": tcCity.text.trim(),
      // Removed UC field as requested
      "education": tcEducation.text.trim(),
      "profession": tcProfession.text.trim(),
      "designation": tcDesignation.text.trim(),
      "designation_area": tcDesignationArea.text.trim(),
      "submitted_at": dateTimeDisplay,
    };

    setState(() {
      submitting = true;
      uploadProgress = 0.0;
    });

    final res = await api.submitForm(
      fields: fields,
      photo: filePhoto,
      cnicFront: fileCnicFront,
      cnicBack: fileCnicBack,
      onSendProgress: (sent, total) {
        setState(() {
          uploadProgress = (total > 0 ? sent / total : 0.0);
        });
      },
    );

    setState(() {
      submitting = false;
      uploadProgress = 0.0;
    });

    if ((res['status'] == 1) ||
        (res['success'] == true) ||
        (res['message']?.toString().toLowerCase().contains('success') ==
            true)) {
      Fluttertoast.showToast(msg: "Submitted successfully");
      Navigator.pushReplacementNamed(
        context,
        '/success',
        arguments: {
          "name": tcName.text.trim(),
          "cnic": tcCnic.text.trim(),
          "id": res['id'] ?? res['member_id'],
        },
      );
    } else {
      final msg = res['message'] ?? "Submission failed";
      Fluttertoast.showToast(msg: msg.toString());
    }
  }

  @override
  void dispose() {
    tcName.dispose();
    tcFather.dispose();
    tcCnic.dispose();
    tcPhone.dispose();
    tcAddress.dispose();
    tcTehsil.dispose();
    tcCity.dispose();
    tcUc.dispose();
    tcEducation.dispose();
    tcProfession.dispose();
    tcDesignation.dispose();
    tcDesignationArea.dispose();
    fnName.dispose();
    fnFather.dispose();
    fnCnic.dispose();
    fnPhone.dispose();
    fnAddress.dispose();
    fnTehsil.dispose();
    fnCity.dispose();
    fnUc.dispose();
    fnEducation.dispose();
    fnProfession.dispose();
    fnDesignationArea.dispose();
    super.dispose();
  }

  Widget _header() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDarkMode
                ? Colors.black.withOpacity(0.25)
                : Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withOpacity(0.18)
                  : Colors.black.withOpacity(0.08),
            ),
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/Logo.png',
                width: 60,
                height: 60,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Pakistan Civil Soldier Movement",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "Date: $dateTimeDisplay",
                      style: TextStyle(
                        fontSize: 12,
                        color: isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Row(
                children: [
                  ChoiceChip(
                    label: const Text('English'),
                    selected: !isRtl,
                    onSelected: (_) => setState(() => isRtl = false),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('اردو'),
                    selected: isRtl,
                    onSelected: (_) => setState(() => isRtl = true),
                  ),
                  const SizedBox(width: 12),
                  PopupMenuButton<ThemeMode>(
                    tooltip: 'Theme',
                    icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode),
                    onSelected: (mode) {
                      PcsmApp.of(context)?.setThemeMode(mode);
                      setState(() {});
                    },
                    itemBuilder: (ctx) => const [
                      PopupMenuItem(
                        value: ThemeMode.system,
                        child: Text('System Default'),
                      ),
                      PopupMenuItem(
                        value: ThemeMode.light,
                        child: Text('Light'),
                      ),
                      PopupMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _translateHint(String en) {
    final map = {
      "Enter your full name": "اپنا پورا نام درج کریں",
      "Enter father's name": "والد کا نام درج کریں",
      "12345-1234567-1": "مثال: 12345-1234567-1",
      "03xx-xxxxxxx": "مثال: 03xx-xxxxxxx",
      "Select Province": "صوبہ منتخب کریں",
      "Province": "صوبہ",
      "Select Division": "ڈویژن منتخب کریں",
      "Division": "ڈویژن",
      "Select District": "ضلع منتخب کریں",
      "District": "ضلع",
      "Tehsil": "تحصیل",
      "Select City": "شہر منتخب کریں",
      "City": "شہر",
      "Enter your UC": "یونین کونسل درج کریں",
      "Enter your complete address": "مکمل پتہ درج کریں",
      "Enter your education": "تعلیم درج کریں",
      "Enter your profession": "پیشہ درج کریں",
      "Select Designation": "عہدہ منتخب کریں",
      "Enter designation area": "عہدے کا علاقہ درج کریں",
    };
    return isRtl ? (map[en] ?? en) : en;
  }

  InputDecoration _in(String hint) => InputDecoration(
    hintText: _translateHint(hint),
    hintStyle: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black45),
    labelStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black87),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: isDarkMode ? Colors.grey[900] : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: isDarkMode ? Colors.white : Colors.grey.shade300,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(
        color: isDarkMode ? Colors.white : const Color(0xFF0B7A3B),
        width: 2,
      ),
    ),
    errorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Colors.red, width: 1),
    ),
    focusedErrorBorder: const OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(8)),
      borderSide: BorderSide(color: Colors.red, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final themeData = ThemeData(
      brightness: isDarkMode ? Brightness.dark : Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0A6831),
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      ),
      textTheme: isRtl
          ? GoogleFonts.notoNastaliqUrduTextTheme(Theme.of(context).textTheme)
          : GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
      scaffoldBackgroundColor: isDarkMode
          ? const Color(0xFF101211)
          : const Color(0xFFF8F9FA),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF0B7A3B),
        elevation: 0,
      ),
    );

    // Sync local dark mode flag with system/app theme
    isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Theme(
      data: themeData,
      child: Directionality(
        textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        child: Scaffold(
          appBar: null,
          bottomNavigationBar: _buildFooter(context),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _header(),
                  const SizedBox(height: 16),
                  // Version removed from header area for premium look

                  // Main form card with subtle glass styling
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode
                          ? Colors.black.withOpacity(0.20)
                          : Colors.white.withOpacity(0.10),
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.06),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Card(
                      color: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 8),

                            // Auto Date/Time Field
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? Colors.grey[900]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDarkMode
                                      ? Colors.white
                                      : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today,
                                    color: Color(0xFF0B7A3B),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Registration Date & Time",
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isDarkMode
                                                ? Colors.white70
                                                : Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          DateTime.now().toString().substring(
                                            0,
                                            19,
                                          ),
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                            color: isDarkMode
                                                ? Colors.white
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.lock_outline,
                                    color: isDarkMode
                                        ? Colors.white70
                                        : Colors.grey,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // images section with mobile-friendly layout
                            const Text(
                              "Pictures",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Profile Photo
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Profile Photo *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () => _pickImage('photo'),
                                  child: Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[900]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                        (photoBytes != null ||
                                            filePhoto != null)
                                        ? Stack(
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: photoBytes != null
                                                    ? Image.memory(
                                                        photoBytes!,
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: 150,
                                                      )
                                                    : Image.file(
                                                        filePhoto!,
                                                        fit: BoxFit.cover,
                                                        width: double.infinity,
                                                        height: 150,
                                                      ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: Container(
                                                  padding: const EdgeInsets.all(
                                                    4,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withOpacity(0.6),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          20,
                                                        ),
                                                  ),
                                                  child: const Icon(
                                                    Icons.edit,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.camera_alt,
                                                size: 48,
                                                color: Colors.grey.shade600,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                "Tap to upload photo",
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                                if (showPhotoWarning) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.orange.shade300,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.warning,
                                          color: Colors.orange.shade600,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            "Please upload a clear photo for better identification",
                                            style: TextStyle(
                                              color: Colors.orange.shade800,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),

                            const SizedBox(height: 16),

                            // CNIC Photos moved near submit button

                            // form inputs with better labels
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Full Name *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: tcName,
                                  focusNode: fnName,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(
                                    context,
                                  ).requestFocus(fnFather),
                                  decoration: _in("Enter your full name")
                                      .copyWith(
                                        prefixIcon: const Icon(
                                          Icons.person,
                                          size: 20,
                                        ),
                                      ),
                                  validator: _validateRequired,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Father Name *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: tcFather,
                                  focusNode: fnFather,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(
                                    context,
                                  ).requestFocus(fnCnic),
                                  decoration: _in("Enter father's name")
                                      .copyWith(
                                        prefixIcon: const Icon(
                                          Icons.person_outline,
                                          size: 20,
                                        ),
                                      ),
                                  validator: _validateRequired,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // CNIC with dashes and auto-formatting
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "CNIC *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: tcCnic,
                                  focusNode: fnCnic,
                                  textInputAction: TextInputAction.next,
                                  onFieldSubmitted: (_) => FocusScope.of(
                                    context,
                                  ).requestFocus(fnPhone),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9-]'),
                                    ),
                                    LengthLimitingTextInputFormatter(15),
                                  ],
                                  decoration: _in("12345-1234567-1").copyWith(
                                    hintText: "12345-1234567-1",
                                    prefixIcon: const Icon(
                                      Icons.credit_card,
                                      size: 20,
                                    ),
                                    suffixIcon:
                                        tcCnic.text
                                                .replaceAll(
                                                  RegExp(r'[^0-9]'),
                                                  '',
                                                )
                                                .length ==
                                            13
                                        ? (isCnicValid
                                              ? const Icon(
                                                  Icons.check_circle,
                                                  color: Colors.green,
                                                  size: 20,
                                                )
                                              : const Icon(
                                                  Icons.error,
                                                  color: Colors.red,
                                                  size: 20,
                                                ))
                                        : null,
                                  ),
                                  validator: _validateCnic,
                                  onChanged: (value) {
                                    // Auto-format: keep digits, insert dashes at 5 and 12
                                    final digits = value.replaceAll(
                                      RegExp(r'[^0-9]'),
                                      '',
                                    );
                                    final formatted = _formatCnicWithDashes(
                                      digits,
                                    );
                                    if (value != formatted) {
                                      tcCnic.value = TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(
                                          offset: formatted.length,
                                        ),
                                      );
                                    }
                                    _validateCnicInput(formatted);
                                    setState(() {});
                                    if (digits.length == 13 && isCnicValid) {
                                      FocusScope.of(
                                        context,
                                      ).requestFocus(fnPhone);
                                    }
                                  },
                                ),
                                if (tcCnic.text
                                            .replaceAll(RegExp(r'[^0-9]'), '')
                                            .length ==
                                        13 &&
                                    !isCnicValid) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "Invalid CNIC format",
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                                if (isCnicDuplicate) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    "This CNIC is already registered",
                                    style: TextStyle(
                                      color: Colors.red.shade700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 8),

                            // phone with mobile-friendly keyboard
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Mobile Number *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: tcPhone,
                                  focusNode: fnPhone,
                                  textInputAction: TextInputAction.next,
                                  keyboardType: TextInputType.phone,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'[0-9+]'),
                                    ),
                                    LengthLimitingTextInputFormatter(15),
                                  ],
                                  decoration: _in("03xx-xxxxxxx").copyWith(
                                    hintText: "03xx-xxxxxxx",
                                    prefixIcon: const Icon(
                                      Icons.phone_android,
                                      size: 20,
                                    ),
                                  ),
                                  validator: _validatePhone,
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                  onFieldSubmitted: (_) => FocusScope.of(
                                    context,
                                  ).requestFocus(fnAddress),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // location section
                            const Text(
                              "Location Information",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Province
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Province *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                provinces.isNotEmpty
                                    ? DropdownButtonFormField<String>(
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        dropdownColor: isDarkMode
                                            ? Colors.grey[900]
                                            : Colors.white,
                                        iconEnabledColor: isDarkMode
                                            ? Colors.white
                                            : null,
                                        initialValue: selectedProvince,
                                        items: provinces
                                            .map(
                                              (p) => DropdownMenuItem(
                                                value: p,
                                                child: Text(p),
                                              ),
                                            )
                                            .toList(),
                                        decoration: _in("Select Province")
                                            .copyWith(
                                              prefixIcon: const Icon(
                                                Icons.location_city,
                                                size: 20,
                                              ),
                                            ),
                                        onChanged: _onProvinceChanged,
                                        validator: (v) =>
                                            (v == null || v.isEmpty)
                                            ? "Required"
                                            : null,
                                      )
                                    : TextFormField(
                                        decoration: _in("Province").copyWith(
                                          prefixIcon: const Icon(
                                            Icons.location_city,
                                            size: 20,
                                          ),
                                        ),
                                        onChanged: (v) => selectedProvince = v,
                                      ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Division
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Division *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                divisions.isNotEmpty
                                    ? DropdownButtonFormField<String>(
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        dropdownColor: isDarkMode
                                            ? Colors.grey[900]
                                            : Colors.white,
                                        iconEnabledColor: isDarkMode
                                            ? Colors.white
                                            : null,
                                        initialValue: selectedDivision,
                                        items: divisions
                                            .map(
                                              (d) => DropdownMenuItem(
                                                value: d,
                                                child: Text(d),
                                              ),
                                            )
                                            .toList(),
                                        decoration: _in("Select Division")
                                            .copyWith(
                                              prefixIcon: const Icon(
                                                Icons.map,
                                                size: 20,
                                              ),
                                            ),
                                        onChanged: _onDivisionChanged,
                                        validator: (v) =>
                                            (v == null || v.isEmpty)
                                            ? "Required"
                                            : null,
                                      )
                                    : TextFormField(
                                        decoration: _in("Division").copyWith(
                                          prefixIcon: const Icon(
                                            Icons.map,
                                            size: 20,
                                          ),
                                        ),
                                        onChanged: (v) => selectedDivision = v,
                                      ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // District
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "District *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                districts.isNotEmpty
                                    ? DropdownButtonFormField<String>(
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        dropdownColor: isDarkMode
                                            ? Colors.grey[900]
                                            : Colors.white,
                                        iconEnabledColor: isDarkMode
                                            ? Colors.white
                                            : null,
                                        initialValue: selectedDistrict,
                                        items: districts
                                            .map(
                                              (d) => DropdownMenuItem(
                                                value: d,
                                                child: Text(d),
                                              ),
                                            )
                                            .toList(),
                                        decoration: _in("Select District")
                                            .copyWith(
                                              prefixIcon: const Icon(
                                                Icons.location_on,
                                                size: 20,
                                              ),
                                            ),
                                        onChanged: _onDistrictChanged,
                                        validator: (v) =>
                                            (v == null || v.isEmpty)
                                            ? "Required"
                                            : null,
                                      )
                                    : TextFormField(
                                        decoration: _in("District").copyWith(
                                          prefixIcon: const Icon(
                                            Icons.location_on,
                                            size: 20,
                                          ),
                                        ),
                                        onChanged: (v) => selectedDistrict = v,
                                      ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Tehsil & City Row
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Tehsil *",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      tehsilsForDistrict.isNotEmpty
                                          ? DropdownButtonFormField<String>(
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                              dropdownColor: isDarkMode
                                                  ? Colors.grey[900]
                                                  : Colors.white,
                                              iconEnabledColor: isDarkMode
                                                  ? Colors.white
                                                  : null,
                                              initialValue:
                                                  tcTehsil.text.isNotEmpty
                                                  ? tcTehsil.text
                                                  : null,
                                              items: tehsilsForDistrict
                                                  .map(
                                                    (t) => DropdownMenuItem(
                                                      value: t,
                                                      child: Text(t),
                                                    ),
                                                  )
                                                  .toList(),
                                              decoration: _in("Tehsil")
                                                  .copyWith(
                                                    prefixIcon: const Icon(
                                                      Icons.location_searching,
                                                      size: 20,
                                                    ),
                                                  ),
                                              onChanged: (v) {
                                                setState(
                                                  () => tcTehsil.text = v ?? "",
                                                );
                                              },
                                            )
                                          : TextFormField(
                                              controller: tcTehsil,
                                              decoration: _in("Tehsil")
                                                  .copyWith(
                                                    prefixIcon: const Icon(
                                                      Icons.location_searching,
                                                      size: 20,
                                                    ),
                                                  ),
                                              textInputAction:
                                                  TextInputAction.next,
                                              onFieldSubmitted: (_) =>
                                                  FocusScope.of(
                                                    context,
                                                  ).requestFocus(fnAddress),
                                            ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "City *",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      citiesForDistrict.isNotEmpty
                                          ? DropdownButtonFormField<String>(
                                              style: TextStyle(
                                                color: isDarkMode
                                                    ? Colors.white
                                                    : Colors.black87,
                                              ),
                                              dropdownColor: isDarkMode
                                                  ? Colors.grey[900]
                                                  : Colors.white,
                                              iconEnabledColor: isDarkMode
                                                  ? Colors.white
                                                  : null,
                                              initialValue:
                                                  tcCity.text.isNotEmpty
                                                  ? tcCity.text
                                                  : null,
                                              items: citiesForDistrict
                                                  .map(
                                                    (c) => DropdownMenuItem(
                                                      value: c,
                                                      child: Text(c),
                                                    ),
                                                  )
                                                  .toList(),
                                              decoration: _in("Select City")
                                                  .copyWith(
                                                    prefixIcon: const Icon(
                                                      Icons.location_city,
                                                      size: 20,
                                                    ),
                                                  ),
                                              onChanged: (v) {
                                                setState(
                                                  () => tcCity.text = v ?? "",
                                                );
                                              },
                                            )
                                          : TextFormField(
                                              controller: tcCity,
                                              decoration: _in("City").copyWith(
                                                prefixIcon: const Icon(
                                                  Icons.location_city,
                                                  size: 20,
                                                ),
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Union Council (UC)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Union Council (UC) *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: tcUc,
                                  decoration: _in("Enter your UC").copyWith(
                                    prefixIcon: const Icon(
                                      Icons.account_balance,
                                      size: 20,
                                    ),
                                  ),
                                  validator: _validateRequired,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Address
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Complete Address *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: tcAddress,
                                  decoration: _in("Enter your complete address")
                                      .copyWith(
                                        prefixIcon: const Icon(
                                          Icons.home,
                                          size: 20,
                                        ),
                                      ),
                                  maxLines: 3,
                                  validator: _validateRequired,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Removed duplicate Address field to avoid redundancy

                            // Professional Information
                            const Text(
                              "Professional Information",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Education
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Education *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: tcEducation,
                                  decoration: _in("Enter your education")
                                      .copyWith(
                                        prefixIcon: const Icon(
                                          Icons.school,
                                          size: 20,
                                        ),
                                      ),
                                  validator: _validateRequired,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Profession
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Profession *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: tcProfession,
                                  decoration: _in("Enter your profession")
                                      .copyWith(
                                        prefixIcon: const Icon(
                                          Icons.work,
                                          size: 20,
                                        ),
                                      ),
                                  validator: _validateRequired,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Designation Dropdown
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Designation *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                DropdownButtonFormField<String>(
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                  dropdownColor: isDarkMode
                                      ? Colors.grey[900]
                                      : Colors.white,
                                  iconEnabledColor: isDarkMode
                                      ? Colors.white
                                      : null,
                                  value: tcDesignation.text.isNotEmpty
                                      ? tcDesignation.text
                                      : null,
                                  items: designations
                                      .map(
                                        (d) => DropdownMenuItem(
                                          value: d,
                                          child: Text(d),
                                        ),
                                      )
                                      .toList(),
                                  decoration: _in("Select Designation")
                                      .copyWith(
                                        prefixIcon: const Icon(
                                          Icons.badge,
                                          size: 20,
                                        ),
                                      ),
                                  onChanged: (value) {
                                    setState(() {
                                      tcDesignation.text = value ?? "";
                                    });
                                  },
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? "Required"
                                      : null,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Designation Area
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Designation Area *",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: tcDesignationArea,
                                  decoration: _in("Enter designation area")
                                      .copyWith(
                                        prefixIcon: const Icon(
                                          Icons.location_on,
                                          size: 20,
                                        ),
                                      ),
                                  validator: _validateRequired,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            if (submitting)
                              Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: uploadProgress,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "${(uploadProgress * 100).toStringAsFixed(0)}% uploaded",
                                  ),
                                ],
                              ),

                            const SizedBox(height: 12),

                            // CNIC Photos (vertical, full-width)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Front
                                GestureDetector(
                                  onTap: () => _pickImage('front'),
                                  child: Container(
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[900]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                        (cnicFrontBytes != null ||
                                            fileCnicFront != null)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: cnicFrontBytes != null
                                                ? Image.memory(
                                                    cnicFrontBytes!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                  )
                                                : Image.file(
                                                    fileCnicFront!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                  ),
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.credit_card,
                                                  size: 36,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  "CNIC Front / شناختی کارڈ سامنے",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "Tap to upload",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                // Back
                                GestureDetector(
                                  onTap: () => _pickImage('back'),
                                  child: Container(
                                    height: 140,
                                    decoration: BoxDecoration(
                                      color: isDarkMode
                                          ? Colors.grey[900]
                                          : Colors.grey[100],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDarkMode
                                            ? Colors.white
                                            : Colors.grey.shade300,
                                        width: 2,
                                      ),
                                    ),
                                    child:
                                        (cnicBackBytes != null ||
                                            fileCnicBack != null)
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: cnicBackBytes != null
                                                ? Image.memory(
                                                    cnicBackBytes!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                  )
                                                : Image.file(
                                                    fileCnicBack!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                  ),
                                          )
                                        : Center(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.credit_card,
                                                  size: 36,
                                                  color: Colors.grey.shade600,
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  "CNIC Back / شناختی کارڈ پچھلا",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade700,
                                                    fontSize: 13,
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "Tap to upload",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // Submit Button
                            Container(
                              width: double.infinity,
                              height: 64,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF0B7A3B),
                                    Color(0xFF14A44D),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x330B7A3B),
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                    horizontal: 20,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: submitting ? null : _submit,
                                child: submitting
                                    ? const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Text(
                                            "Submitting...",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.app_registration,
                                            color: Colors.white,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            "Register Member",
                                            style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),

                            const SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final isCompact = constraints.maxWidth < 420;
        return ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Colors.black.withOpacity(0.25)
                    : Colors.white.withOpacity(0.12),
                border: const Border(
                  top: BorderSide(color: Color(0xFFFFD700), width: 3),
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 10 : 16,
                vertical: isCompact ? 8 : 10,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.language),
                          tooltip: 'Website',
                          onPressed: () => launchUrl(
                            Uri.parse(AppConstants.contactWebsite),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.facebook),
                          tooltip: 'Facebook',
                          onPressed: () => launchUrl(
                            Uri.parse(AppConstants.contactFacebook),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat),
                          tooltip: 'WhatsApp',
                          onPressed: () => launchUrl(
                            Uri.parse(AppConstants.contactWhatsAppWaMe),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.camera_alt),
                          tooltip: 'Instagram',
                          onPressed: () => launchUrl(
                            Uri.parse(AppConstants.contactInstagram),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill),
                          tooltip: 'YouTube',
                          onPressed: () => launchUrl(
                            Uri.parse(AppConstants.contactYouTube),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.alternate_email),
                          tooltip: 'Twitter / X',
                          onPressed: () => launchUrl(
                            Uri.parse(AppConstants.contactTwitterX),
                            mode: LaunchMode.externalApplication,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone),
                          tooltip: AppConstants.contactPhone,
                          onPressed: () => launchUrl(
                            Uri.parse('tel:${AppConstants.contactPhone}'),
                          ),
                        ),
                      ],
                    ),
                    if (!isCompact)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Chairman Pakistan Haji Taj Muhammad Khan',
                          style: TextStyle(
                            color: isDarkMode ? Colors.white70 : Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
