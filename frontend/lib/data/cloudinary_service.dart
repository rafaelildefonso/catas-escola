import '../core/app_config.dart';

class CloudinaryService {
  static final String _cloudName = AppConfig.cloudinaryCloudName;

  CloudinaryService();

  /// Returns the URL string for an image manually
  static String getImageUrl(String publicId) {
    if (_cloudName.isEmpty) return '';

    // Simplified URL generation without automatic prefixing.
    // Let the caller specify the full path (e.g., 'logos/logo.png').
    // https://res.cloudinary.com/<cloud_name>/image/upload/<public_id>
    return 'https://res.cloudinary.com/$_cloudName/image/upload/$publicId';
  }
}
