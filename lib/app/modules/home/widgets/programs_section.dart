import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/models/models.dart';
import '../../../routes/app_routes.dart';
import '../../../widgets/widgets.dart';

/// Renders the loaded Available Programs section (Requirements 7.1, 7.3).
///
/// Each [Program] is shown with its name and a Register control. Selecting
/// Register navigates to the registration entry point for *that* program,
/// passing the program as the route argument so the destination screen
/// (Task 16) can render the registration for the selected program
/// (Req 7.2 — `Get.toNamed(AppRoutes.programs, arguments: program)`).
///
/// This widget renders the *non-empty* list only; the empty-state (which
/// withholds every register control, Req 7.3) is handled by the Home view.
class ProgramsSection extends StatelessWidget {
  const ProgramsSection({
    super.key,
    required this.programs,
    this.onRegister,
  });

  /// The active organization's programs to display (non-empty).
  final List<Program> programs;

  /// Optional override for the Register action; defaults to navigating to the
  /// registration entry point for the selected program.
  final void Function(Program program)? onRegister;

  void _register(Program program) {
    if (onRegister != null) {
      onRegister!(program);
      return;
    }
    Get.toNamed<void>(AppRoutes.programs, arguments: program);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: programs.length,
      separatorBuilder: (_, __) => const SizedBox(width: 14),
      itemBuilder: (BuildContext context, int index) {
        final Program program = programs[index];
        return SizedBox(
          width: 280,
          child: _ProgramCard(
            program: program,
            onRegister: () => _register(program),
          ),
        );
      },
    );
  }
}

class _ProgramCard extends StatelessWidget {
  const _ProgramCard({
    required this.program,
    required this.onRegister,
  });

  final Program program;
  final VoidCallback onRegister;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.event_available_rounded,
                    color: scheme.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    program.name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              'Register for this program to join the next available session.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withValues(alpha: 0.70),
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            KioskButton(
              label: 'Register',
              icon: Icons.app_registration_rounded,
              onPressed: onRegister,
            ),
          ],
        ),
      ),
    );
  }
}
