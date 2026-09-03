import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Set by the router's `redirect` (`app_router.dart`) when a `concord://invite/{code}` deep link is
/// opened, and consumed once by `HomeScreen` to open the join-server sheet pre-filled with the code.
/// An invite link can't be wired to a plain `GoRoute` the way `/reset-password` is, because joining a
/// server happens through the "Add a Server" modal bottom sheet, not a routable full-screen widget —
/// so the router stashes the intent here instead, and it survives an unauthenticated user being
/// bounced to `/login` first (the provider is global, unaffected by that redirect).
final pendingInviteCodeProvider = StateProvider<String?>((ref) => null);
