import 'package:flutter/material.dart';

/// Widget que anima la aparición de un item de lista con fade-in y slide-up
class AnimatedListItem extends StatefulWidget {
  // El widget que va a animar
  final Widget child;
  // posición del item en la lista para calcular el retraso
  final int index;
  // Duración del retraso entre items
  final Duration delay;

  const AnimatedListItem({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 20), // Más lento
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  // Controla la duracion de la animación
  late AnimationController _controller;
  // Animaciones de opacidad
  late Animation<double> _fadeAnimation;
  // Animación de desplazamiento
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 900), // Más lento
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // hace que cada elemento aparezca con animacion basado en el índice
    Future.delayed(widget.delay * widget.index, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}
