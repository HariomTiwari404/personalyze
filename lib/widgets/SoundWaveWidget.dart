import 'package:flutter/material.dart';

class SoundWaveWidget extends StatelessWidget {
  final List<double> soundLevels;
  final Color color;

  const SoundWaveWidget({
    required this.soundLevels,
    this.color = Colors.white,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          soundLevels.length,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 50),
              width: 2,
              height: (soundLevels[index] * 100).clamp(5, 100).toDouble(),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
