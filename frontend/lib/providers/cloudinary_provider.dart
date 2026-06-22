import 'package:flutter/material.dart';
import '../data/cloudinary_service.dart';

class CloudinaryProvider with ChangeNotifier {
  final CloudinaryService _cloudinaryService = CloudinaryService();

  CloudinaryService get service => _cloudinaryService;
}
