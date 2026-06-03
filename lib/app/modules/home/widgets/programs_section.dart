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
          child: ProgramCampaignCard(
            program: program,
            compact: true,
            onTap: () => Get.toNamed<void>(AppRoutes.programs, arguments: program),
            onRegister: () => _register(program),
          ),
        );
      },
    );
  }
}
