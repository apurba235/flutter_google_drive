import 'dart:ui';

import 'package:flutter/material.dart';

class CircularProgressIndicatorWithBackdrop extends StatelessWidget {
  const CircularProgressIndicatorWithBackdrop({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaY: 3, sigmaX: 3),
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}