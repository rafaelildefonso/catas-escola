import 'dart:typed_data';

import 'package:catas/data/cloudinary_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:skeletonizer/skeletonizer.dart';

enum LogoId {
  google('google.svg'),
  googleGmail('google-gmail-icon.svg'),
  googleCalendar('google-calendar-icon.svg'),
  googleMeet('google-meet-icon.svg'),
  googleDrive('google-drive-icon.svg'),
  googleDocs('google-docs-icon.svg'),
  googleSheets('google-sheets-icon.svg'),
  notion('notion-icon.svg'),
  whatsapp('whatsapp-icon.svg'),
  slack('slack-icon.svg'),
  apple('apple-icon');

  final String filename;
  const LogoId(this.filename);

  String get assetPath => 'assets/icons/$filename';
}

class Logo extends StatelessWidget {
  final LogoId logoId;
  final Icon onErrorIcon;
  final double size;

  const Logo({
    super.key,
    required this.logoId,
    required this.onErrorIcon,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    return Skeleton.replace(
      width: size,
      height: size,
      replacement: Bone.circle(size: size),
      child: _buildAssetImage(),
    );
  }

  Widget _buildAssetImage() {
    final bool isSvg = logoId.filename.toLowerCase().contains('.svg');
    final String cloudUrl = CloudinaryService.getImageUrl(logoId.filename);
    final bool hasCloudinary = cloudUrl.isNotEmpty;

    if (!hasCloudinary) {
      return isSvg ? _buildLocalSvg() : _buildLocalRaster();
    }

    if (isSvg) {
      return _buildCloudinarySvg(cloudUrl);
    }

    return _buildCloudinaryRaster(cloudUrl);
  }

  Widget _buildLocalSvg() {
    return SvgPicture.asset(
      logoId.assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => _buildLoading(),
    );
  }

  Widget _buildLocalRaster() {
    return Image.asset(
      logoId.assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _buildError(),
    );
  }

  Widget _buildCloudinarySvg(String url) {
    return _CloudinarySvgImage(
      url: url,
      size: size,
      fallback: _buildLocalSvg,
    );
  }

  Widget _buildCloudinaryRaster(String url) {
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (_, _) => _buildLoading(),
      errorWidget: (_, _, _) => _buildLocalRaster(),
    );
  }

  Widget _buildError() {
    return SizedBox(width: size, height: size, child: onErrorIcon);
  }

  Widget _buildLoading() {
    return Bone.circle(size: size);
  }
}

class _CloudinarySvgImage extends StatefulWidget {
  final String url;
  final double size;
  final Widget Function() fallback;

  const _CloudinarySvgImage({
    required this.url,
    required this.size,
    required this.fallback,
  });

  @override
  State<_CloudinarySvgImage> createState() => _CloudinarySvgImageState();
}

class _CloudinarySvgImageState extends State<_CloudinarySvgImage> {
  late Future<Uint8List> _future;
  bool _timedOut = false;

  @override
  void initState() {
    super.initState();
    _future = DefaultCacheManager()
        .getSingleFile(widget.url)
        .then((fi) => fi.readAsBytes());

    // Timeout de 5s — se não carregar, cai pro fallback
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && !_timedOut) {
        setState(() => _timedOut = true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && !_timedOut) {
          return Bone.circle(size: widget.size);
        }

        if (snapshot.hasData && !_timedOut) {
          try {
            return SvgPicture.memory(
              snapshot.data!,
              width: widget.size,
              height: widget.size,
              fit: BoxFit.contain,
            );
          } catch (_) {}
        }

        return widget.fallback();
      },
    );
  }
}
