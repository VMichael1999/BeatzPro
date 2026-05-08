import 'package:flutter/material.dart';

import 'glass_widgets.dart';

class CommonDialog extends StatelessWidget {
  const CommonDialog({super.key, this.child});
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            child: GlassContainer(
              borderRadius: 28,
              blur: 22,
              opacity: 0.14,
              padding: EdgeInsets.zero,
              child: child ?? const SizedBox.shrink(),
            ),
          )),
    );
  }
}
