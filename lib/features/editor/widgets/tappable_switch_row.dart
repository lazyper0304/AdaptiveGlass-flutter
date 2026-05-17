import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

class TappableSwitchRow extends StatefulWidget {
  const TappableSwitchRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.activeColor,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color activeColor;

  @override
  State<TappableSwitchRow> createState() => _TappableSwitchRowState();
}

class _TappableSwitchRowState extends State<TappableSwitchRow> {
  static const double _tapMovementLimit = 10;

  Offset? _pointerStart;
  int _pointerSequence = 0;
  bool _switchHandledPointer = false;

  void _handlePointerDown(PointerDownEvent event) {
    _pointerSequence += 1;
    _pointerStart = event.localPosition;
    _switchHandledPointer = false;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerStart = null;
  }

  void _handlePointerUp(PointerUpEvent event) {
    final start = _pointerStart;
    _pointerStart = null;
    if (start == null) {
      return;
    }

    final isTap = (event.localPosition - start).distance <= _tapMovementLimit;
    if (isTap) {
      final sequence = _pointerSequence;
      final nextValue = !widget.value;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || sequence != _pointerSequence || _switchHandledPointer) {
          return;
        }
        widget.onChanged(nextValue);
      });
    }
  }

  void _handleSwitchChanged(bool value) {
    _switchHandledPointer = true;
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      toggled: widget.value,
      label: widget.label,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handlePointerDown,
        onPointerCancel: _handlePointerCancel,
        onPointerUp: _handlePointerUp,
        child: Row(
          children: [
            Expanded(
              child: Text(
                widget.label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.88),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            GlassSwitch(
              value: widget.value,
              onChanged: _handleSwitchChanged,
              activeColor: widget.activeColor,
              quality: GlassQuality.standard,
            ),
          ],
        ),
      ),
    );
  }
}
