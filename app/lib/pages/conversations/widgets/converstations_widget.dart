import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/src/services/haptic_feedback.dart';
import 'package:omi/pages/conversation_capturing/page.dart';
import 'package:omi/pages/conversations/widgets/processing_capture.dart';
import 'package:omi/providers/capture_provider.dart';
import 'package:omi/utils/analytics/mixpanel.dart';
import 'package:omi/utils/enums.dart';
import 'package:omi/utils/styles.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import 'package:waveform_flutter/waveform_flutter.dart';

class AmplitudeTestWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CaptureProvider>(
      builder: (context, captureProvider, child) {
        return Column(
          children: [
            Text('Recording State: ${captureProvider.recordingState}'),
            Text('Mic Level: ${captureProvider.microphoneLevel}'),
            Text('System Audio Level: ${captureProvider.systemAudioLevel}'),

            StreamBuilder<double>(
              stream: captureProvider.amplitudeStream,
              builder: (context, snapshot) {
                return Text('Stream Amplitude: ${snapshot.data ?? "No data"}');
              },
            ),

            // Simple visual indicator
            StreamBuilder<double>(
              stream: captureProvider.amplitudeStream,
              builder: (context, snapshot) {
                double amplitude = snapshot.data ?? 0.0;
                return Container(
                  width: 200,
                  height: 20,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: LinearProgressIndicator(
                    value: amplitude,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class ConverstationsWidget extends StatefulWidget {
  const ConverstationsWidget({super.key});

  @override
  State<ConverstationsWidget> createState() => _ConverstationsWidgetState();
}

class _ConverstationsWidgetState extends State<ConverstationsWidget> {
  late final Stream<Amplitude> _mockAmplitudeStream;
  final Random _random = Random();
  bool _isPhoneMicPaused = false;
  @override
  void initState() {
    super.initState();

    // Simulate an audio input stream (values from 0–100)
    _mockAmplitudeStream = Stream.periodic(
      const Duration(milliseconds: 70),
      (count) => Amplitude(
        current: 10 * 100,
        // current: Random().nextDouble() * 20, // 🔥 smaller wave (0–20 instead of 0–100)
        max: 100,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CaptureProvider>(builder: (context, provider, child) {
      bool isDeviceRecording = provider.havingRecordingDevice &&
          (provider.recordingState == RecordingState.deviceRecord || provider.recordingState == RecordingState.pause);
      bool isPhoneRecording = provider.recordingState == RecordingState.record ||
          provider.recordingState == RecordingState.systemAudioRecord ||
          provider.recordingState == RecordingState.initialising ||
          _isPhoneMicPaused;
      bool isRecording = provider.recordingState == RecordingState.record;

      print("💌💌💌💌💌💌💌>=== ${isRecording}");
      // Determine pause state based on recording type
      bool isPaused = false;
      if (isDeviceRecording) {
        isPaused = provider.isPaused && provider.recordingState == RecordingState.pause;
      } else if (isPhoneRecording) {
        isPaused = _isPhoneMicPaused || provider.isPaused;
      }
      return Container(
        width: double.infinity,
        child: Column(
          children: [
            // lestning charts

            Container(
              // height: 30,
              //child: AudioWaveformDemo(),
              child: ShaderMask(
                shaderCallback: (bounds) => LinearGradient(
                  colors: [
                    const Color.fromRGBO(131, 189, 200, 1),
                    TayaColors.secondaryTextColor,
                    const Color.fromRGBO(131, 189, 200, 1)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ).createShader(bounds),
                blendMode: BlendMode.srcIn,
                child: Waveform(
                  //amplitudeStream: _mockAmplitudeStream,
                  amplitudeStream: provider.amplitudeStream.asyncMap((val) {
                    return Amplitude(current: val * 100, max: 100);
                  }),
                ),
              ),
            ),
            // AmplitudeTestWidget(),
            Container(
              // color: Colors.red,
              padding: const EdgeInsets.only(bottom: 15),
              child: Center(
                child: Text(
                  "Live transcription · Auto-stops after silence",
                  style: TextStyle(color: TayaColors.secondaryTextColor, fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ),
            // Show transcript below controls during recording

            Stack(
              children: [
                if (provider.segments.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 12, bottom: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: AutoScrollingText(
                      text: provider.segments.map((segment) => segment.text).join(' '),
                    ),
                  ),
                ],
                SizedBox(
                  height: 15,
                ),
                Align(
                  alignment: Alignment.center,
                  child: PlayPauseButton(
                    isPlaying: isRecording,
                  ),
                ),
              ],
            )
          ],
        ),
      );
    });
  }
}

class PlayPauseButton extends StatefulWidget {
  final double size;
  final Color color;
  final bool isPlaying;

  const PlayPauseButton({
    super.key,
    this.size = 48,
    this.color = Colors.black,
    this.isPlaying = false,
  });

  @override
  State<PlayPauseButton> createState() => _PlayPauseButtonState();
}

class _PlayPauseButtonState extends State<PlayPauseButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late bool _isPlaying;

  @override
  void initState() {
    super.initState();
    _isPlaying = widget.isPlaying; // 👈 initialize from widget

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 👇 if starting as playing, forward the animation
    if (_isPlaying) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(PlayPauseButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Listen to changes from the provider
    if (oldWidget.isPlaying != widget.isPlaying) {
      setState(() {
        _isPlaying = widget.isPlaying;
        if (_isPlaying) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        width: 70,
        height: 70,
        decoration: const BoxDecoration(
          color: Color.fromRGBO(59, 159, 178, 1),
          shape: BoxShape.circle,
        ),
        child: Consumer<CaptureProvider>(builder: (context, provider, child) {
          bool isInitializing = provider.recordingState == RecordingState.initialising;
          return IconButton(
            iconSize: widget.size,
            color: widget.color,
            icon: AnimatedIcon(
              color: Colors.white,
              icon: AnimatedIcons.play_pause,
              progress: _controller,
            ),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              if (isInitializing) return;
              await _handleRecordButtonPress(context, provider);
              // setState(() {
              //   if (_isPlaying) {
              //     _controller.reverse();
              //   } else {
              //     _controller.forward();
              //   }
              //   _isPlaying = !_isPlaying;
              // });
            },
          );
        }));
  }
}

Future<void> _handleRecordButtonPress(BuildContext context, CaptureProvider captureProvider) async {
  var recordingState = captureProvider.recordingState;

  if (recordingState == RecordingState.record) {
    // Stop recording and summarize conversation
    await captureProvider.stopStreamRecording();
    captureProvider.forceProcessingCurrentConversation();
    MixpanelManager().phoneMicRecordingStopped();
  } else if (recordingState == RecordingState.initialising) {
    // Already initializing, do nothing
    debugPrint('initialising, have to wait');
  } else {
    // Start recording directly without dialog
    await captureProvider.streamRecording();
    MixpanelManager().phoneMicRecordingStarted();

    // Navigate to conversation capturing page
    if (context.mounted) {
      var topConvoId = (captureProvider.conversationProvider?.conversations ?? []).isNotEmpty
          ? captureProvider.conversationProvider!.conversations.first.id
          : null;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConversationCapturingPage(topConversationId: topConvoId),
        ),
      );
    }
  }
}

// class AudioWaveformUI extends StatefulWidget {
//   final double height;
//   final Color backgroundColor;
//   final Color waveColor;
//   final Color dotColor;

//   const AudioWaveformUI({
//     super.key,
//     this.height = 30,
//     this.backgroundColor = const Color(0xFFB8D4D9),
//     this.waveColor = const Color(0xFF4A90A4),
//     this.dotColor = const Color(0xFF6B9AA0),
//   });

//   @override
//   State<AudioWaveformUI> createState() => _AudioWaveformUIState();
// }

// class _AudioWaveformUIState extends State<AudioWaveformUI> with TickerProviderStateMixin {
//   bool _isRecording = false;
//   bool _isSpeaking = false; // New state for when user is speaking
//   late AnimationController _waveController;
//   late AnimationController _dotController;
//   late Animation<double> _waveAnimation;

//   List<double> _waveHeights = [];
//   final Random _random = Random();

//   @override
//   void initState() {
//     super.initState();

//     _waveController = AnimationController(
//       duration: const Duration(milliseconds: 150),
//       vsync: this,
//     );

//     _dotController = AnimationController(
//       duration: const Duration(milliseconds: 1500),
//       vsync: this,
//     )..repeat();

//     _waveAnimation = Tween<double>(begin: 0, end: 1).animate(_waveController);

//     // Initialize with some random wave heights
//     _generateWaveHeights();

//     // Start the wave animation loop
//     _startWaveAnimation();
//   }

//   void _generateWaveHeights() {
//     _waveHeights = List.generate(50, (index) {
//       if (!_isRecording || !_isSpeaking) return 2.0; // Flat line when not recording or not speaking

//       // Simulate realistic speech patterns
//       return _generateSpeechLikeWave(index);
//     });
//   }

//   double _generateSpeechLikeWave(int index) {
//     final time = DateTime.now().millisecondsSinceEpoch / 200.0; // Faster time scale

//     // Create speech-like patterns with pauses and emphasis
//     final speechCycle = (time * 0.5) % 8; // 8-second speech cycle

//     if (speechCycle < 1) {
//       // Pause/silence
//       return _random.nextDouble() * 4 + 2;
//     } else if (speechCycle < 2.5) {
//       // Building up
//       final progress = (speechCycle - 1) / 1.5;
//       return _random.nextDouble() * (widget.height * 0.4 * progress) + 3;
//     } else if (speechCycle < 5.5) {
//       // Active speaking with lots of variation
//       final baseHeight = widget.height * 0.3;
//       final variation = sin((time * 2 + index * 0.8)) * widget.height * 0.25;
//       final randomness = (_random.nextDouble() - 0.5) * widget.height * 0.3;
//       final pulse = sin(time * 3) * widget.height * 0.1; // Add pulse effect
//       return (baseHeight + variation + randomness + pulse).clamp(4.0, widget.height * 0.85);
//     } else if (speechCycle < 7) {
//       // Emphasis/louder part
//       final baseHeight = widget.height * 0.5;
//       final variation = sin((time * 2.5 + index * 0.4)) * widget.height * 0.2;
//       final randomness = (_random.nextDouble() - 0.5) * widget.height * 0.2;
//       return (baseHeight + variation + randomness).clamp(6.0, widget.height * 0.9);
//     } else {
//       // Winding down
//       final progress = 1.0 - ((speechCycle - 7) / 1.0);
//       return _random.nextDouble() * (widget.height * 0.2 * progress) + 2;
//     }
//   }

//   void _startWaveAnimation() {
//     if (_isRecording) {
//       // Generate new wave data immediately
//       setState(() {
//         _generateWaveHeights();
//       });

//       _waveController.forward().then((_) {
//         if (mounted && _isRecording) {
//           _waveController.reset();
//           _startWaveAnimation(); // Continue the loop
//         }
//       });
//     }
//   }

//   void toggleRecording() {
//     setState(() {
//       _isRecording = !_isRecording;
//       if (_isRecording) {
//         _startWaveAnimation();
//         // Auto-start speaking simulation after a brief delay
//         Future.delayed(const Duration(milliseconds: 500), () {
//           if (mounted && _isRecording) {
//             startSpeaking();
//           }
//         });
//       } else {
//         _waveController.stop();
//         _isSpeaking = false;
//         _generateWaveHeights(); // Reset to flat line
//       }
//     });
//   }

//   void startSpeaking() {
//     setState(() {
//       _isSpeaking = true;
//     });

//     // Auto-stop speaking after 3-5 seconds to simulate natural pauses
//     final speakingDuration = 3000 + _random.nextInt(2000); // 3-5 seconds
//     Future.delayed(Duration(milliseconds: speakingDuration), () {
//       if (mounted && _isRecording) {
//         stopSpeaking();
//       }
//     });
//   }

//   void stopSpeaking() {
//     setState(() {
//       _isSpeaking = false;
//     });

//     // Start speaking again after a pause (1-3 seconds)
//     final pauseDuration = 1000 + _random.nextInt(2000); // 1-3 seconds
//     Future.delayed(Duration(milliseconds: pauseDuration), () {
//       if (mounted && _isRecording) {
//         startSpeaking();
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _waveController.dispose();
//     _dotController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       height: widget.height,
//       decoration: BoxDecoration(
//         color: widget.backgroundColor,
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: (_isRecording && _isSpeaking) ? _buildWaveform() : _buildDottedLine(),
//     );
//   }

//   Widget _buildDottedLine() {
//     return AnimatedBuilder(
//       animation: _dotController,
//       builder: (context, child) {
//         return CustomPaint(
//           painter: DottedLinePainter(
//             dotColor: widget.dotColor,
//             animationValue: _dotController.value,
//           ),
//           size: Size.infinite,
//         );
//       },
//     );
//   }

//   Widget _buildWaveform() {
//     return AnimatedBuilder(
//       animation: _waveAnimation,
//       builder: (context, child) {
//         return CustomPaint(
//           painter: WaveformPainter(
//             waveHeights: _waveHeights,
//             waveColor: widget.waveColor,
//             maxHeight: widget.height,
//             animationValue: _waveAnimation.value,
//           ),
//           size: Size.infinite,
//         );
//       },
//     );
//   }
// }

// class DottedLinePainter extends CustomPainter {
//   final Color dotColor;
//   final double animationValue;

//   DottedLinePainter({
//     required this.dotColor,
//     required this.animationValue,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = dotColor
//       ..strokeCap = StrokeCap.round;

//     final centerY = size.height / 2;
//     final dotSpacing = 8.0;
//     final dotRadius = 1.5;
//     final totalDots = (size.width / dotSpacing).floor();

//     // Create animated effect by varying opacity
//     for (int i = 0; i < totalDots; i++) {
//       final x = i * dotSpacing + dotSpacing / 2;

//       // Create a wave-like opacity animation
//       final phase = (i / totalDots) * 2 * pi + (animationValue * 2 * pi);
//       final opacity = (sin(phase) * 0.3 + 0.7).clamp(0.4, 1.0);

//       paint.color = dotColor.withOpacity(opacity);
//       canvas.drawCircle(Offset(x, centerY), dotRadius, paint);
//     }
//   }

//   @override
//   bool shouldRepaint(DottedLinePainter oldDelegate) {
//     return oldDelegate.animationValue != animationValue;
//   }
// }

// class WaveformPainter extends CustomPainter {
//   final List<double> waveHeights;
//   final Color waveColor;
//   final double maxHeight;
//   final double animationValue;

//   WaveformPainter({
//     required this.waveHeights,
//     required this.waveColor,
//     required this.maxHeight,
//     required this.animationValue,
//   });

//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = waveColor
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = 2;

//     final centerY = size.height / 2;
//     final barWidth = 3.0;
//     final barSpacing = 2.0;
//     final totalBarWidth = barWidth + barSpacing;
//     final maxBars = (size.width / totalBarWidth).floor();

//     for (int i = 0; i < maxBars && i < waveHeights.length; i++) {
//       final x = i * totalBarWidth + barWidth / 2;
//       final height = waveHeights[i] * animationValue;

//       // Draw the waveform bar (centered vertically)
//       canvas.drawLine(
//         Offset(x, centerY - height / 2),
//         Offset(x, centerY + height / 2),
//         paint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(WaveformPainter oldDelegate) {
//     return oldDelegate.waveHeights != waveHeights || oldDelegate.animationValue != animationValue;
//   }
// }

// // Demo widget to test the waveform UI with realistic speech simulation
// class AudioWaveformDemo extends StatelessWidget {
//   const AudioWaveformDemo({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//     child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             const Icon(
//               Icons.person,
//               size: 80,
//               color: Colors.grey,
//             ),
//             const SizedBox(height: 20),
//             const Text(
//               '🎤 Tap to start recording\n'
//               '• Dotted line = listening but no speech\n'
//               '• Waveform = user is speaking\n'
//               '• Auto-simulates speech patterns with pauses',
//               style: TextStyle(fontSize: 14, color: Colors.grey),
//               textAlign: TextAlign.center,
//             ),
//             const SizedBox(height: 30),

//             // Main waveform widget with speech simulation
//             Builder(
//               builder: (context) {
//                 return GestureDetector(
//                   onTap: () {
//                     // Find the AudioWaveformUI and toggle it
//                     final audioWaveform = context.findAncestorStateOfType<_AudioWaveformUIState>();
//                     audioWaveform?.toggleRecording();
//                   },
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(20),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.1),
//                           blurRadius: 10,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: const AudioWaveformUI(height: 30),
//                   ),
//                 );
//               },
//             ),

//             const SizedBox(height: 40),

//             const Text(
//               'Speech Pattern Simulation:',
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),
//             const SizedBox(height: 10),
//             const Text(
//               '• Starts quiet (pause)\n'
//               '• Builds up volume\n'
//               '• Active speaking with variations\n'
//               '• Emphasis/louder moments\n'
//               '• Winds down\n'
//               '• Brief pause before repeating',
//               style: TextStyle(fontSize: 12, color: Colors.grey),
//             ),

//             const SizedBox(height: 30),

//             // Different conversation scenarios
//             const Text('Different Conversation Types:', style: TextStyle(fontSize: 14, color: Colors.grey)),
//             const SizedBox(height: 15),

//             // Quiet conversation
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: Column(
//                 children: [
//                   const Text('Quiet Conversation', style: TextStyle(fontSize: 12)),
//                   const SizedBox(height: 5),
//                   AudioWaveformUI(
//                     height: 25,
//                     backgroundColor: const Color(0xFFF0F8FF),
//                     waveColor: const Color(0xFF64B5F6),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 10),

//             // Animated conversation
//             Container(
//               padding: const EdgeInsets.all(10),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(15),
//               ),
//               child: Column(
//                 children: [
//                   const Text('Animated Discussion', style: TextStyle(fontSize: 12)),
//                   const SizedBox(height: 5),
//                   AudioWaveformUI(
//                     height: 35,
//                     backgroundColor: const Color(0xFFFFF3E0),
//                     waveColor: const Color(0xFFFF9800),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
