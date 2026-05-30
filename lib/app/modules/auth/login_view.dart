import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/app_constants.dart';
import '../../widgets/widgets.dart';
import 'login_controller.dart';

/// The administrator login screen (Requirement 1).
///
/// A landscape-friendly, centered login card with organization/app branding,
/// email and password fields wired to the [LoginController]'s per-field error
/// observables, and a submit button whose loading/disabled state is driven by
/// [LoginController.isSubmitting] (Requirements 1.1, 1.6, 1.7). A small demo
/// credentials hint keeps the seeded Palos/An-Noor demo usable. All transient
/// messaging is handled by the controller via the `NotificationService`.
class LoginView extends GetView<LoginController> {
  const LoginView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: SectionCard(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _buildBranding(theme),
                      const SizedBox(height: 28),
                      _buildEmailField(),
                      const SizedBox(height: 18),
                      _buildPasswordField(),
                      const SizedBox(height: 28),
                      _buildSubmitButton(),
                      const SizedBox(height: 20),
                      _buildDemoHint(theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// App/organization branding header: logo, app name, and a short prompt.
  Widget _buildBranding(ThemeData theme) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          height: 72,
          width: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.mosque_rounded,
            size: 40,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Administrator sign in',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.70),
          ),
        ),
      ],
    );
  }

  /// Email field with inline error bound to [LoginController.emailError].
  Widget _buildEmailField() {
    return Obx(
      () => KioskTextField(
        label: 'Email',
        controller: controller.emailController,
        errorText: controller.emailError.value,
        prefixIcon: Icons.email_outlined,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.next,
        enabled: !controller.isSubmitting.value,
        onChanged: controller.onEmailChanged,
        autofocus: true,
      ),
    );
  }

  /// Obscured password field with inline error bound to
  /// [LoginController.passwordError]; submitting from the keyboard triggers
  /// [LoginController.submit].
  Widget _buildPasswordField() {
    return Obx(
      () => KioskTextField(
        label: 'Password',
        controller: controller.passwordController,
        errorText: controller.passwordError.value,
        prefixIcon: Icons.lock_outline,
        obscureText: true,
        textInputAction: TextInputAction.done,
        enabled: !controller.isSubmitting.value,
        onChanged: controller.onPasswordChanged,
        onSubmitted: (_) => controller.submit(),
      ),
    );
  }

  /// Submit button: shows a spinner and is disabled while submitting
  /// (Requirement 1.7).
  Widget _buildSubmitButton() {
    return Obx(
      () => KioskButton(
        label: 'Sign In',
        icon: Icons.login_rounded,
        expand: true,
        isLoading: controller.isSubmitting.value,
        isEnabled: !controller.isSubmitting.value,
        onPressed: controller.submit,
      ),
    );
  }

  /// Small help text listing the seeded demo credentials so the demo is
  /// usable out of the box.
  Widget _buildDemoHint(ThemeData theme) {
    final TextStyle? base = theme.textTheme.bodySmall?.copyWith(
      color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.70),
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.40),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Demo credentials',
            style: base?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text('Palos — admin@palos.org / palos123', style: base),
          Text('An-Noor — admin@annoor.org / annoor123', style: base),
        ],
      ),
    );
  }
}
