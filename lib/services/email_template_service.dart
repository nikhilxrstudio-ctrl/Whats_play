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
  // 1. WELCOME EMAIL (Sent when user registers / logs in with Google first time)
  // =========================================================================

  static String getWelcomeSubject(String userName) {
    return '🎉 Welcome to WhatsPlay, $userName! Your musical journey begins';
  }

  static String generateWelcomeTextTemplate({required String userName}) {
    return '''
======================================================
             🎵 WELCOME TO WHATSPLAY!
======================================================

Hi $userName! 👋

Welcome to the WhatsPlay family! We're thrilled to have you here.

WhatsPlay brings you high-fidelity audio streaming, rich regional
Indian music discovery, real-time shared Blends with friends, and
unlimited offline downloads — completely free!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🌟 WHAT YOU CAN DO ON WHATSPLAY:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🎧 1. EXPLORE MILLIONS OF SONGS
Stream Bollywood, Punjabi, Gujarati, Romantic, Lo-Fi, and Trending
chartbusters with dual-engine studio sound quality.

👥 2. REAL-TIME SHARED BLENDS
Create collaborative listening rooms with your friends! Get a unique
6-digit code, share it, and add tracks together in real-time.

💾 3. OFFLINE DOWNLOADS
Save songs directly to your device and listen anytime, anywhere,
even when you're completely offline.

🎤 4. SYNCHRONIZED LYRICS
Sing along to your favorite hits with interactive real-time lyrics
embedded directly inside the full-screen player.

👉 Open WhatsPlay and start listening:
$appUrl

Happy Listening! 🎶
WhatsPlay Music Team • Developed by Nikhil
======================================================''';
  }

  static String generateWelcomeHtmlTemplate({
    required String userName,
    required String userEmail,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome to WhatsPlay</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0A0A0A; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #FFFFFF;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0A0A0A; padding: 40px 10px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width: 580px; background-color: #161616; border-radius: 24px; border: 1px solid rgba(255, 255, 255, 0.1); overflow: hidden; box-shadow: 0 16px 40px rgba(0, 0, 0, 0.6);" cellspacing="0" cellpadding="0">
          
          <!-- Header Banner -->
          <tr>
            <td style="background: linear-gradient(135deg, #1DB954 0%, #0d5f2a 60%, #121212 100%); padding: 44px 32px; text-align: center;">
              <div style="display: inline-block; background-color: rgba(0, 0, 0, 0.45); border-radius: 50%; width: 72px; height: 72px; line-height: 72px; font-size: 36px; margin-bottom: 14px; border: 2px solid rgba(255, 255, 255, 0.25);">
                🎵
              </div>
              <div style="font-size: 11.5px; font-weight: 800; letter-spacing: 2px; text-transform: uppercase; color: rgba(255, 255, 255, 0.9); margin-bottom: 6px;">
                WELCOME TO THE FAMILY
              </div>
              <h1 style="margin: 0; font-size: 28px; font-weight: 900; color: #FFFFFF; letter-spacing: -0.5px;">
                WhatsPlay Music
              </h1>
            </td>
          </tr>

          <!-- Body Content -->
          <tr>
            <td style="padding: 34px 32px;">
              <p style="font-size: 18px; font-weight: 700; color: #FFFFFF; margin-top: 0; margin-bottom: 8px;">
                Hi $userName! 👋
              </p>
              <p style="font-size: 15px; line-height: 1.6; color: #B3B3B3; margin: 0 0 28px 0;">
                We're excited to welcome you to <strong>WhatsPlay</strong>! Your Google Account (<span style="color: #1DB954;">$userEmail</span>) is now connected, giving you full access to real-time music collaboration, offline downloads, and personalized playlists.
              </p>

              <!-- Feature Highlights Grid -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-bottom: 28px;">
                <tr>
                  <td style="padding: 14px 16px; background-color: rgba(255, 255, 255, 0.04); border-radius: 14px; margin-bottom: 10px; border: 1px solid rgba(255, 255, 255, 0.06);">
                    <div style="font-size: 14.5px; font-weight: 700; color: #FFFFFF; margin-bottom: 4px;">
                      👥 Real-Time Shared Blends
                    </div>
                    <div style="font-size: 13px; color: #8E8E8E; line-height: 1.5;">
                      Create collaborative listening rooms with unique 6-digit join codes. Invite friends and blend music together live!
                    </div>
                  </td>
                </tr>
                <tr><td style="height: 10px;"></td></tr>
                <tr>
                  <td style="padding: 14px 16px; background-color: rgba(255, 255, 255, 0.04); border-radius: 14px; margin-bottom: 10px; border: 1px solid rgba(255, 255, 255, 0.06);">
                    <div style="font-size: 14.5px; font-weight: 700; color: #FFFFFF; margin-bottom: 4px;">
                      🎧 Regional Indian Music Catalogue
                    </div>
                    <div style="font-size: 13px; color: #8E8E8E; line-height: 1.5;">
                      Discover the best of Bollywood, Punjabi, Gujarati, Romantic, and Party hits with dual-engine studio playback.
                    </div>
                  </td>
                </tr>
                <tr><td style="height: 10px;"></td></tr>
                <tr>
                  <td style="padding: 14px 16px; background-color: rgba(255, 255, 255, 0.04); border-radius: 14px; border: 1px solid rgba(255, 255, 255, 0.06);">
                    <div style="font-size: 14.5px; font-weight: 700; color: #FFFFFF; margin-bottom: 4px;">
                      💾 Offline Storage & Synchronized Lyrics
                    </div>
                    <div style="font-size: 13px; color: #8E8E8E; line-height: 1.5;">
                      Download your favorites for zero-data offline playback, and sing along with real-time synchronized lyrics.
                    </div>
                  </td>
                </tr>
              </table>

              <!-- Action Button CTA -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-bottom: 26px;">
                <tr>
                  <td align="center">
                    <a href="$appUrl" style="display: inline-block; background-color: #1DB954; color: #000000; font-size: 15px; font-weight: 800; text-decoration: none; padding: 15px 40px; border-radius: 30px; letter-spacing: 0.3px; box-shadow: 0 4px 18px rgba(29, 185, 84, 0.4);">
                      Start Listening on WhatsPlay
                    </a>
                  </td>
                </tr>
              </table>

              <p style="font-size: 12.5px; color: #666666; line-height: 1.5; margin: 0; text-align: center;">
                Need help or have suggestions? Feel free to reach out anytime. Happy listening! 🎧
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 22px 32px; background-color: #111111; border-top: 1px solid rgba(255, 255, 255, 0.06); text-align: center;">
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
  // 2. WELCOME BACK EMAIL (Sent when existing user logs in again with Google)
  // =========================================================================

  static String getWelcomeBackSubject(String userName) {
    return '🎵 Welcome back to WhatsPlay, $userName! Good to see you again';
  }

  static String generateWelcomeBackTextTemplate({required String userName}) {
    return '''
======================================================
            🎵 WELCOME BACK TO WHATSPLAY!
======================================================

Hi $userName! 👋

It's great to see you again on WhatsPlay!

Your account has been successfully verified. Your liked tracks,
playlists, and shared Blends are synchronized and ready to enjoy.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚡ WHAT'S NEW ON WHATSPLAY:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
• 👥 Automated Dark-Themed Email Invites for Shared Blends
• 🎵 Smart Genre-Based Song Suggestions in Add Song Sheet
• 🎨 High-Contrast Play All Controls & Polished Blend States
• 🏷️ Official v1.0.0 Release with Enhanced Audio Reliability

👉 Jump right back into your music:
$appUrl

Happy Listening! 🎶
WhatsPlay Music Team • Developed by Nikhil
======================================================''';
  }

  static String generateWelcomeBackHtmlTemplate({
    required String userName,
    required String userEmail,
  }) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Welcome Back to WhatsPlay</title>
</head>
<body style="margin: 0; padding: 0; background-color: #0A0A0A; font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #FFFFFF;">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="background-color: #0A0A0A; padding: 40px 10px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" style="max-width: 580px; background-color: #161616; border-radius: 24px; border: 1px solid rgba(255, 255, 255, 0.1); overflow: hidden; box-shadow: 0 16px 40px rgba(0, 0, 0, 0.6);" cellspacing="0" cellpadding="0">
          
          <!-- Header Banner -->
          <tr>
            <td style="background: linear-gradient(135deg, #9C27B0 0%, #4A148C 60%, #121212 100%); padding: 44px 32px; text-align: center;">
              <div style="display: inline-block; background-color: rgba(0, 0, 0, 0.45); border-radius: 50%; width: 72px; height: 72px; line-height: 72px; font-size: 36px; margin-bottom: 14px; border: 2px solid rgba(255, 255, 255, 0.25);">
                ✨
              </div>
              <div style="font-size: 11.5px; font-weight: 800; letter-spacing: 2px; text-transform: uppercase; color: rgba(255, 255, 255, 0.9); margin-bottom: 6px;">
                WELCOME BACK
              </div>
              <h1 style="margin: 0; font-size: 28px; font-weight: 900; color: #FFFFFF; letter-spacing: -0.5px;">
                Good to See You, $userName!
              </h1>
            </td>
          </tr>

          <!-- Body Content -->
          <tr>
            <td style="padding: 34px 32px;">
              <p style="font-size: 16px; line-height: 1.6; color: #B3B3B3; margin-top: 0; margin-bottom: 24px;">
                You've successfully signed back in to your <strong>WhatsPlay</strong> account (<span style="color: #CE93D8;">$userEmail</span>). All your liked tracks, listening history, and shared Blends are synced and ready for you.
              </p>

              <!-- New Updates Card -->
              <div style="background-color: rgba(255, 255, 255, 0.04); border-radius: 14px; padding: 20px 22px; margin-bottom: 28px; border: 1px solid rgba(255, 255, 255, 0.07);">
                <div style="font-size: 12.5px; font-weight: 800; text-transform: uppercase; color: #E1BEE7; letter-spacing: 1.5px; margin-bottom: 12px;">
                  ⚡ WHAT'S NEW IN LATEST VERSION:
                </div>
                <div style="font-size: 13.5px; color: #CCCCCC; line-height: 1.7;">
                  • 💌 <strong>Automated Email Templates</strong> for Blends via Brevo SMTP<br>
                  • 🎯 <strong>Smart Song Recommendations</strong> in the Add Song sheet<br>
                  • 🌟 <strong>Polished Dynamic Play Controls</strong> with high contrast<br>
                  • 🏷️ <strong>Official Version Tagging & Update System</strong>
                </div>
              </div>

              <!-- Action Button CTA -->
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-bottom: 26px;">
                <tr>
                  <td align="center">
                    <a href="$appUrl" style="display: inline-block; background-color: #1DB954; color: #000000; font-size: 15px; font-weight: 800; text-decoration: none; padding: 15px 40px; border-radius: 30px; letter-spacing: 0.3px; box-shadow: 0 4px 18px rgba(29, 185, 84, 0.4);">
                      Resume Listening Now
                    </a>
                  </td>
                </tr>
              </table>

              <p style="font-size: 12.5px; color: #666666; line-height: 1.5; margin: 0; text-align: center;">
                Need to invite friends to a Blend? Open the app and share your 6-digit code anytime! 🎶
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 22px 32px; background-color: #111111; border-top: 1px solid rgba(255, 255, 255, 0.06); text-align: center;">
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
  // 3. CREATOR CONFIRMATION EMAIL TEMPLATES (Sent when user creates a Blend)
  // =========================================================================

  static String getBlendCreatedSubject(BlendModel blend) {
    return '🎉 Your WhatsPlay Blend is ready: "${blend.name}" (Code: ${blend.code})';
  }

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
        <table role="presentation" width="100%" style="max-width: 560px; background-color: #1A1A1A; border-radius: 20px; border: 1px solid rgba(255, 255, 255, 0.1); overflow: hidden; box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);" cellspacing="0" cellpadding="0">
          
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

          <tr>
            <td style="padding: 32px 30px;">
              <p style="font-size: 16px; line-height: 1.5; color: #E0E0E0; margin-top: 0;">
                Hi <strong style="color: #FFFFFF;">$creatorName</strong>! 👋
              </p>
              <p style="font-size: 15px; line-height: 1.6; color: #B0B0B0; margin: 0 0 24px 0;">
                Your collaborative music Blend <strong style="color: #FFFFFF;">"${blend.name}"</strong> is live and ready! Share your unique code with friends so they can add tracks and listen with you in real-time.
              </p>

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

              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-bottom: 30px;">
                <tr>
                  <td align="center">
                    <a href="$link" style="display: inline-block; background-color: #1DB954; color: #000000; font-size: 15px; font-weight: 800; text-decoration: none; padding: 15px 36px; border-radius: 30px; letter-spacing: 0.3px; box-shadow: 0 4px 14px rgba(29, 185, 84, 0.4);">
                      Open & Manage Blend
                    </a>
                  </td>
                </tr>
              </table>

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

              <p style="font-size: 13px; color: #888888; line-height: 1.5; margin: 0; text-align: center;">
                🎵 WhatsPlay Blend lets you and your friends blend music together in real-time, share favorite tracks, and enjoy synchronized playback.
              </p>
            </td>
          </tr>

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
  // 4. FRIEND INVITATION EMAIL TEMPLATES (Sent when inviting someone else)
  // =========================================================================

  static String getBlendInviteSubject(BlendModel blend, {required String creatorName}) {
    return '🎵 $creatorName invited you to join "${blend.name}" on WhatsPlay! (Code: ${blend.code})';
  }

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
        <table role="presentation" width="100%" style="max-width: 560px; background-color: #1A1A1A; border-radius: 20px; border: 1px solid rgba(255, 255, 255, 0.1); overflow: hidden; box-shadow: 0 10px 30px rgba(0, 0, 0, 0.5);" cellspacing="0" cellpadding="0">
          
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

          <tr>
            <td style="padding: 32px 30px;">
              <p style="font-size: 16px; line-height: 1.5; color: #E0E0E0; margin-top: 0;">
                Hey there! 👋
              </p>
              <p style="font-size: 15px; line-height: 1.6; color: #B0B0B0; margin: 0 0 24px 0;">
                <strong style="color: #FFFFFF;">$creatorName</strong> created a new collaborative music Blend on <strong>WhatsPlay</strong> and wants you to join the session!
              </p>

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

              <table role="presentation" width="100%" cellspacing="0" cellpadding="0" style="margin-bottom: 30px;">
                <tr>
                  <td align="center">
                    <a href="$link" style="display: inline-block; background-color: #1DB954; color: #000000; font-size: 15px; font-weight: 800; text-decoration: none; padding: 15px 36px; border-radius: 30px; letter-spacing: 0.3px; box-shadow: 0 4px 14px rgba(29, 185, 84, 0.4);">
                      Open & Join Blend Now
                    </a>
                  </td>
                </tr>
              </table>

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

              <p style="font-size: 13px; color: #888888; line-height: 1.5; margin: 0; text-align: center;">
                🎵 WhatsPlay Blend lets you and your friends blend music together in real-time, share favorite tracks, and enjoy synchronized playback.
              </p>
            </td>
          </tr>

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
  // 5. CENTRALIZED FIRESTORE AUDIT LOGGING ('email_logs' collection)
  // =========================================================================

  /// Centralized logging for all outgoing emails into Cloud Firestore 'email_logs'
  static Future<void> _logToFirestore({
    required String userEmail,
    required String userName,
    required String category,
    required String subject,
    required String htmlContent,
    required String textContent,
    String? userId,
    String? source,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final docData = <String, dynamic>{
        'userEmail': userEmail,
        'userName': userName,
        'category': category, // 'WELCOME' | 'WELCOME_BACK' | 'BLEND_CREATED' | 'BLEND_INVITE'
        'subject': subject,
        'provider': 'Brevo',
        'status': 'DELIVERED',
        'source': source ?? 'app',
        'sentAt': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (userId != null && userId.isNotEmpty) {
        docData['userId'] = userId;
      }
      if (extra != null) {
        docData.addAll(extra);
      }

      // Add to dedicated 'email_logs' collection
      await FirebaseFirestore.instance
          .collection('email_logs')
          .add(docData)
          .timeout(const Duration(seconds: 4));

      // Also log legacy/audit mail record in 'mail'
      await FirebaseFirestore.instance
          .collection('mail')
          .add({
            'to': [userEmail],
            'message': {
              'subject': subject,
              'text': textContent,
              'html': htmlContent,
            },
            'category': category,
            'provider': 'Brevo',
            'status': 'DELIVERED',
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[EmailTemplateService] Non-fatal Firestore log notice: $e');
    }
  }

  // =========================================================================
  // 6. EMAIL DELIVERY SERVICES VIA BREVO
  // =========================================================================

  /// Sends a Welcome Email to a new user after Google Login
  static Future<bool> sendWelcomeEmail({
    required String userId,
    required String userEmail,
    required String userName,
    String source = 'onboarding',
  }) async {
    if (userEmail.isEmpty || !userEmail.contains('@')) {
      debugPrint('[EmailTemplateService] Invalid welcome email recipient: $userEmail');
      return false;
    }

    try {
      final subject = getWelcomeSubject(userName);
      final textTemplate = generateWelcomeTextTemplate(userName: userName);
      final htmlTemplate = generateWelcomeHtmlTemplate(
        userName: userName,
        userEmail: userEmail,
      );

      final message = Message()
        ..from = const Address(_brevoSenderEmail, _brevoSenderName)
        ..recipients.add(userEmail)
        ..subject = subject
        ..text = textTemplate
        ..html = htmlTemplate;

      final sendReport = await send(message, _smtpServer);
      debugPrint('[EmailTemplateService] Welcome email delivered via Brevo to $userEmail: $sendReport');

      await _logToFirestore(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        category: 'WELCOME',
        subject: subject,
        htmlContent: htmlTemplate,
        textContent: textTemplate,
        source: source,
      );

      return true;
    } catch (e) {
      debugPrint('[EmailTemplateService] Error delivering welcome email via Brevo: $e');
      return false;
    }
  }

  /// Sends a Welcome Back Email to a returning user after Google Login
  static Future<bool> sendWelcomeBackEmail({
    required String userId,
    required String userEmail,
    required String userName,
    String source = 'onboarding',
  }) async {
    if (userEmail.isEmpty || !userEmail.contains('@')) {
      debugPrint('[EmailTemplateService] Invalid welcome back email recipient: $userEmail');
      return false;
    }

    try {
      final subject = getWelcomeBackSubject(userName);
      final textTemplate = generateWelcomeBackTextTemplate(userName: userName);
      final htmlTemplate = generateWelcomeBackHtmlTemplate(
        userName: userName,
        userEmail: userEmail,
      );

      final message = Message()
        ..from = const Address(_brevoSenderEmail, _brevoSenderName)
        ..recipients.add(userEmail)
        ..subject = subject
        ..text = textTemplate
        ..html = htmlTemplate;

      final sendReport = await send(message, _smtpServer);
      debugPrint('[EmailTemplateService] Welcome back email delivered via Brevo to $userEmail: $sendReport');

      await _logToFirestore(
        userId: userId,
        userEmail: userEmail,
        userName: userName,
        category: 'WELCOME_BACK',
        subject: subject,
        htmlContent: htmlTemplate,
        textContent: textTemplate,
        source: source,
      );

      return true;
    } catch (e) {
      debugPrint('[EmailTemplateService] Error delivering welcome back email via Brevo: $e');
      return false;
    }
  }

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

      await _logToFirestore(
        userId: auth.isLoggedIn.value ? auth.userEmail.value : null,
        userEmail: targetEmail,
        userName: auth.effectiveUserName,
        category: 'BLEND_CREATED',
        subject: subject,
        htmlContent: htmlTemplate,
        textContent: textTemplate,
        extra: {
          'blendId': blend.id,
          'blendCode': blend.code,
        },
      );

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

      await _logToFirestore(
        userId: auth.isLoggedIn.value ? auth.userEmail.value : null,
        userEmail: targetEmail,
        userName: auth.effectiveUserName,
        category: 'BLEND_INVITE',
        subject: subject,
        htmlContent: htmlTemplate,
        textContent: textTemplate,
        extra: {
          'blendId': blend.id,
          'blendCode': blend.code,
        },
      );

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
