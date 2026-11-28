import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../constants/app_colors.dart';
import '../controllers/player_controller.dart';
import '../models/blend_model.dart';
import '../services/auth_service.dart';
import '../services/blend_service.dart';
import '../services/email_template_service.dart';
import '../widgets/add_song_to_blend_sheet.dart';
import '../widgets/mini_player_bar.dart';
import '../widgets/music_wave_equalizer.dart';
import '../widgets/spotify_back_button.dart';

class BlendDetailScreen extends StatefulWidget {
  final BlendModel? blend;

  const BlendDetailScreen({super.key, this.blend});

  @override
  State<BlendDetailScreen> createState() => _BlendDetailScreenState();
}

class _BlendDetailScreenState extends State<BlendDetailScreen> {
  late BlendModel _blend;

  @override
  void initState() {
    super.initState();
    if (widget.blend != null) {
      _blend = widget.blend!;
    } else if (Get.arguments is BlendModel) {
      _blend = Get.arguments as BlendModel;
    } else {
      // Fallback
      _blend = BlendModel(
        id: '',
        name: 'Blend',
        code: '------',
        creatorUid: '',
        creatorName: 'Friend',
        memberUids: [],
        members: [],
      );
    }
  }

  void _shareBlend([BlendModel? blendOverride]) {
    final blend = blendOverride ?? _blend;
    _showShareBlendSheet(context, blend);
  }

  void _showSendEmailInviteDialog(BuildContext context, BlendModel blend) {
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    final initialEmail = auth?.userEmail.value ?? '';
    final emailCtrl = TextEditingController(text: initialEmail);

    showDialog(
      context: context,
      builder: (dlgContext) {
        bool isSending = false;
        return StatefulBuilder(
          builder: (context, setDlgState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF222222),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              title: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.email_rounded, color: AppColors.primary),
                  ),
                  SizedBox(width: 10.w),
                  Text(
                    'Send Email Invite',
                    style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sends a rich, styled HTML invitation email with your Blend code and magic link:',
                    style: TextStyle(color: Colors.white70, fontSize: 12.5.sp),
                  ),
                  SizedBox(height: 14.h),
                  TextField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(color: Colors.white, fontSize: 13.5.sp),
                    decoration: InputDecoration(
                      labelText: 'Recipient Email',
                      labelStyle: TextStyle(color: Colors.white60, fontSize: 12.sp),
                      hintText: 'friend@gmail.com',
                      hintStyle: TextStyle(color: Colors.white30, fontSize: 12.sp),
                      filled: true,
                      fillColor: Colors.white.withValues(alpha: 0.06),
                      prefixIcon: const Icon(Icons.alternate_email_rounded, color: Colors.white54),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending ? null : () => Navigator.pop(dlgContext),
                  child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          final email = emailCtrl.text.trim();
                          if (email.isEmpty || !email.contains('@')) {
                            Get.snackbar(
                              'Invalid Email',
                              'Please enter a valid email address.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.redAccent.withValues(alpha: 0.9),
                              colorText: Colors.white,
                            );
                            return;
                          }

                          setDlgState(() => isSending = true);
                          final success = await EmailTemplateService.sendBlendInviteEmail(
                            blend,
                            recipientEmail: email,
                          );
                          if (dlgContext.mounted) {
                            Navigator.pop(dlgContext);
                          }

                          if (success) {
                            Get.snackbar(
                              'Email Sent! ✉️',
                              'Formatted HTML invitation delivered to $email',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: const Color(0xFF2C2C2C),
                              colorText: Colors.white,
                              icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                              duration: const Duration(seconds: 4),
                            );
                          } else {
                            Get.snackbar(
                              'Send Failed',
                              'Could not deliver email. Please check your network connection.',
                              snackPosition: SnackPosition.BOTTOM,
                              backgroundColor: Colors.redAccent,
                              colorText: Colors.white,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                  ),
                  child: isSending
                      ? SizedBox(
                          width: 16.w,
                          height: 16.w,
                          child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Text('Send Invite', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showShareBlendSheet(BuildContext context, BlendModel blend) {
    HapticFeedback.lightImpact();
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    final userEmail = auth?.userEmail.value ?? '';
    final isLoggedInWithEmail = (auth?.isLoggedIn.value ?? false) && userEmail.isNotEmpty;
    final link = EmailTemplateService.getBlendLink(blend);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            systemNavigationBarColor: Color(0xFF1E1E1E),
            systemNavigationBarDividerColor: Colors.transparent,
            systemNavigationBarIconBrightness: Brightness.light,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
            ),
            child: SafeArea(
              top: false,
              bottom: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag Handle
                  Center(
                    child: Container(
                      width: 38.w,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),

                  // Header with Icon & Title
                  Row(
                    children: [
                      Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: blend.themeColor.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: blend.themeColor.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Center(
                          child: Text(blend.icon, style: TextStyle(fontSize: 18.sp)),
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Share "${blend.name}"',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Invite friends with your unique Blend code',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 11.5.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),

                  // Code Card with Tap to Copy
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Clipboard.setData(ClipboardData(text: blend.code));
                      Get.snackbar(
                        'Code Copied!',
                        'Blend code ${blend.code} copied to clipboard.',
                        snackPosition: SnackPosition.BOTTOM,
                        backgroundColor: const Color(0xFF2C2C2C),
                        colorText: Colors.white,
                        icon: const Icon(Icons.copy_rounded, color: AppColors.primary),
                        duration: const Duration(seconds: 2),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(
                          color: blend.themeColor.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'BLEND CODE',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 2.h),
                              Text(
                                blend.code,
                                style: TextStyle(
                                  color: blend.themeColor,
                                  fontSize: 24.sp,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 4.0,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                            decoration: BoxDecoration(
                              color: blend.themeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 14.sp, color: blend.themeColor),
                                SizedBox(width: 4.w),
                                Text(
                                  'Copy',
                                  style: TextStyle(
                                    color: blend.themeColor,
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 18.h),

                  // Option 1: Send HTML Invitation Email (Brevo Instant Delivery)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: const Icon(Icons.mark_email_read_rounded, color: AppColors.primary),
                    ),
                    title: const Text(
                      'Send HTML Invite to Email',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Delivers rich formatted card with join button & code',
                      style: TextStyle(color: Colors.white54, fontSize: 11.5.sp),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showSendEmailInviteDialog(context, blend);
                    },
                  ),

                  // Option 2: Send directly to My Email (if logged in)
                  if (isLoggedInWithEmail)
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        width: 40.w,
                        height: 40.w,
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: const Icon(Icons.send_rounded, color: Colors.blueAccent),
                      ),
                      title: const Text(
                        'Send Template to My Email',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                      ),
                      subtitle: Text(
                        'Direct delivery to $userEmail',
                        style: TextStyle(color: Colors.white54, fontSize: 11.5.sp),
                      ),
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        final success = await EmailTemplateService.sendBlendCreatedEmail(blend);
                        if (success) {
                          Get.snackbar(
                            'Email Delivered! ✉️',
                            'Formatted HTML template delivered to $userEmail',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: const Color(0xFF2C2C2C),
                            colorText: Colors.white,
                            icon: const Icon(Icons.check_circle_rounded, color: AppColors.primary),
                            duration: const Duration(seconds: 4),
                          );
                        } else {
                          Get.snackbar(
                            'Send Failed',
                            'Could not deliver email. Please check your network connection.',
                            snackPosition: SnackPosition.BOTTOM,
                            backgroundColor: Colors.redAccent,
                            colorText: Colors.white,
                          );
                        }
                      },
                    ),

                  // Option 3: Share to Apps (WhatsApp, Telegram, etc.)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: blend.themeColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Icon(Icons.share_rounded, color: blend.themeColor),
                    ),
                    title: const Text(
                      'Share to Apps',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'WhatsApp, Instagram, Telegram, SMS & apps',
                      style: TextStyle(color: Colors.white54, fontSize: 11.5.sp),
                    ),
                    onTap: () async {
                      Navigator.pop(sheetContext);
                      final shareMessage = '🎵 Join my "${blend.name}" Blend on WhatsPlay!\n\nBlend Code: ${blend.code}\n\nListen & blend music together in real-time:\n$link';
                      Clipboard.setData(ClipboardData(text: blend.code));
                      await SharePlus.instance.share(
                        ShareParams(
                          text: shareMessage,
                          subject: 'Join my "${blend.name}" Blend on WhatsPlay',
                        ),
                      );
                    },
                  ),

                  // Option 4: Open in Phone Email App (Compose)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: const Icon(Icons.open_in_new_rounded, color: Colors.white70),
                    ),
                    title: const Text(
                      'Open Phone Email App',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Compose via Gmail/Outlook app on device',
                      style: TextStyle(color: Colors.white54, fontSize: 11.5.sp),
                    ),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      EmailTemplateService.shareViaEmail(blend);
                    },
                  ),

                  SizedBox(height: 8.h),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final playerCtrl = Get.isRegistered<PlayerController>()
        ? Get.find<PlayerController>()
        : null;
    final blendService = Get.isRegistered<BlendService>()
        ? BlendService.to
        : Get.put(BlendService());
    final auth = Get.isRegistered<AuthService>() ? AuthService.to : null;
    final currentUid = auth?.currentUser.value?.uid ?? '';

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarDividerColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: AppColors.background,
        bottomNavigationBar: Container(
          color: const Color(0xFF1E1E1E),
          child: SafeArea(
            top: false,
            bottom: true,
            child: Get.isRegistered<PlayerController>()
                ? const MiniPlayerBar()
                : const SizedBox.shrink(),
          ),
        ),
        body: _blend.id.isEmpty
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : StreamBuilder<BlendModel?>(
                stream: blendService.getBlendStream(_blend.id),
                initialData: _blend,
                builder: (context, blendSnapshot) {
                  final currentBlend = blendSnapshot.data ?? _blend;

                  return StreamBuilder<List<BlendTrack>>(
                    stream: blendService.getBlendTracksStream(currentBlend.id),
                    builder: (context, snapshot) {
                      final tracks = snapshot.data ?? [];
                      final isLoading = snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData;

                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Hero Header with Dynamic Mood Gradient & Custom Emoji
                    SliverAppBar(
                      expandedHeight: 240.h,
                      pinned: true,
                      stretch: true,
                      backgroundColor: const Color(0xFF191919),
                      leadingWidth: 52.w,
                      titleSpacing: 8.w,
                      centerTitle: false,
                      leading: const SpotifyBackButton(),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.share_rounded, color: Colors.white),
                          tooltip: 'Share Blend Link',
                          onPressed: () => _shareBlend(currentBlend),
                        ),
                        IconButton(
                          icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                          onPressed: () => _showBlendOptionsMenu(context, blendService, currentUid, currentBlend),
                        ),
                        SizedBox(width: 8.w),
                      ],
                      flexibleSpace: FlexibleSpaceBar(
                        stretchModes: const [
                          StretchMode.zoomBackground,
                          StretchMode.blurBackground,
                        ],
                        background: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                currentBlend.gradientColors.first,
                                currentBlend.gradientColors.length > 1
                                    ? currentBlend.gradientColors[1]
                                    : currentBlend.themeColor,
                                const Color(0xFF121212),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  // Badge with Mood Icon
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.4),
                                          borderRadius: BorderRadius.circular(12.r),
                                          border: Border.all(
                                            color: currentBlend.themeColor.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              currentBlend.icon,
                                              style: TextStyle(fontSize: 12.sp),
                                            ),
                                            SizedBox(width: 5.w),
                                            Text(
                                              currentBlend.isOfficialBlend ? 'OFFICIAL BLEND' : 'SHARED BLEND',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10.5.sp,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      if (currentBlend.isOfficialBlend) ...[
                                        SizedBox(width: 8.w),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 9.w, vertical: 4.h),
                                          decoration: BoxDecoration(
                                            color: currentBlend.themeColor.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(12.r),
                                            border: Border.all(
                                              color: currentBlend.themeColor,
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.verified_rounded,
                                                color: currentBlend.themeColor,
                                                size: 13.sp,
                                              ),
                                              SizedBox(width: 4.w),
                                              Text(
                                                '✓ Official',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 10.5.sp,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: 0.5,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  SizedBox(height: 10.h),

                                  // Blend Emoji Avatar + Title with color shadow!
                                  Row(
                                    children: [
                                      Container(
                                        width: 44.w,
                                        height: 44.w,
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.45),
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: currentBlend.themeColor.withValues(alpha: 0.7),
                                            width: 1.5,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: currentBlend.themeColor.withValues(alpha: 0.45),
                                              blurRadius: 14,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: Text(
                                            currentBlend.icon,
                                            style: TextStyle(fontSize: 22.sp),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 12.w),
                                      Expanded(
                                        child: Text(
                                          currentBlend.name,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 24.sp,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.5,
                                            shadows: [
                                              Shadow(
                                                color: Colors.black.withValues(alpha: 0.7),
                                                blurRadius: 8,
                                              ),
                                            ],
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 10.h),

                                  // Members and Stats row
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (currentBlend.creatorName.isNotEmpty)
                                        Padding(
                                          padding: EdgeInsets.only(bottom: 6.h),
                                          child: Row(
                                            children: [
                                              Icon(
                                                Icons.verified_user_rounded,
                                                color: currentBlend.themeColor,
                                                size: 13.sp,
                                              ),
                                              SizedBox(width: 4.w),
                                              Flexible(
                                                child: Text(
                                                  'Created by ${currentBlend.creatorName}',
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 11.5.sp,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      Row(
                                        children: [
                                          _buildMembersAvatarStack(currentBlend.members),
                                          SizedBox(width: 10.w),
                                          Text(
                                            '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'} • ${currentBlend.members.length} ${currentBlend.members.length == 1 ? 'friend' : 'friends'}',
                                            style: TextStyle(
                                              color: Colors.white.withValues(alpha: 0.85),
                                              fontSize: 12.sp,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16.h),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Action Bar (Play All + Add Songs)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
                        child: Row(
                          children: [
                            // Play Button with matching theme color & shadow
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24.r),
                                boxShadow: tracks.isNotEmpty
                                    ? [
                                        BoxShadow(
                                          color: currentBlend.themeColor.withValues(alpha: 0.35),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: ElevatedButton.icon(
                                onPressed: tracks.isEmpty
                                    ? () => _showAddSongToBlendSheet(context, currentBlend, tracks)
                                    : () {
                                        final trackModels = tracks.map((t) => t.toTrackModel()).toList();
                                        playerCtrl?.playTrack(trackModels.first, queue: trackModels);
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: tracks.isNotEmpty
                                      ? currentBlend.themeColor
                                      : Colors.white.withValues(alpha: 0.08),
                                  foregroundColor: tracks.isNotEmpty
                                      ? (ThemeData.estimateBrightnessForColor(currentBlend.themeColor) == Brightness.dark
                                          ? Colors.white
                                          : Colors.black)
                                      : Colors.white54,
                                  side: tracks.isEmpty
                                      ? BorderSide(color: Colors.white.withValues(alpha: 0.15))
                                      : BorderSide.none,
                                  padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 11.h),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(24.r),
                                  ),
                                  elevation: 0,
                                ),
                                icon: Icon(
                                  Icons.play_arrow_rounded,
                                  size: 22.sp,
                                  color: tracks.isNotEmpty
                                      ? (ThemeData.estimateBrightnessForColor(currentBlend.themeColor) == Brightness.dark
                                          ? Colors.white
                                          : Colors.black)
                                      : Colors.white54,
                                ),
                                label: Text(
                                  'Play All',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.w800,
                                    color: tracks.isNotEmpty
                                        ? (ThemeData.estimateBrightnessForColor(currentBlend.themeColor) == Brightness.dark
                                            ? Colors.white
                                            : Colors.black)
                                        : Colors.white54,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 12.w),

                            // "+ Add Songs" Button
                            OutlinedButton.icon(
                              onPressed: () => _showAddSongToBlendSheet(context, currentBlend, tracks),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.25),
                                ),
                                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 11.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24.r),
                                ),
                              ),
                              icon: Icon(Icons.add_rounded, size: 18.sp, color: currentBlend.themeColor),
                              label: Text(
                                'Add Songs',
                                style: TextStyle(
                                  fontSize: 13.5.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                // Tracks List or Empty State
                if (isLoading)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppColors.primary,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                else if (tracks.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.w),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: EdgeInsets.all(20.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.05),
                              ),
                              child: Icon(
                                Icons.queue_music_rounded,
                                size: 48.sp,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'Blend is empty',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18.sp,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              'Tap "Add Songs" below or share the code (${_blend.code}) with friends to add tracks together in real-time!',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13.sp,
                                height: 1.4,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 20.h),
                            ElevatedButton.icon(
                              onPressed: () => _showAddSongToBlendSheet(context, currentBlend, tracks),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                              ),
                              icon: const Icon(Icons.add_rounded, color: Colors.black),
                              label: const Text(
                                'Add First Song',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final track = tracks[index];
                          return _buildTrackTile(context, track, tracks, index, playerCtrl, currentUid);
                        },
                        childCount: tracks.length,
                      ),
                    ),
                  ),

                // Spacing at bottom for mini player
                SliverToBoxAdapter(
                  child: SizedBox(height: 80.h),
                ),
              ],
            );
          },
        );
      },
    ),
  ),
);
  }

  Widget _buildMembersAvatarStack(List<BlendMember> members) {
    if (members.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 28.w,
      width: (20.w * (members.length.clamp(1, 4))) + 8.w,
      child: Stack(
        children: List.generate(members.length.clamp(0, 4), (index) {
          final member = members[index];
          return Positioned(
            left: index * 16.w,
            child: Container(
              padding: EdgeInsets.all(1.5.w),
              decoration: const BoxDecoration(
                color: Colors.black,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: member.photoUrl.isNotEmpty
                    ? Image.network(
                        member.photoUrl,
                        width: 25.w,
                        height: 25.w,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildInitialAvatar(member.name),
                      )
                    : _buildInitialAvatar(member.name),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildInitialAvatar(String name) {
    final letter = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return Container(
      width: 25.w,
      height: 25.w,
      color: AppColors.primary,
      alignment: Alignment.center,
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.black,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  Widget _buildTrackTile(
    BuildContext context,
    BlendTrack track,
    List<BlendTrack> allTracks,
    int index,
    PlayerController? playerCtrl,
    String currentUid,
  ) {
    if (playerCtrl == null) {
      return _buildTrackTileContent(context, track, allTracks, false, false, currentUid);
    }

    return Obx(() {
      final currentTrack = playerCtrl.currentTrack.value;
      final isCurrentTrack = currentTrack != null &&
          (currentTrack.trackId == track.id ||
              currentTrack.title.trim().toLowerCase() ==
                  track.title.trim().toLowerCase());
      final isPlaying = isCurrentTrack && playerCtrl.isPlaying.value;

      return _buildTrackTileContent(
          context, track, allTracks, isCurrentTrack, isPlaying, currentUid);
    });
  }

  Widget _buildTrackTileContent(
    BuildContext context,
    BlendTrack track,
    List<BlendTrack> allTracks,
    bool isCurrentTrack,
    bool isPlaying,
    String currentUid,
  ) {
    final playerCtrl = Get.isRegistered<PlayerController>()
        ? Get.find<PlayerController>()
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: () {
          final queue = allTracks.map((t) => t.toTrackModel()).toList();
          playerCtrl?.playTrack(track.toTrackModel(), queue: queue);
        },
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 4.w),
          child: Row(
            children: [
              // 48x48 Artwork with animated wave equalizer overlay when currently playing
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: SizedBox(
                  width: 48.w,
                  height: 48.w,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      track.artwork.isNotEmpty
                          ? Image.network(
                              track.artwork,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: AppColors.surfaceLight,
                                child: const Icon(Icons.music_note_rounded, color: Colors.white54),
                              ),
                            )
                          : Container(
                              color: AppColors.surfaceLight,
                              child: const Icon(Icons.music_note_rounded, color: Colors.white54),
                            ),
                      if (isCurrentTrack)
                        Container(
                          color: Colors.black.withValues(alpha: 0.55),
                          child: Center(
                            child: MusicWaveEqualizer(
                              isPlaying: isPlaying,
                              size: 16.h,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),

              // Title, Artist, Playing Equalizer & Added By Pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.title,
                            style: TextStyle(
                              color: isCurrentTrack ? AppColors.primary : AppColors.textPrimary,
                              fontSize: 14.5.sp,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentTrack) ...[
                          SizedBox(width: 6.w),
                          MusicWaveEqualizer(
                            isPlaying: isPlaying,
                            size: 11.h,
                            color: AppColors.primary,
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 3.h),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            track.artist,
                            style: TextStyle(
                              color: isCurrentTrack
                                  ? AppColors.primary.withValues(alpha: 0.75)
                                  : AppColors.textSecondary,
                              fontSize: 12.sp,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.5.h),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Text(
                            'Added by ${track.addedByName}',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 9.5.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Remove track option if added by current user or creator
              if (track.addedByUid == currentUid || _blend.creatorUid == currentUid)
                IconButton(
                  icon: Icon(
                    Icons.remove_circle_outline_rounded,
                    size: 18.sp,
                    color: Colors.white38,
                  ),
                  tooltip: 'Remove from Blend',
                  onPressed: () async {
                    final blendService = BlendService.to;
                    await blendService.removeTrackFromBlend(_blend.id, track.id);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showBlendOptionsMenu(
    BuildContext context,
    BlendService blendService,
    String currentUid,
    BlendModel currentBlend,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
                SizedBox(height: 16.h),
                ListTile(
                  leading: Text(
                    currentBlend.icon,
                    style: TextStyle(fontSize: 22.sp),
                  ),
                  title: const Text(
                    'Customize Icon & Mood Color',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Change Blend emoji and ambient theme',
                    style: TextStyle(color: Colors.white54, fontSize: 11.5.sp),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showCustomizeThemeSheet(context, blendService, currentBlend);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.share_rounded, color: currentBlend.themeColor),
                  title: const Text(
                    'Share Blend Link',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Code: ${currentBlend.code} • Share to WhatsApp, Instagram & apps',
                    style: TextStyle(color: Colors.white54, fontSize: 11.5.sp),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _shareBlend(currentBlend);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.exit_to_app_rounded, color: Color(0xFFFF5252)),
                  title: const Text(
                    'Leave Blend',
                    style: TextStyle(color: Color(0xFFFF5252), fontWeight: FontWeight.w600),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    final confirmed = await Get.defaultDialog<bool>(
                      title: 'Leave Blend?',
                      middleText: 'Are you sure you want to leave "${currentBlend.name}"?',
                      textConfirm: 'Leave',
                      textCancel: 'Cancel',
                      confirmTextColor: Colors.white,
                      buttonColor: const Color(0xFFFF5252),
                      onConfirm: () => Get.back(result: true),
                    );
                    if (confirmed == true) {
                      await blendService.leaveBlend(currentBlend.id);
                      Get.back();
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCustomizeThemeSheet(
    BuildContext context,
    BlendService blendService,
    BlendModel currentBlend,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          decoration: BoxDecoration(
            color: const Color(0xFF222222),
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Choose Blend Icon & Mood Color',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Changes update the ambient hero glow and icon in real-time.',
                  style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                ),
                SizedBox(height: 16.h),
                Wrap(
                  spacing: 10.w,
                  runSpacing: 10.h,
                  children: kBlendPresets.map((preset) {
                    final color = Color(int.parse('FF${preset.colorHex.replaceAll('#', '')}', radix: 16));
                    final isSelected = currentBlend.icon == preset.icon;

                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(sheetContext);
                        setState(() {
                          _blend = _blend.copyWith(
                            icon: preset.icon,
                            colorHex: preset.colorHex,
                          );
                        });
                        await blendService.updateBlendTheme(
                          currentBlend.id,
                          icon: preset.icon,
                          colorHex: preset.colorHex,
                        );
                      },
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: isSelected ? color.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSelected ? color : Colors.white.withValues(alpha: 0.12),
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.4),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(preset.icon, style: TextStyle(fontSize: 18.sp)),
                            SizedBox(width: 6.w),
                            Text(
                              preset.label,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 12.sp,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 14.h),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showAddSongToBlendSheet(
    BuildContext context, [
    BlendModel? blendOverride,
    List<BlendTrack> currentTracks = const [],
  ]) {
    final targetBlend = blendOverride ?? _blend;
    AddSongToBlendSheet.show(context, targetBlend, currentTracks);
  }
}
