import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config/app_constants.dart';
import '../../widgets/widgets.dart';
import 'login_controller.dart';
import 'login_validator.dart';

/// The administrator login screen (Requirement 1).
///
/// A landscape-friendly, centered login card with organization/app branding,
/// email and password fields wired to the [LoginController]'s per-field error
/// observables, and a submit button whose loading/disabled state is driven by
/// [LoginController.isSubmitting] (Requirements 1.1, 1.6, 1.7). A small demo
/// credentials hint keeps the seeded Palos/An-Noor demo usable. All transient
/// messaging is handled by the controller via the `NotificationService`.
class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final ScrollController _scrollController = ScrollController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final GlobalKey _emailFieldKey = GlobalKey();
  final GlobalKey _passwordFieldKey = GlobalKey();

  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();

  LoginController get controller => Get.find<LoginController>();

  @override
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_handleEmailFocus);
    _passwordFocusNode.addListener(_handlePasswordFocus);
  }

  @override
  void dispose() {
    _emailFocusNode.removeListener(_handleEmailFocus);
    _passwordFocusNode.removeListener(_handlePasswordFocus);
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleEmailFocus() {
    if (_emailFocusNode.hasFocus) {
      _ensureFieldVisible(_emailFieldKey);
    }
  }

  void _handlePasswordFocus() {
    if (_passwordFocusNode.hasFocus) {
      _ensureFieldVisible(_passwordFieldKey);
    }
  }

  void _ensureFieldVisible(GlobalKey fieldKey) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (!mounted) {
          return;
        }

        final BuildContext? fieldContext = fieldKey.currentContext;
        if (fieldContext == null || !fieldContext.mounted) {
          return;
        }

        Scrollable.ensureVisible(
          fieldContext,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          alignment: 0.35,
          alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.only(bottom: keyboardInset),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final double minHeight = constraints.maxHeight > 48
                  ? constraints.maxHeight - 48
                  : 0;

              return SingleChildScrollView(
                controller: _scrollController,
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: minHeight),
                  child: Align(
                    alignment: isKeyboardOpen
                        ? Alignment.topCenter
                        : Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: SectionCard(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Form(
                            key: _formKey,
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
            },
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
    return KeyedSubtree(
      key: _emailFieldKey,
      child: Obx(
        () => KioskTextField(
          label: 'Email',
          controller: controller.emailController,
          focusNode: _emailFocusNode,
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !controller.isSubmitting.value,
          onChanged: controller.onEmailChanged,
          validator: (String? value) =>
              LoginValidator.validateEmail((value ?? '').trim()),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          onSubmitted: (_) => _passwordFocusNode.requestFocus(),
        ),
      ),
    );
  }

  /// Obscured password field with inline error bound to
  /// [LoginController.passwordError]; submitting from the keyboard triggers
  /// [LoginController.submit].
  Widget _buildPasswordField() {
    return KeyedSubtree(
      key: _passwordFieldKey,
      child: Obx(
        () => KioskTextField(
          label: 'Password',
          controller: controller.passwordController,
          focusNode: _passwordFocusNode,
          prefixIcon: Icons.lock_outline,
          obscureText: controller.isPasswordObscured.value,
          textInputAction: TextInputAction.done,
          enabled: !controller.isSubmitting.value,
          onChanged: controller.onPasswordChanged,
          validator: (String? value) =>
              LoginValidator.validatePassword(value ?? ''),
          autovalidateMode: AutovalidateMode.onUserInteraction,
          suffixIcon: IconButton(
            tooltip: controller.isPasswordObscured.value
                ? 'Show password'
                : 'Hide password',
            onPressed: controller.isSubmitting.value
                ? null
                : controller.togglePasswordVisibility,
            icon: Icon(
              controller.isPasswordObscured.value
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
            ),
          ),
          onSubmitted: (_) => _submit(),
        ),
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
        onPressed: _submit,
      ),
    );
  }

  void _submit() {
    final FormState? form = _formKey.currentState;
    if (form == null) {
      controller.submit();
      return;
    }
    final bool ok = form.validate();
    if (!ok) {
      return;
    }
    controller.submit();
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
