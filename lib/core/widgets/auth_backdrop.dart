import 'package:flutter/material.dart';

/// Full-bleed onboarding artwork faded into the page, with the form content
/// scrolling above it.
class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({
    required this.image,
    required this.child,
    this.artOnTop = false,
    this.artTopFraction = .28,
    super.key,
  });

  final String image;
  final Widget child;
  final bool artOnTop;
  final double artTopFraction;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xfffaf9ff)),
          Positioned(
            top: artOnTop ? 0 : size.height * artTopFraction,
            left: 0,
            right: 0,
            height: artOnTop ? size.height * .64 : null,
            bottom: artOnTop ? null : 0,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (bounds) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: artOnTop
                    ? const [Colors.white, Colors.white, Colors.transparent]
                    : const [Colors.transparent, Colors.white, Colors.white],
                stops: artOnTop ? const [0, .82, 1] : const [0, .18, 1],
              ).createShader(bounds),
              child: Image.asset(image, fit: BoxFit.cover),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(26, 12, 26, 32),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: size.height - MediaQuery.paddingOf(context).vertical - 44,
                ),
                child: child,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
