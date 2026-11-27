import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../constants/app_colors.dart';
import '../routes/app_routes.dart';
import '../services/auth_service.dart';
import '../services/onboarding_service.dart';

/// Genre option data shown in Step 2
class _Genre {
  final String label;
  final String emoji;
  const _Genre(this.label, this.emoji);
}

const _kGenreOptions = [
  _Genre('Bollywood', '🎬'),
  _Genre('Punjabi', '🎺'),
  _Genre('Gujarati', '🪘'),
  _Genre('Romantic', '💕'),
  _Genre('Party', '🎉'),
  _Genre('Pop', '🌟'),
  _Genre('Hip-Hop/Rap', '🎤'),
  _Genre('Rock', '🎸'),
  _Genre('Lo-Fi', '🎧'),
  _Genre('Chill', '🌊'),
  _Genre('Classical', '🎻'),
  _Genre('R&B / Soul', '🎷'),
  _Genre('Electronic', '⚡'),
  _Genre('Jazz', '🎹'),
  _Genre('Acoustic', '🪕'),
];

class OnboardingScreen extends StatefulWidget {
  /// When [isFromJoinBlend] is true (guest tapping Join Blend) we skip Step 1
  /// entirely because they already gave their name in the join sheet.
  const OnboardingScreen({super.key, this.isFromJoinBlend = false});
  final bool isFromJoinBlend;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  final _nameCtrl = TextEditingController();
  final Set<String> _selectedGenres = {};
  int _currentPage = 0;
  bool _isSaving = false;

  // Total pages: 2 (name + genre).
  // If guest coming from join-blend flow we start directly on page 1.
  int get _totalPages => 2;

  @override
  void initState() {
    super.initState();
    final startPage = widget.isFromJoinBlend ? 1 : 0;
    _currentPage = startPage;
    _pageController = PageController(initialPage: startPage);

    // Pre-fill name if the auth service already has one
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    if (auth != null) {
      if (auth.isLoggedIn.value && auth.userName.value.isNotEmpty) {
        _nameCtrl.text = auth.userName.value;
      } else if (auth.guestUserName.value.isNotEmpty &&
          auth.guestUserName.value != 'Music Lover') {
        _nameCtrl.text = auth.guestUserName.value;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);
    HapticFeedback.mediumImpact();

    final name = _nameCtrl.text.trim();
    final genres = _selectedGenres.toList();

    // Persist to OnboardingService
    await OnboardingService().completeOnboarding(name: name, genres: genres);

    // Also update AuthService guest name if not logged in
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    if (auth != null && !auth.isLoggedIn.value && name.isNotEmpty) {
      await auth.updateGuestName(name);
    }

    // Navigate to main app
    Get.offAllNamed(AppRoutes.catalogue);
  }

  void _skip() {
    // Allow user to skip genre selection but still mark done
    _finish();
  }

  // ── build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Color(0xFF0A0A0A),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        resizeToAvoidBottomInset: true,
        body: SafeArea(
          child: Column(
            children: [
              // ── Progress bar ──────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(24.w, 18.h, 24.w, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Step indicator text
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Step ${_currentPage + 1} of $_totalPages',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_currentPage == _totalPages - 1)
                          GestureDetector(
                            onTap: _skip,
                            child: Text(
                              'Skip',
                              style: TextStyle(
                                color: Colors.white38,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 10.h),
                    // Segmented progress bar
                    Row(
                      children: List.generate(_totalPages, (i) {
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeOut,
                            margin: EdgeInsets.only(right: i < _totalPages - 1 ? 6.w : 0),
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: i <= _currentPage
                                  ? AppColors.primary
                                  : Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),

              // ── Page content ──────────────────────────────────────
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (p) => setState(() => _currentPage = p),
                  children: [
                    _buildNamePage(),
                    _buildGenrePage(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: Name ───────────────────────────────────────────────────────────

  Widget _buildNamePage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 28.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 36.h),
          // 3D Musical Mascot Avatar
          Container(
            width: 96.w,
            height: 96.w,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF1DB954), Color(0xFF00897B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 24,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/mascot_avatar.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.surfaceLight,
                  child: const Center(
                    child: Text('👋', style: TextStyle(fontSize: 34)),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            "What's your name?",
            style: TextStyle(
              color: Colors.white,
              fontSize: 26.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            'This name will appear in Blends you join so friends know who you are.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 32.h),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'e.g. Nikhil',
              hintStyle: TextStyle(color: Colors.white30, fontSize: 18.sp),
              prefixIcon: const Icon(Icons.person_rounded, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16.r),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onSubmitted: (_) => _next(),
          ),
          const Spacer(),
          _buildNextButton(
            label: 'Continue',
            onTap: () {
              if (_nameCtrl.text.trim().isEmpty) {
                Get.snackbar(
                  'Name Required',
                  'Please enter your name to continue.',
                  snackPosition: SnackPosition.BOTTOM,
                  backgroundColor: const Color(0xFF1E1E1E),
                  colorText: Colors.white,
                  duration: const Duration(seconds: 2),
                );
                return;
              }
              _next();
            },
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  // ── Step 2: Genre Selection ────────────────────────────────────────────────

  Widget _buildGenrePage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(28.w, 44.h, 28.w, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72.w,
                height: 72.w,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8C00FF), Color(0xFF1DB954)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.r),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8C00FF).withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Center(
                  child: Text('🎵', style: TextStyle(fontSize: 34.sp)),
                ),
              ),
              SizedBox(height: 28.h),
              Text(
                'What music do you love?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'Pick up to 3 of your favourites (${_selectedGenres.length}/3) and we\'ll personalise your Home feed.',
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14.sp,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
        // Genre grid
        Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: StatefulBuilder(builder: (context, setInner) {
              return GridView.builder(
                padding: EdgeInsets.only(bottom: 16.h),
                physics: const BouncingScrollPhysics(),
                itemCount: _kGenreOptions.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 10.w,
                  mainAxisSpacing: 10.h,
                  childAspectRatio: 1.5,
                ),
                itemBuilder: (_, i) {
                  final g = _kGenreOptions[i];
                  final selected = _selectedGenres.contains(g.label);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        if (selected) {
                          _selectedGenres.remove(g.label);
                        } else {
                          if (_selectedGenres.length >= 3) {
                            Get.snackbar(
                              'Maximum 3 Genres',
                              'You can choose up to 3 favorite genres.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: const Color(0xFF242424),
                              colorText: Colors.white,
                              duration: const Duration(seconds: 2),
                              margin: EdgeInsets.all(16.w),
                              borderRadius: 12.r,
                            );
                            return;
                          }
                          _selectedGenres.add(g.label);
                        }
                      });
                      setInner(() {});
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : Colors.white.withValues(alpha: 0.1),
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(g.emoji, style: TextStyle(fontSize: 22.sp)),
                          SizedBox(height: 4.h),
                          Text(
                            g.label,
                            style: TextStyle(
                              color: selected ? AppColors.primary : Colors.white70,
                              fontSize: 10.5.sp,
                              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(28.w, 0, 28.w, 20.h),
          child: _buildNextButton(
            label: _isSaving
                ? 'Setting up…'
                : (_selectedGenres.isEmpty ? 'Start with All Music' : 'Let\'s Go!'),
            onTap: _isSaving ? null : _finish,
          ),
        ),
      ],
    );
  }

  // ── Shared button widget ───────────────────────────────────────────────────

  Widget _buildNextButton({required String label, VoidCallback? onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26.r),
          ),
          elevation: 0,
        ),
        child: _isSaving && onTap == null
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.black,
                ),
              ),
      ),
    );
  }
}
