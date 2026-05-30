import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/data/models/models.dart';
import '../../widgets/widgets.dart';
import '../auth/login_validator.dart';
import '../home/section_state.dart';
import 'programs_controller.dart';

/// The organization-scoped Programs destination screen (Requirement 7.2).
///
/// Reachable two ways, both themed consistently with the Home_Screen via the
/// shared [KioskDestinationScaffold]:
/// * from a Home "Register" control — `Get.arguments` carries the selected
///   [Program] and the screen opens that program's registration entry point
///   directly;
/// * from the sidebar — no argument; the screen lists every program for the
///   active organization, each with a Register action that opens the
///   registration entry point for that program.
///
/// The content swaps between the list and the registration panel based on the
/// controller's [ProgramsController.selectedProgram]; a failed/empty load shows
/// the matching error+retry / empty-state.
class ProgramsView extends GetView<ProgramsController> {
  const ProgramsView({super.key});

  @override
  Widget build(BuildContext context) {
    return KioskDestinationScaffold(
      active: KioskDestination.programs,
      child: Obx(() {
        final Program? selected = controller.selectedProgram.value;
        if (selected != null) {
          return _ProgramRegistrationPanel(
            program: selected,
            onCancel: controller.clearSelection,
            onSubmit: controller.confirmRegistration,
          );
        }
        return _ProgramsList(controller: controller);
      }),
    );
  }
}

/// The full programs list (sidebar entry point). Maps the controller's
/// [SectionState] to loading / loaded / empty / error views (Requirements 7.1,
/// 7.3).
class _ProgramsList extends StatelessWidget {
  const _ProgramsList({required this.controller});

  final ProgramsController controller;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Available Programs',
      icon: Icons.event_rounded,
      expandChild: true,
      child: Obx(() {
        final SectionState<List<Program>> state = controller.programs.value;

        if (state is SectionLoading<List<Program>>) {
          return const SingleChildScrollView(
            child: ShimmerLoader(shape: ShimmerShape.programsList),
          );
        }
        if (state is SectionEmpty<List<Program>>) {
          return const _ProgramsEmptyState();
        }
        if (state is SectionError<List<Program>>) {
          return _ProgramsErrorState(
            message: state.message,
            onRetry: controller.load,
          );
        }
        if (state is SectionLoaded<List<Program>>) {
          return _ProgramsLoaded(
            programs: state.data,
            onRegister: controller.selectProgram,
          );
        }
        return const SizedBox.shrink();
      }),
    );
  }
}

/// The loaded, non-empty programs list: each program with a Register control
/// that opens its registration entry point (Requirements 7.1, 7.2).
class _ProgramsLoaded extends StatelessWidget {
  const _ProgramsLoaded({required this.programs, required this.onRegister});

  final List<Program> programs;
  final ValueChanged<Program> onRegister;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return ListView.separated(
      itemCount: programs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (BuildContext context, int index) {
        final Program program = programs[index];
        return Row(
          children: <Widget>[
            Icon(
              Icons.event_rounded,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                program.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            KioskButton(
              label: 'Register',
              icon: Icons.app_registration_rounded,
              onPressed: () => onRegister(program),
            ),
          ],
        );
      },
    );
  }
}

/// Empty-state for the programs list, withholding every register control
/// (Requirement 7.3).
class _ProgramsEmptyState extends StatelessWidget {
  const _ProgramsEmptyState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(
            Icons.event_busy_rounded,
            size: 48,
            color: scheme.onSurface.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 12),
          Text(
            'No programs available.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: scheme.onSurface.withValues(alpha: 0.55),
            ),
          ),
        ],
      ),
    );
  }
}

/// Error-state for the programs list with a Retry control (Requirement 3.6).
class _ProgramsErrorState extends StatelessWidget {
  const _ProgramsErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 48, color: scheme.error),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(color: scheme.error),
          ),
          const SizedBox(height: 16),
          KioskButton(
            label: 'Retry',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}

/// The registration entry point for a selected program (Requirement 7.2).
///
/// A simple, themed registration form scaffold: the program name plus name and
/// email fields with a Register submit that confirms via the
/// [NotificationService] (wired through the controller).
class _ProgramRegistrationPanel extends StatefulWidget {
  const _ProgramRegistrationPanel({
    required this.program,
    required this.onCancel,
    required this.onSubmit,
  });

  final Program program;
  final VoidCallback onCancel;
  final void Function({required String name, required String email}) onSubmit;

  @override
  State<_ProgramRegistrationPanel> createState() =>
      _ProgramRegistrationPanelState();
}

class _ProgramRegistrationPanelState extends State<_ProgramRegistrationPanel> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String? _nameError;
  String? _emailError;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameController.text.trim();
    final String email = _emailController.text.trim();

    final String? nameError = name.isEmpty ? 'Name is required.' : null;
    final String? emailError = LoginValidator.validateEmail(email);

    setState(() {
      _nameError = nameError;
      _emailError = emailError;
    });

    if (nameError != null || emailError != null) {
      return;
    }

    widget.onSubmit(name: name, email: email);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SectionCard(
      title: 'Register',
      icon: Icons.app_registration_rounded,
      expandChild: true,
      action: KioskButton(
        label: 'All programs',
        icon: Icons.arrow_back_rounded,
        variant: KioskButtonVariant.secondary,
        onPressed: widget.onCancel,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              widget.program.name,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Enter your details to register for this program.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            KioskTextField(
              label: 'Full name',
              controller: _nameController,
              prefixIcon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              errorText: _nameError,
              onChanged: (_) {
                if (_nameError != null) {
                  setState(() => _nameError = null);
                }
              },
            ),
            const SizedBox(height: 16),
            KioskTextField(
              label: 'Email',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              errorText: _emailError,
              onChanged: (_) {
                if (_emailError != null) {
                  setState(() => _emailError = null);
                }
              },
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 24),
            KioskButton(
              label: 'Register',
              icon: Icons.check_rounded,
              expand: true,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
