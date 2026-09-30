import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';

class StrataImage extends StatelessWidget {
  StrataImage.file(
    String filePath, {
    Key? key,
    double? scale,
    double? width,
    double? height,
    Color? color,
    BlendMode? colorBlendMode,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
  }) : this._(
         key: key,
         imageFile: File(filePath),
         scale: scale,
         width: width,
         height: height,
         color: color,
         colorBlendMode: colorBlendMode,
         fit: fit,
         alignment: alignment,
       );

  const StrataImage._({
    super.key,
    this.imageUrl,
    this.imagePath,
    this.imageFile,
    this.scale,
    this.width,
    this.height,
    this.color,
    this.colorBlendMode,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
    this.placeholderAssetImage,
    this.placeholderBuilder,
    this.progressIndicatorBuilder,
    this.errorBuilder,
    this.showError = false,
    this.showProgressIndicator = false,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheKey,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
    this.placeholderForegroundColor,
    this.httpHeaders,
    this.imageBuilder,
    this.fadeOutDuration = const Duration(milliseconds: 1000),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeInCurve = Curves.easeIn,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.useOldImageOnUrlChange = false,
    this.progressBarColor,
    this.filterQuality = FilterQuality.low,
    this.placeholderFadeInDuration,
    this.borderRadius,
  });

  const StrataImage.network(
    String imageUrl, {
    Key? key,
    String? placeholderAssetImage,
    Widget Function(BuildContext context, String)? placeholderBuilder,
    Widget Function(BuildContext, String, DownloadProgress)?
    progressIndicatorBuilder,
    Widget Function(BuildContext, String, dynamic)? errorBuilder,
    bool showError = false,
    bool showProgressIndicator = false,
    double? height,
    double? width,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
    int? memCacheWidth,
    int? memCacheHeight,
    String? cacheKey,
    int? maxWidthDiskCache,
    int? maxHeightDiskCache,
    Color? shimmerBaseColor,
    Color? shimmerHighlightColor,
    Color? placeholderForegroundColor,
    Map<String, String>? httpHeaders,
    Widget Function(BuildContext context, ImageProvider<Object> imageProvider)?
    imageBuilder,
    Duration fadeOutDuration = const Duration(milliseconds: 1000),
    Curve fadeOutCurve = Curves.easeOut,
    Duration fadeInDuration = const Duration(milliseconds: 500),
    Curve fadeInCurve = Curves.easeIn,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    bool matchTextDirection = false,
    bool useOldImageOnUrlChange = false,
    Color? color,
    Color? progressBarColor,
    FilterQuality filterQuality = FilterQuality.low,
    BlendMode? colorBlendMode,
    Duration? placeholderFadeInDuration,
    BorderRadiusGeometry? borderRadius,
  }) : this._(
         key: key,
         imageUrl: imageUrl,
         placeholderAssetImage: placeholderAssetImage,
         placeholderBuilder: placeholderBuilder,
         progressIndicatorBuilder: progressIndicatorBuilder,
         errorBuilder: errorBuilder,
         showError: showError,
         showProgressIndicator: showProgressIndicator,
         height: height,
         width: width,
         fit: fit,
         borderRadius: borderRadius,
         alignment: alignment,
         memCacheWidth: memCacheWidth,
         memCacheHeight: memCacheHeight,
         cacheKey: cacheKey,
         maxWidthDiskCache: maxWidthDiskCache,
         maxHeightDiskCache: maxHeightDiskCache,
         shimmerBaseColor: shimmerBaseColor,
         shimmerHighlightColor: shimmerHighlightColor,
         placeholderForegroundColor: placeholderForegroundColor,
         httpHeaders: httpHeaders,
         imageBuilder: imageBuilder,
         fadeOutDuration: fadeOutDuration,
         fadeOutCurve: fadeOutCurve,
         fadeInDuration: fadeInDuration,
         fadeInCurve: fadeInCurve,
         repeat: repeat,
         matchTextDirection: matchTextDirection,
         useOldImageOnUrlChange: useOldImageOnUrlChange,
         color: color,
         progressBarColor: progressBarColor,
         filterQuality: filterQuality,
         colorBlendMode: colorBlendMode,
         placeholderFadeInDuration: placeholderFadeInDuration,
       );

  const StrataImage.asset(
    String imagePath, {
    Key? key,
    double? scale,
    double? width,
    double? height,
    Color? color,
    BlendMode? colorBlendMode,
    BoxFit fit = BoxFit.cover,
    Alignment alignment = Alignment.center,
  }) : this._(
         key: key,
         imagePath: imagePath,
         scale: scale,
         width: width,
         height: height,
         color: color,
         colorBlendMode: colorBlendMode,
         fit: fit,
         alignment: alignment,
       );

  final String? imageUrl;
  final String? imagePath;
  final File? imageFile;
  final double? scale;
  final double? width;
  final double? height;
  final Color? color;
  final BlendMode? colorBlendMode;
  final BoxFit fit;
  final Alignment alignment;
  final String? placeholderAssetImage;
  final Widget Function(BuildContext, String)? placeholderBuilder;
  final Widget Function(BuildContext, String, DownloadProgress)?
  progressIndicatorBuilder;
  final Widget Function(BuildContext, String, dynamic)? errorBuilder;
  final bool showError;
  final bool showProgressIndicator;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final String? cacheKey;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final Color? shimmerBaseColor;
  final Color? shimmerHighlightColor;
  final Color? placeholderForegroundColor;
  final Map<String, String>? httpHeaders;
  final Widget Function(BuildContext, ImageProvider<Object>)? imageBuilder;
  final Duration fadeOutDuration;
  final Curve fadeOutCurve;
  final Duration fadeInDuration;
  final Curve fadeInCurve;
  final ImageRepeat repeat;
  final bool matchTextDirection;
  final bool useOldImageOnUrlChange;
  final Color? progressBarColor;
  final FilterQuality filterQuality;
  final Duration? placeholderFadeInDuration;
  final BorderRadiusGeometry? borderRadius;

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return _buildNetworkImage(context);
    } else if (imageFile != null) {
      return _buildFileImage();
    } else if (imagePath != null) {
      return _buildAssetImage(context);
    }
    return const SizedBox.shrink();
  }

  Widget _buildNetworkImage(BuildContext context) {
    return CachedNetworkImage(
      imageUrl: imageUrl!,
      width: width,
      height: height,
      fit: fit,
      color: color,
      colorBlendMode: colorBlendMode,
      alignment: alignment,
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      cacheKey: cacheKey,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      httpHeaders: httpHeaders,
      imageBuilder:
          imageBuilder ??
          (borderRadius != null
              ? (context, imageProvider) => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: borderRadius,
                    image: DecorationImage(
                      image: imageProvider,
                      fit: fit,
                      colorFilter: ColorFilter.mode(
                        color ?? Colors.transparent,
                        colorBlendMode ?? BlendMode.color,
                      ),
                    ),
                  ),
                )
              : null),
      fadeOutDuration: fadeOutDuration,
      fadeOutCurve: fadeOutCurve,
      fadeInDuration: fadeInDuration,
      fadeInCurve: fadeInCurve,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      filterQuality: filterQuality,
      placeholder: _getPlaceholderBuilder(context),
      errorWidget: _getErrorBuilder(context),
      progressIndicatorBuilder: _getProgressBuilder(context),
      placeholderFadeInDuration: placeholderFadeInDuration,
      useOldImageOnUrlChange: useOldImageOnUrlChange,
    );
  }

  Widget _buildFileImage() {
    return Image.file(
      imageFile!,
      key: key,
      scale: scale ?? 1.0,
      width: width,
      height: height,
      color: color,
      fit: fit,
      alignment: alignment,
      colorBlendMode: colorBlendMode,
    );
  }

  Widget _buildAssetImage(BuildContext context) {
    final isSvg = imagePath!.toLowerCase().endsWith('.svg');
    return isSvg
        ? _buildSvgImage()
        : Image.asset(
            imagePath!,
            key: key,
            scale: scale,
            width: width,
            height: height,
            color: color,
            fit: fit,
            alignment: alignment,
            colorBlendMode: colorBlendMode,
          );
  }

  Widget _buildSvgImage() {
    return SvgPicture.asset(
      imagePath!,
      width: width,
      height: height,
      colorFilter: color != null
          ? ColorFilter.mode(color!, colorBlendMode ?? BlendMode.srcOver)
          : null,
      fit: fit,
      alignment: alignment,
    );
  }

  Widget Function(BuildContext, String)? _getPlaceholderBuilder(
    BuildContext context,
  ) {
    return placeholderBuilder ??
        (progressIndicatorBuilder == null && !showProgressIndicator
            ? _defaultPlaceholderBuilder
            : null);
  }

  Widget Function(BuildContext, String, dynamic) _getErrorBuilder(
    BuildContext context,
  ) {
    return errorBuilder ?? _defaultErrorBuilder;
  }

  Widget Function(BuildContext, String, DownloadProgress)? _getProgressBuilder(
    BuildContext context,
  ) {
    return progressIndicatorBuilder ??
        (placeholderBuilder == null && showProgressIndicator
            ? _defaultProgressIndicatorBuilder
            : null);
  }

  Widget _defaultPlaceholderBuilder(BuildContext context, String url) {
    return Shimmer.fromColors(
      baseColor:
          shimmerBaseColor ??
          Theme.of(context).colorScheme.surfaceContainerHighest,
      highlightColor:
          shimmerHighlightColor ?? Theme.of(context).colorScheme.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: borderRadius,
        ),
        child: _buildPlaceholderIcon(context),
      ),
    );
  }

  Widget _buildPlaceholderIcon(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: Icon(
          Icons.photo,
          size: constraints.maxWidth * 0.4,
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _defaultErrorBuilder(BuildContext context, String url, dynamic error) {
    return placeholderAssetImage != null
        ? Image.asset(
            placeholderAssetImage!,
            width: width,
            height: height,
            fit: fit,
            color: Colors.grey.shade300,
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              return Icon(
                Icons.broken_image,
                size: constraints.maxWidth * 0.4,
                color: Theme.of(context).colorScheme.error,
              );
            },
          );
  }

  Widget Function(BuildContext, String, DownloadProgress)
  get _defaultProgressIndicatorBuilder {
    return (BuildContext context, String url, DownloadProgress progress) {
      return FractionallySizedBox(
        heightFactor: 0.3,
        widthFactor: 0.3,
        child: CircularProgressIndicator.adaptive(
          value: progress.downloaded / (progress.totalSize ?? 1),
          strokeWidth: 5,
          strokeAlign: -3,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation<Color>(
            progressBarColor ?? Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    };
  }
}
