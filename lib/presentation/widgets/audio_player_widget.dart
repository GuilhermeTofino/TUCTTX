import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:just_audio/just_audio.dart';

class AudioPlayerWidget extends StatefulWidget {
  final String url;
  final VoidCallback? onPlay;

  const AudioPlayerWidget({super.key, required this.url, this.onPlay});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget> {
  late AudioPlayer _player;
  bool _isInit = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _init();
  }

  Future<void> _init() async {
    try {
      await _player.setUrl(widget.url);
      if (mounted) {
        setState(() {
          _isInit = true;
        });
      }
    } catch (e) {
      print("Erro ao carregar áudio: $e");
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit) {
      return const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Container(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              StreamBuilder<PlayerState>(
                stream: _player.playerStateStream,
                builder: (context, snapshot) {
                  final playerState = snapshot.data;
                  final processingState = playerState?.processingState;
                  final playing = playerState?.playing;

                  if (processingState == ProcessingState.loading ||
                      processingState == ProcessingState.buffering) {
                    return const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(),
                    );
                  } else if (playing != true) {
                    return IconButton(
                      icon: const Icon(Icons.play_circle_fill),
                      iconSize: 48,
                      color: Colors.orange,
                      onPressed: () {
                        widget.onPlay?.call();
                        _player.play();
                      },
                    );
                  } else if (processingState != ProcessingState.completed) {
                    return IconButton(
                      icon: const Icon(Icons.pause_circle_filled),
                      iconSize: 48,
                      color: Colors.orange,
                      onPressed: _player.pause,
                    );
                  } else {
                    return IconButton(
                      icon: const Icon(Icons.replay_circle_filled),
                      iconSize: 48,
                      color: Colors.orange,
                      onPressed: () => _player.seek(Duration.zero),
                    );
                  }
                },
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StreamBuilder<Duration>(
                  stream: _player.positionStream,
                  builder: (context, snapshot) {
                    final position = snapshot.data ?? Duration.zero;
                    final total = _player.duration ?? Duration.zero;

                    return ProgressBar(
                      progress: position,
                      total: total,
                      progressBarColor: Colors.orange,
                      baseBarColor: Colors.orange.withOpacity(0.15),
                      thumbColor: Colors.orange,
                      barHeight: 6,
                      thumbRadius: 8,
                      thumbGlowRadius: 20,
                      onSeek: (duration) {
                        _player.seek(duration);
                      },
                      timeLabelLocation: TimeLabelLocation.below,
                      timeLabelPadding: 8,
                      timeLabelTextStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
