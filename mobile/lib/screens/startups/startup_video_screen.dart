import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import 'package:mescla_invest/themes/app_theme.dart';
import 'package:mescla_invest/widgets/premium_ui.dart';

class StartupVideoScreen extends StatefulWidget {
  final String title;
  final String videoUrl;

  const StartupVideoScreen({
    super.key,
    required this.title,
    required this.videoUrl,
  });

  @override
  State<StartupVideoScreen> createState() => _StartupVideoScreenState();
}

class _StartupVideoScreenState extends State<StartupVideoScreen> {
  late final VideoPlayerController _controller;
  bool _loading = true;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _inicializarVideo();
  }

  Future<void> _inicializarVideo() async {
    try {
      _controller = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );

      await _controller.initialize();
      await _controller.play();

      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = true;
      });
    }
  }

  @override
  void dispose() {
    if (!_error) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _togglePlayPause() {
    if (_error || _loading) return;

    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fundo,
      appBar: AppBar(
        backgroundColor: AppColors.fundo,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: AppColors.destaque,
        ),
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.destaque,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PremiumHeaderEyebrow(
              text: 'PITCH EM VÍDEO',
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Center(
                child: _buildVideoContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent() {
    if (_loading) {
      return const CircularProgressIndicator(
        color: AppColors.destaque,
      );
    }

    if (_error) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: premiumCardDecoration(
          radius: 24,
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              color: AppColors.destaque,
              size: 38,
            ),
            SizedBox(height: 14),
            Text(
              'Não foi possível carregar o vídeo desta startup.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textoPrincipal,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: premiumCardDecoration(
            radius: 24,
          ),
          padding: const EdgeInsets.all(6),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AspectRatio(
              aspectRatio: _controller.value.aspectRatio,
              child: VideoPlayer(_controller),
            ),
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destaque,
              foregroundColor: AppColors.fundo,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: _togglePlayPause,
            icon: Icon(
              _controller.value.isPlaying
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(
              _controller.value.isPlaying ? 'Pausar vídeo' : 'Reproduzir vídeo',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
