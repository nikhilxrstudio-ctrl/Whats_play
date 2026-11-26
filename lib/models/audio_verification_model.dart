class AudioVerificationModel {
  final String url;
  final int statusCode;
  final String contentType;
  final bool isAccessible;
  final bool isFullTrack;
  final DateTime verificationTime;
  final String details;

  const AudioVerificationModel({
    required this.url,
    required this.statusCode,
    required this.contentType,
    required this.isAccessible,
    required this.isFullTrack,
    required this.verificationTime,
    required this.details,
  });

  factory AudioVerificationModel.failed({
    required String url,
    required String error,
  }) {
    return AudioVerificationModel(
      url: url,
      statusCode: 0,
      contentType: 'unknown',
      isAccessible: false,
      isFullTrack: false,
      verificationTime: DateTime.now(),
      details: 'Verification failed: $error',
    );
  }
}
