import 'package:flutter/material.dart';
import '../../services/database_helper.dart';
import '../../services/user_service.dart';
import '../../models/center_model.dart';
import '../../services/firestore_service.dart';
import 'main_navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  int _currentPage = 0;

  // Controllers for user profile inputs
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _middleNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _areaController = TextEditingController();
  final TextEditingController _localCenterController = TextEditingController();
  final TextEditingController _centerAddressController =
      TextEditingController();
  final TextEditingController _memberIdController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _positionController = TextEditingController();

  // Database state options
  List<String> _districts = [];
  List<CenterModel> _centerOptions = [];
  String? _selectedDistrict;
  CenterModel? _selectedCenter;

  // Area dropdown options: Area 1 to Area 6, plus Custom / Enter Manually
  final List<String> _areaDropdownOptions = [
    'Area 1',
    'Area 2',
    'Area 3',
    'Area 4',
    'Area 5',
    'Area 6',
    'Custom / Enter Manually',
  ];
  String? _selectedAreaDropdown;

  // Manual input toggles
  bool _isManualDistrict = false;
  bool _isManualCenter = false;
  bool _isManualArea = false;
  bool _isLoadingDb = true;
  bool _hasAcceptedTerms = false;

  @override
  void initState() {
    super.initState();
    final uniqueNum = DateTime.now().millisecondsSinceEpoch
        .toString()
        .substring(7);
    _memberIdController.text = 'USER$uniqueNum';
    _positionController.text = 'Member';
    _loadDatabaseData();
  }

  Future<void> _loadDatabaseData() async {
    try {
      final districts = await DatabaseHelper.getDistricts();
      setState(() {
        _districts = districts;
        _isLoadingDb = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingDb = false;
      });
    }
  }

  Future<void> _onDistrictSelected(String? district) async {
    if (district == 'Other / Enter Manually') {
      setState(() {
        _isManualDistrict = true;
        _selectedDistrict = null;
        _districtController.clear();
        _centerOptions = [];
        _selectedCenter = null;
        _localCenterController.clear();
        _centerAddressController.clear();
      });
      return;
    }

    setState(() {
      _isManualDistrict = false;
      _selectedDistrict = district;
      _districtController.text = district ?? '';
      _selectedCenter = null;
      _localCenterController.clear();
      _centerAddressController.clear();
    });

    if (district != null && district.isNotEmpty) {
      final centers = await DatabaseHelper.getCentersForDistrict(district);
      setState(() {
        _centerOptions = centers;
      });
    } else {
      setState(() {
        _centerOptions = [];
      });
    }
  }

  void _onCenterSelected(CenterModel? center) {
    if (center == null) return;

    setState(() {
      _selectedCenter = center;
      _localCenterController.text = center.name;
      _centerAddressController.text = center.address;

      // Handle Area pre-selection from database center data
      final rawArea = center.area.trim();
      if (rawArea.isNotEmpty) {
        // Match 1..6 or Area 1..6
        final cleanNum = rawArea.replaceAll(RegExp(r'[^0-9]'), '');
        if (cleanNum.isNotEmpty &&
            ['1', '2', '3', '4', '5', '6'].contains(cleanNum)) {
          final matchedArea = 'Area $cleanNum';
          _selectedAreaDropdown = matchedArea;
          _areaController.text = matchedArea;
          _isManualArea = false;
        } else {
          _selectedAreaDropdown = 'Custom / Enter Manually';
          _areaController.text = rawArea;
          _isManualArea = true;
        }
      }
    });
  }

  void _onAreaDropdownSelected(String? val) {
    if (val == null) return;

    if (val == 'Custom / Enter Manually') {
      setState(() {
        _selectedAreaDropdown = val;
        _isManualArea = true;
        _areaController.clear();
      });
    } else {
      setState(() {
        _selectedAreaDropdown = val;
        _isManualArea = false;
        _areaController.text = val;
      });
    }
  }

  Future<void> _onFinishOnboarding() async {
    final nickname = _nicknameController.text.trim().isEmpty
        ? 'Member'
        : _nicknameController.text.trim();
    final email = _emailController.text.trim();

    final district = _districtController.text.trim().isEmpty
        ? 'Default District'
        : _districtController.text.trim();
    final area = _areaController.text.trim().isEmpty
        ? 'Default Area'
        : _areaController.text.trim();
    final localCenter = _localCenterController.text.trim().isEmpty
        ? 'MAIN CENTER'
        : _localCenterController.text.trim().toUpperCase();
    final centerAddress = _centerAddressController.text.trim();
    final memberId = _memberIdController.text.trim();
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final position = _positionController.text.trim().isEmpty
        ? 'Member'
        : _positionController.text.trim();

    await UserService.instance.updateProfile(
      nickname: nickname,
      district: district,
      area: area,
      localCenter: localCenter,
      centerAddress: centerAddress,
      memberId: memberId,
      email: email,
      firstName: firstName,
      middleName: middleName,
      lastName: lastName,
      position: position,
    );

    // Save profile online to Firestore
    try {
      await FirestoreService().saveUserProfile(
        uid: memberId,
        email: email,
        name: nickname,
        firstName: firstName,
        middleName: middleName,
        surname: lastName,
        position: position,
        district: district,
        area: _extractDigits(area),
        centerName: localCenter,
        centerAddress: centerAddress,
      );
    } catch (e) {
      debugPrint('Error saving user profile to Firestore: $e');
    }

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainNavigationScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nicknameController.dispose();
    _firstNameController.dispose();
    _middleNameController.dispose();
    _lastNameController.dispose();
    _districtController.dispose();
    _areaController.dispose();
    _localCenterController.dispose();
    _centerAddressController.dispose();
    _memberIdController.dispose();
    _emailController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Widget _buildWelcomeSlide(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 3,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Image.asset(
                'assets/images/brand_mark.png',
                fit: BoxFit.contain,
              ),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Welcome to UECFI APP',
            style: theme.textTheme.displayMedium?.copyWith(fontSize: 26),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Your spiritual home for daily worship, prayer, fellowship, and staying connected with your local center.',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.textTheme.bodySmall?.color,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSlide(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Terms & Agreements',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Please review and accept our guidelines before continuing.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 20),

          // Scrollable Card showing the Terms text
          Container(
            height: 320,
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor, width: 1),
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTermSection(
                      title: '1. Acceptance of Terms',
                      description:
                          'By accessing and using this application, you accept and agree to be bound by the terms and provisions of this agreement.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTermSection(
                      title: '2. Purpose and Conduct',
                      description:
                          'This application is designed to foster community and spiritual growth. Users are expected to maintain respectful, appropriate, and constructive conduct in all interactions.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTermSection(
                      title: '3. User Submissions',
                      description:
                          'Any content submitted by users (such as posts, comments, or directory updates) must not be malicious, offensive, or infringe upon the rights of others.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTermSection(
                      title: '4. Privacy and Data',
                      description:
                          'We are committed to protecting your privacy. Personal information collected through forms or profiles will be used solely for community directory and application functionality purposes.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTermSection(
                      title: '5. Intellectual Property',
                      description:
                          'All content included on the app, such as text, graphics, logos, images, and software, is the property of the organization or its content suppliers.',
                      theme: theme,
                    ),
                    const SizedBox(height: 16),
                    _buildTermSection(
                      title: '6. Disclaimer',
                      description:
                          'The application and its content are provided "as is". We make no warranties regarding the accuracy or completeness of the informational directories provided.',
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Checkbox / Switch to Accept Terms
          Row(
            children: [
              Checkbox(
                value: _hasAcceptedTerms,
                onChanged: (val) {
                  setState(() {
                    _hasAcceptedTerms = val ?? false;
                  });
                },
                activeColor: theme.colorScheme.primary,
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _hasAcceptedTerms = !_hasAcceptedTerms;
                    });
                  },
                  child: Text(
                    'I accept and agree to the Terms & Agreements',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTermSection({
    required String title,
    required String description,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodySmall?.copyWith(height: 1.4, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildProfileSlide(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            'What should we call you?',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter your preferred nickname so we can personalize your experience.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'First Name',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _firstNameController,
            decoration: const InputDecoration(hintText: 'e.g. John'),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your first name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Text(
            'Middle Name',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _middleNameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Smith (Optional)',
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'Last Name',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _lastNameController,
            decoration: const InputDecoration(hintText: 'e.g. Doe'),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your last name';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Text(
            'Preferred Nickname',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              hintText: 'e.g. Hermano. John, Hermana Mary',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your preferred nickname';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          Text(
            'Member ID (Unique)',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _memberIdController,
            enabled: false,
            decoration: const InputDecoration(hintText: 'Unique Member ID'),
          ),
          const SizedBox(height: 16),

          Text(
            'Email Address',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'e.g. john.doe@example.com',
            ),
            validator: (val) {
              if (val == null || val.trim().isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(val.trim())) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildChurchInfoSlide(ThemeData theme) {
    final bool isDistrictSelected =
        _isManualDistrict || _selectedDistrict != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Church Information',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Select your district and local center from the UECFI registry.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 20),

          // District Dropdown / Manual Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'District',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isManualDistrict = !_isManualDistrict;
                    if (_isManualDistrict) {
                      _selectedDistrict = null;
                      _districtController.clear();
                      _centerOptions = [];
                      _selectedCenter = null;
                      _localCenterController.clear();
                      _centerAddressController.clear();
                    }
                  });
                },
                child: Text(
                  _isManualDistrict ? 'Use Dropdown' : 'Enter Manually',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_isManualDistrict || _isLoadingDb)
            TextFormField(
              controller: _districtController,
              decoration: const InputDecoration(hintText: 'e.g. District 1'),
            )
          else
            DropdownButtonFormField<String>(
              initialValue: _selectedDistrict,
              isExpanded: true,
              hint: const Text('Select District'),
              decoration: const InputDecoration(),
              items: [
                ..._districts.map(
                  (d) => DropdownMenuItem(
                    value: d,
                    child: Text(d, overflow: TextOverflow.ellipsis),
                  ),
                ),
                const DropdownMenuItem(
                  value: 'Other / Enter Manually',
                  child: Text(
                    'Other / Enter Manually...',
                    style: TextStyle(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
              onChanged: _onDistrictSelected,
            ),
          const SizedBox(height: 16),

          // Local Center Dropdown / Manual Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Local Center',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              GestureDetector(
                onTap: isDistrictSelected
                    ? () {
                        setState(() {
                          _isManualCenter = !_isManualCenter;
                          if (_isManualCenter) {
                            _selectedCenter = null;
                            _localCenterController.clear();
                            _centerAddressController.clear();
                          }
                        });
                      }
                    : null,
                child: Text(
                  _isManualCenter ? 'Use Dropdown' : 'Enter Manually',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDistrictSelected
                        ? theme.colorScheme.primary
                        : theme.disabledColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (_isManualCenter || _centerOptions.isEmpty)
            TextFormField(
              controller: _localCenterController,
              enabled: isDistrictSelected,
              decoration: InputDecoration(
                hintText: !isDistrictSelected
                    ? 'Select a District first or enter manually'
                    : 'e.g. Central Worship Center',
              ),
            )
          else
            DropdownButtonFormField<CenterModel>(
              initialValue: _selectedCenter,
              isExpanded: true,
              hint: const Text('Select Local Center'),
              decoration: const InputDecoration(),
              items: isDistrictSelected
                  ? _centerOptions.map((center) {
                      return DropdownMenuItem<CenterModel>(
                        value: center,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              center.name,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              center.address,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList()
                  : null,
              selectedItemBuilder: isDistrictSelected
                  ? (BuildContext context) {
                      return _centerOptions.map((center) {
                        return Text(
                          center.name,
                          overflow: TextOverflow.ellipsis,
                        );
                      }).toList();
                    }
                  : null,
              onChanged: isDistrictSelected ? _onCenterSelected : null,
            ),
          const SizedBox(height: 16),

          // Area Dropdown (1 to 6) / Manual Input
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Area',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              ),
              GestureDetector(
                onTap: isDistrictSelected
                    ? () {
                        setState(() {
                          _isManualArea = !_isManualArea;
                          if (_isManualArea) {
                            _selectedAreaDropdown = 'Custom / Enter Manually';
                            _areaController.clear();
                          }
                        });
                      }
                    : null,
                child: Text(
                  _isManualArea ? 'Use Dropdown' : 'Enter Manually',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDistrictSelected
                        ? theme.colorScheme.primary
                        : theme.disabledColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          if (!_isManualArea)
            DropdownButtonFormField<String>(
              initialValue: _selectedAreaDropdown,
              isExpanded: true,
              hint: const Text('Select Area (1 - 6)'),
              decoration: const InputDecoration(),
              items: isDistrictSelected
                  ? _areaDropdownOptions.map((opt) {
                      return DropdownMenuItem<String>(
                        value: opt,
                        child: Text(opt),
                      );
                    }).toList()
                  : null,
              onChanged: isDistrictSelected ? _onAreaDropdownSelected : null,
            ),

          if (_isManualArea) ...[
            TextFormField(
              controller: _areaController,
              enabled: isDistrictSelected,
              decoration: const InputDecoration(
                hintText: 'e.g. Area 7, North Sector',
              ),
            ),
          ],
          const SizedBox(height: 16),

          // Center Address
          Text(
            'Center Address',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _centerAddressController,
            maxLines: 2,
            enabled: isDistrictSelected && _isManualCenter,
            decoration: const InputDecoration(
              hintText: 'Center street address or location details',
            ),
          ),
          const SizedBox(height: 16),

          // Position in Church
          Text(
            'Position in Church',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _positionController,
            decoration: const InputDecoration(
              hintText: 'e.g. Member, President, Medium, Vice-President',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummarySlide(ThemeData theme) {
    final name = _nicknameController.text.trim().isEmpty
        ? 'Member'
        : _nicknameController.text.trim();
    final district = _districtController.text.trim().isEmpty
        ? 'Not specified'
        : _districtController.text.trim();
    final area = _areaController.text.trim().isEmpty
        ? 'Not specified'
        : _areaController.text.trim();
    final center = _localCenterController.text.trim().isEmpty
        ? 'Not specified'
        : _localCenterController.text.trim().toUpperCase();
    final address = _centerAddressController.text.trim().isEmpty
        ? 'Not specified'
        : _centerAddressController.text.trim();
    final memberId = _memberIdController.text.trim();
    final email = _emailController.text.trim();
    final position = _positionController.text.trim().isEmpty
        ? 'Member'
        : _positionController.text.trim();
    final firstName = _firstNameController.text.trim();
    final middleName = _middleNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final fullName =
        '$firstName ${middleName.isEmpty ? "" : "$middleName "}$lastName';

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_rounded,
              size: 56,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'You are all set!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Review your information below. You can update this anytime in settings.',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // Summary Card (Flat Facebook Card Style)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor, width: 1),
            ),
            child: Column(
              children: [
                _buildSummaryRow(
                  theme: theme,
                  icon: Icons.badge_outlined,
                  label: 'Member ID',
                  value: memberId,
                ),
                Divider(color: theme.dividerColor, height: 24),
                _buildSummaryRow(
                  theme: theme,
                  icon: Icons.email_outlined,
                  label: 'Email Address',
                  value: email,
                ),
                Divider(color: theme.dividerColor, height: 24),
                _buildSummaryRow(
                  theme: theme,
                  icon: Icons.person_outline_rounded,
                  label: 'Nickname',
                  value: name,
                ),
                Divider(color: theme.dividerColor, height: 24),
                _buildSummaryRow(
                  theme: theme,
                  icon: Icons.person_rounded,
                  label: 'Full Name',
                  value: fullName,
                ),
                Divider(color: theme.dividerColor, height: 24),
                _buildSummaryRow(
                  theme: theme,
                  icon: Icons.map_outlined,
                  label: 'District & Area',
                  value: '$district • $area',
                ),
                Divider(color: theme.dividerColor, height: 24),
                _buildSummaryRow(
                  theme: theme,
                  icon: Icons.church_outlined,
                  label: 'Local Center',
                  value: center,
                ),
                if (address != 'Not specified') ...[
                  Divider(color: theme.dividerColor, height: 24),
                  _buildSummaryRow(
                    theme: theme,
                    icon: Icons.place_outlined,
                    label: 'Center Address',
                    value: address,
                  ),
                ],
                Divider(color: theme.dividerColor, height: 24),
                _buildSummaryRow(
                  theme: theme,
                  icon: Icons.work_outline_rounded,
                  label: 'Position in Church',
                  value: position,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const totalPages = 5;
    final isLastPage = _currentPage == totalPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    )
                  else
                    const SizedBox(width: 48),
                  const SizedBox(width: 48),
                ],
              ),
            ),

            // Form PageView
            Expanded(
              child: Form(
                key: _formKey,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  children: [
                    _buildWelcomeSlide(theme),
                    _buildTermsSlide(theme),
                    _buildProfileSlide(theme),
                    _buildChurchInfoSlide(theme),
                    _buildSummarySlide(theme),
                  ],
                ),
              ),
            ),

            // Bottom Control Area
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  // Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      totalPages,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 28 : 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primary.withValues(
                                  alpha: 0.2,
                                ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Next / Finish Button (Solid Facebook Blue Button)
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: (_currentPage == 1 && !_hasAcceptedTerms)
                          ? null
                          : () async {
                              if (_currentPage == 2) {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }

                                final messenger = ScaffoldMessenger.of(context);
                                final navigator = Navigator.of(context);

                                // Show loading overlay
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (dialogContext) => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );

                                final nickname =
                                    _nicknameController.text.trim().isEmpty
                                    ? 'Member'
                                    : _nicknameController.text.trim();
                                final email = _emailController.text.trim();

                                bool hasError = false;

                                try {
                                  final exists = await FirestoreService()
                                      .checkNicknameExists(nickname);
                                  if (exists) {
                                    hasError = true;
                                    navigator.pop(); // dismiss loading
                                    messenger.showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Nickname is already taken. Please choose a different one.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor: Colors.orangeAccent,
                                      ),
                                    );
                                    return;
                                  }

                                  if (email.isNotEmpty) {
                                    final emailExists = await FirestoreService()
                                        .checkEmailExists(email);
                                    if (emailExists) {
                                      hasError = true;
                                      navigator.pop(); // dismiss loading
                                      messenger.showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'This email address is already registered. Please use a different email or recover your profile in Settings.',
                                          ),
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: Colors.orangeAccent,
                                        ),
                                      );
                                      return;
                                    }
                                  }
                                } catch (e) {
                                  debugPrint(
                                    'Error verifying details during onboarding: $e',
                                  );
                                }

                                if (!hasError) {
                                  navigator.pop(); // dismiss loading
                                }
                              } else if (_currentPage == 3) {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }
                              }

                              if (isLastPage) {
                                _onFinishOnboarding();
                              } else {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              }
                            },
                      style: FilledButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      child: Text(
                        isLastPage ? 'Get Started' : 'Continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _extractDigits(String text) {
    final match = RegExp(r'(\d+)').firstMatch(text);
    return match != null ? match.group(0)! : text;
  }
}
