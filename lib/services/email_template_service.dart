import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:share_plus/share_plus.dart';
import '../models/blend_model.dart';
import 'auth_service.dart';

class EmailTemplateService {
  static const String appUrl = 'https://nikhilxrstudio-ctrl.github.io/Whats_play';

  // Brevo SMTP Relay configuration
  static const String _brevoSmtpHost = 'smtp-relay.brevo.com';
  static const int _brevoSmtpPort = 587;
  static const String _brevoUsername = 'c570e4001@smtp-brevo.com';
  static String get _brevoPassword => utf8.decode(
        base64.decode(
          'eHNtdHBzaWItZjA5NjYzODNkMmUyNmE3YWZmNDQxMGExZTZkNjQxZjkxZmRkZTIxNGI0MTNiNzUxMTEzOWM2MmNiMzg2MjRmYi1FNDRjSGFkRjJYUWNhRjE2',
        ),
      );
  static const String _brevoSenderEmail = 'whatsplay.official@gmail.com';
  static const String _brevoSenderName = 'WhatsPlay';

  static SmtpServer get _smtpServer => SmtpServer(
        _brevoSmtpHost,
        port: _brevoSmtpPort,
        username: _brevoUsername,
        password: _brevoPassword,
        allowInsecure: true,
        ignoreBadCertificate: true,
      );

  /// Generates the magic link for joining a Blend
  static String getBlendLink(BlendModel blend) {
    final encodedName = Uri.encodeComponent(blend.name);
    return '$appUrl/blend.html?code=${blend.code}&name=$encodedName';
  }

  // =========================================================================
  // 1. CREATOR CONFIRMATION EMAIL TEMPLATES (Sent when user creates a Blend)
  // =========================================================================

  /// Subject line sent to the creator confirming their new Blend
  static String getBlendCreatedSubject(BlendModel blend) {
    return '🎉 Your WhatsPlay Blend is ready: "${blend.name}" (Code: ${blend.code})';
  }

  /// Plain text template sent to the creator confirming Blend creation
  static String generateBlendCreatedTextTemplate({
    required BlendModel blend,
    required String creatorName,
  }) {
    final link = getBlendLink(blend);

    return '''
======================================================
         🎉 YOUR WHATSPLAY BLEND IS READY!
======================================================

Hi $creatorName! 👋

Your new collaborative music Blend "${blend.name}" has been successfully created and is live on WhatsPlay!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🎧 BLEND NAME       :  "${blend.name}"
  🔑 YOUR SHARE CODE  :  ${blend.code}
  ✨ MOOD THEME       :  ${blend.icon} ${blend.name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📲 HOW TO INVITE YOUR FRIENDS:
1. Share your 6-digit code with friends: ${blend.code}
2. Friends can open WhatsPlay → "Your Library" → "Blends" → "Join Blend" and enter code: ${blend.code}

👉 Or send them your direct magic invite link:
$link

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WHAT IS A BLEND?
Blend is a real-time collaborative listening room on WhatsPlay.
You and your friends can add your favorite tracks, compare music
tastes, and listen together in real-time!

Happy Listening! 🎶
WhatsPlay Music Team
======================================================''';
  }

  /// Modern dark-mode HTML template sent to creator confirming Blend creation
  static String generateBlendCreatedHtmlTemplate({
    required BlendModel blend,
    required String creatorName,
  }) {
    final link = getBlendLink(blend);
    final themeColorHex = blend.colorHex.isNotEmpty ? blend.colorHex : '#1DB954';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Your Blend "${blend.name}" is Ready!</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0F0F0F; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #FFFFFF;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0F0F0F; padding: 40px 10px;">
    <tr>
      <td align="center">
        <!-- Main Card Container -->
        <table role="presentation" width="100%" style="max-width: 560px; background-color: #1A1A1A; border-radius: 20px; border: 1px solid rgba(255, 255, 255, 0.1); overflow: hidden; box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);" cellspacing="0" cellpadding="0">
          
          <!-- Header Banner -->
          <tr>
            <td style="background: linear-gradient(135deg, $themeColorHex, #121212); padding: 36px 30px; text-align: center;">
              <div style="display: inline-block; background-color: rgba(0, 0, 0, 0.4); border-radius: 50%; width: 64px; height: 64px; line-height: 64px; font-size: 32px; margin-bottom: 12px; border: 2px solid rgba(255, 255, 255, 0.2);">
                ${blend.icon}
              </div>
              <div style="font-size: 11px; font-weight: 800; letter-spacing: 2px; text-transform: uppercase; color: rgba(255, 255, 255, 0.85); margin-bottom: 6px;">
                🎉 BLEND CREATED • WHATSPLAY
              </div>
              <h1 style="margin: 0; font-size: 26px; font-weight: 900; color: #FFFFFF; letter-spacing: -0.5px;">
                ${blend.name}
              </h1>
            </td>
          </tr>

          <!-- Content Body -->
          <tr>
            <td style="padding: 32px 30px;">
              <p style="font-size: 16px; line-height: 1.5; color: #E0E0E0; margin-top: 0;">
                Hi <strong style="color: #FFFFFF;">$creatorName</strong>! 👋
              </p>
              <p style="font-size: 15px; line-height: 1.6; color: #B0B0B0; margin: 0 0 24px 0;">
                Your collaborative music Blend <strong style="color: #FFFFFF;">"${blend.name}"</strong> is live and ready! Share your unique code with friends so they can add tracks and listen with you in real-time.
              </p>

              <!-- Join Code Badge Box -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #121212; border: 2px dashed $themeColorHex; border-radius: 14px; margin-bottom: 28px;">
                <tr>
                  <td style="padding: 24px; text-align: center;">
                    <span style="font-size: 12px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; color: #888888; display: block; margin-bottom: 8px;">
                      Your Blend Share Code
                    </span>
                    <span style="font-family: 'Courier New', Courier, monospace; font-size: 40px; font-weight: 900; letter-spacing: 8px; color: $themeColorHex; display: block;">
                      ${blend.code}
                    </span>
                  </td>
                </tr>
              </table>

              <!-- Action Button CTA -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-bottom: 30px;">
                <tr>
                  <td align="center">
                    <a href="$link" style="display: inline-block; background-color: #1DB954; color: #000000; font-size: 15px; font-weight: 800; text-decoration: none; padding: 15px 36px; border-radius: 30px; letter-spacing: 0.3px; box-shadow: 0 4px 14px rgba(29, 185, 84, 0.4);">
                      Open & Manage Blend
                    </a>
                  </td>
                </tr>
              </table>

              <!-- Steps Guide -->
              <div style="background-color: rgba(255, 255, 255, 0.04); border-radius: 12px; padding: 18px 20px; margin-bottom: 24px;">
                <div style="font-size: 12px; font-weight: 800; color: #FFFFFF; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px;">
                  How to invite friends:
                </div>
                <div style="font-size: 13.5px; color: #CCCCCC; line-height: 1.6;">
                  1. Share your code <strong style="color: $themeColorHex; font-family: monospace;">${blend.code}</strong> with your friends.<br>
                  2. They open <strong>WhatsPlay</strong> &rarr; <strong>Blends</strong> &rarr; <strong>Join Blend</strong>.<br>
                  3. They enter code <strong style="color: $themeColorHex; font-family: monospace;">${blend.code}</strong> to join instantly!
                </div>
              </div>

              <!-- Explanation -->
              <p style="font-size: 13px; color: #888888; line-height: 1.5; margin: 0; text-align: center;">
                🎵 WhatsPlay Blend lets you and your friends blend music together in real-time, share favorite tracks, and enjoy synchronized playback.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 20px 30px; background-color: #141414; border-top: 1px solid rgba(255, 255, 255, 0.06); text-align: center;">
              <p style="font-size: 12px; color: #666666; margin: 0;">
                WhatsPlay Music • Developed by Nikhil • Built for Music Lovers
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>''';
  }

  // =========================================================================
  // 2. FRIEND INVITATION EMAIL TEMPLATES (Sent when inviting someone else)
  // =========================================================================

  /// Subject line sent to a friend invited to join a Blend
  static String getBlendInviteSubject(BlendModel blend, {required String creatorName}) {
    return '🎵 $creatorName invited you to join "${blend.name}" on WhatsPlay! (Code: ${blend.code})';
  }

  /// Plain text template sent to an invited friend
  static String generateBlendInviteTextTemplate({
    required BlendModel blend,
    required String creatorName,
  }) {
    final link = getBlendLink(blend);

    return '''
======================================================
            🎵 YOU'RE INVITED TO A BLEND!
======================================================

Hey there! 👋

$creatorName has invited you to join their exclusive music Blend "${blend.name}" on WhatsPlay!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  🎧 BLEND NAME       :  "${blend.name}"
  🔑 YOUR JOIN CODE   :  ${blend.code}
  ✨ CREATED BY       :  $creatorName
  ✨ MOOD THEME       :  ${blend.icon} ${blend.name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎵 HOW TO JOIN:
1. Open the WhatsPlay Music app on your phone.
2. Tap "Your Library" → "Blends" → "Join Blend".
3. Enter your 6-digit code: ${blend.code}

👉 Or tap your direct magic invite link:
$link

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
WHAT IS A BLEND?
Blend is a real-time collaborative listening room on WhatsPlay.
You and your friends can add your favorite tracks, compare music
tastes, and listen together in real-time!

Happy Listening! 🎶
WhatsPlay Music Team
======================================================''';
  }

  /// Modern dark-mode HTML template sent to an invited friend
  static String generateBlendInviteHtmlTemplate({
    required BlendModel blend,
    required String creatorName,
  }) {
    final link = getBlendLink(blend);
    final themeColorHex = blend.colorHex.isNotEmpty ? blend.colorHex : '#1DB954';

    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Join "${blend.name}" on WhatsPlay</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0F0F0F; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #FFFFFF;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0F0F0F; padding: 40px 10px;">
    <tr>
      <td align="center">
        <!-- Main Card Container -->
        <table role="presentation" width="100%" style="max-width: 560px; background-color: #1A1A1A; border-radius: 20px; border: 1px solid rgba(255, 255, 255, 0.1); overflow: hidden; box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);" cellspacing="0" cellpadding="0">
          
          <!-- Header Banner -->
          <tr>
            <td style="background: linear-gradient(135deg, $themeColorHex, #121212); padding: 36px 30px; text-align: center;">
              <div style="display: inline-block; background-color: rgba(0, 0, 0, 0.4); border-radius: 50%; width: 64px; height: 64px; line-height: 64px; font-size: 32px; margin-bottom: 12px; border: 2px solid rgba(255, 255, 255, 0.2);">
                ${blend.icon}
              </div>
              <div style="font-size: 11px; font-weight: 800; letter-spacing: 2px; text-transform: uppercase; color: rgba(255, 255, 255, 0.85); margin-bottom: 6px;">
                💌 INVITATION • WHATSPLAY BLEND
              </div>
              <h1 style="margin: 0; font-size: 26px; font-weight: 900; color: #FFFFFF; letter-spacing: -0.5px;">
                ${blend.name}
              </h1>
            </td>
          </tr>

          <!-- Content Body -->
          <tr>
            <td style="padding: 32px 30px;">
              <p style="font-size: 16px; line-height: 1.5; color: #E0E0E0; margin-top: 0;">
                Hey there! 👋
              </p>
              <p style="font-size: 15px; line-height: 1.6; color: #B0B0B0; margin: 0 0 24px 0;">
                <strong style="color: #FFFFFF;">$creatorName</strong> created a new collaborative music Blend on <strong>WhatsPlay</strong> and wants you to join the session!
              </p>

              <!-- Join Code Badge Box -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #121212; border: 2px dashed $themeColorHex; border-radius: 14px; margin-bottom: 28px;">
                <tr>
                  <td style="padding: 24px; text-align: center;">
                    <span style="font-size: 12px; font-weight: 700; letter-spacing: 1.5px; text-transform: uppercase; color: #888888; display: block; margin-bottom: 8px;">
                      Your Unique Join Code
                    </span>
                    <span style="font-family: 'Courier New', Courier, monospace; font-size: 40px; font-weight: 900; letter-spacing: 8px; color: $themeColorHex; display: block;">
                      ${blend.code}
                    </span>
                  </td>
                </tr>
              </table>

              <!-- Action Button CTA -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-bottom: 30px;">
                <tr>
                  <td align="center">
                    <a href="$link" style="display: inline-block; background-color: #1DB954; color: #000000; font-size: 15px; font-weight: 800; text-decoration: none; padding: 15px 36px; border-radius: 30px; letter-spacing: 0.3px; box-shadow: 0 4px 14px rgba(29, 185, 84, 0.4);">
                      Open & Join Blend Now
                    </a>
                  </td>
                </tr>
              </table>

              <!-- Steps Guide -->
              <div style="background-color: rgba(255, 255, 255, 0.04); border-radius: 12px; padding: 18px 20px; margin-bottom: 24px;">
                <div style="font-size: 12px; font-weight: 800; color: #FFFFFF; text-transform: uppercase; letter-spacing: 1px; margin-bottom: 10px;">
                  How to join with code:
                </div>
                <div style="font-size: 13.5px; color: #CCCCCC; line-height: 1.6;">
                  1. Open the <strong>WhatsPlay</strong> app.<br>
                  2. Tap <strong>Your Library</strong> &rarr; <strong>Blends</strong> &rarr; <strong>Join Blend</strong>.<br>
                  3. Enter code <strong style="color: $themeColorHex; font-family: monospace;">${blend.code}</strong>.
                </div>
              </div>

              <!-- Explanation -->
              <p style="font-size: 13px; color: #888888; line-height: 1.5; margin: 0; text-align: center;">
                🎵 WhatsPlay Blend lets you and your friends blend music together in real-time, share favorite tracks, and enjoy synchronized playback.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 20px 30px; background-color: #141414; border-top: 1px solid rgba(255, 255, 255, 0.06); text-align: center;">
              <p style="font-size: 12px; color: #666666; margin: 0;">
                WhatsPlay Music • Developed by Nikhil • Built for Music Lovers
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>''';
  }

  // =========================================================================
  // 3. EMAIL DELIVERY SERVICES VIA BREVO & FIRESTORE
  // =========================================================================

  /// Sends the Blend Created confirmation email directly to the Blend creator
  static Future<bool> sendBlendCreatedEmail(
    BlendModel blend, {
    String? recipientEmail,
  }) async {
    final auth = AuthService.to;
    final targetEmail = recipientEmail ?? auth.userEmail.value;

    if (targetEmail.isEmpty) {
      debugPrint('[EmailTemplateService] No recipient email specified, skipping automated email.');
      return false;
    }

    try {
      final subject = getBlendCreatedSubject(blend);
      final textTemplate = generateBlendCreatedTextTemplate(
        blend: blend,
        creatorName: auth.effectiveUserName,
      );
      final htmlTemplate = generateBlendCreatedHtmlTemplate(
        blend: blend,
        creatorName: auth.effectiveUserName,
      );

      final message = Message()
        ..from = const Address(_brevoSenderEmail, _brevoSenderName)
        ..recipients.add(targetEmail)
        ..subject = subject
        ..text = textTemplate
        ..html = htmlTemplate;

      final sendReport = await send(message, _smtpServer);
      debugPrint('[EmailTemplateService] Creator email delivered via Brevo to $targetEmail: $sendReport');

      // Audit log to Firestore
      try {
        await FirebaseFirestore.instance.collection('mail').add({
          'to': [targetEmail],
          'message': {
            'subject': subject,
            'text': textTemplate,
            'html': htmlTemplate,
          },
          'blendId': blend.id,
          'blendCode': blend.code,
          'type': 'CREATOR_CONFIRMATION',
          'provider': 'Brevo',
          'status': 'DELIVERED',
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 4));
      } catch (logErr) {
        debugPrint('[EmailTemplateService] Non-fatal Firestore log notice: $logErr');
      }

      return true;
    } catch (e) {
      debugPrint('[EmailTemplateService] Error delivering creator email via Brevo: $e');
      return false;
    }
  }

  /// Sends a Blend Invitation email directly to an invited friend
  static Future<bool> sendBlendInviteEmail(
    BlendModel blend, {
    required String recipientEmail,
  }) async {
    final auth = AuthService.to;
    final targetEmail = recipientEmail.trim();

    if (targetEmail.isEmpty || !targetEmail.contains('@')) {
      debugPrint('[EmailTemplateService] Invalid recipient email: $targetEmail');
      return false;
    }

    try {
      final subject = getBlendInviteSubject(blend, creatorName: auth.effectiveUserName);
      final textTemplate = generateBlendInviteTextTemplate(
        blend: blend,
        creatorName: auth.effectiveUserName,
      );
      final htmlTemplate = generateBlendInviteHtmlTemplate(
        blend: blend,
        creatorName: auth.effectiveUserName,
      );

      final message = Message()
        ..from = const Address(_brevoSenderEmail, _brevoSenderName)
        ..recipients.add(targetEmail)
        ..subject = subject
        ..text = textTemplate
        ..html = htmlTemplate;

      final sendReport = await send(message, _smtpServer);
      debugPrint('[EmailTemplateService] Invite email delivered via Brevo to $targetEmail: $sendReport');

      // Audit log to Firestore
      try {
        await FirebaseFirestore.instance.collection('mail').add({
          'to': [targetEmail],
          'message': {
            'subject': subject,
            'text': textTemplate,
            'html': htmlTemplate,
          },
          'blendId': blend.id,
          'blendCode': blend.code,
          'type': 'FRIEND_INVITATION',
          'senderName': auth.effectiveUserName,
          'provider': 'Brevo',
          'status': 'DELIVERED',
          'createdAt': FieldValue.serverTimestamp(),
        }).timeout(const Duration(seconds: 4));
      } catch (logErr) {
        debugPrint('[EmailTemplateService] Non-fatal Firestore log notice: $logErr');
      }

      return true;
    } catch (e) {
      debugPrint('[EmailTemplateService] Error delivering invite email via Brevo: $e');
      return false;
    }
  }

  /// Launches the native share sheet with the invitation template and subject
  static Future<void> shareViaEmail(BlendModel blend) async {
    HapticFeedback.mediumImpact();
    final auth = AuthService.to;
    final subject = getBlendInviteSubject(blend, creatorName: auth.effectiveUserName);
    final body = generateBlendInviteTextTemplate(
      blend: blend,
      creatorName: auth.effectiveUserName,
    );

    // Also copy code to clipboard as quick convenience
    Clipboard.setData(ClipboardData(text: blend.code));

    await SharePlus.instance.share(
      ShareParams(
        text: body,
        subject: subject,
      ),
    );
  }
}
