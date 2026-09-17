import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/voice_call_controller.dart';
import 'incoming_call_modal.dart';

class VoiceCallOverlay extends ConsumerWidget {
  const VoiceCallOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceCallControllerProvider);
    final controller = ref.read(voiceCallControllerProvider.notifier);
    final incomingCall = state.incomingCall;

    return Stack(
      children: [
        child,
        if (incomingCall != null)
          Positioned.fill(
            child: PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) {
                if (didPop) return;
                controller.declineIncomingCall();
              },
              child: IncomingCallModal(
                callerName: incomingCall.callerName,
                callerAvatarUrl: incomingCall.callerAvatarUrl,
                type: incomingCall.type,
                onAccept: controller.acceptIncomingCall,
                onDecline: controller.declineIncomingCall,
              ),
            ),
          ),
      ],
    );
  }
}
