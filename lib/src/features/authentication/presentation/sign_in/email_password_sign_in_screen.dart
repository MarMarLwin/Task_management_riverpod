import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:task_management/src/common_widgets/custom_text_button.dart';
import 'package:task_management/src/common_widgets/primary_button.dart';
import 'package:task_management/src/common_widgets/responsive_scrollable_card.dart';
import 'package:task_management/src/constant/app_sizes.dart';
import 'package:task_management/src/features/authentication/presentation/sign_in/email_password_sign_in_controller.dart';
import 'package:task_management/src/features/authentication/presentation/sign_in/email_password_sign_in_form_type.dart';
import 'package:task_management/src/features/authentication/presentation/sign_in/email_password_sign_in_validators.dart';
import 'package:task_management/src/features/authentication/presentation/sign_in/string_validators.dart';
import 'package:task_management/src/routing/app_router.dart';
import 'package:task_management/src/utils/async_value_ui.dart';

/// Email & password sign in screen.
/// Wraps the [EmailPasswordSignInContents] widget below with a [Scaffold] and
/// [AppBar] with a title.
class EmailPasswordSignInScreen extends StatelessWidget {
  const EmailPasswordSignInScreen(
      {super.key, required this.formType, this.onSignedIn});
  final EmailPasswordSignInFormType formType;
  final VoidCallback? onSignedIn;

  // * Keys for testing using find.byKey()
  static const emailKey = Key('email');
  static const passwordKey = Key('password');

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: EmailPasswordSignInContents(
          formType: formType,
        ),
      ),
    );
  }
}

/// A widget for email & password authentication, supporting the following:
/// - sign in
/// - register (create an account)
class EmailPasswordSignInContents extends ConsumerStatefulWidget {
  const EmailPasswordSignInContents({
    super.key,
    this.onSignedIn,
    required this.formType,
  });
  final VoidCallback? onSignedIn;

  /// The default form type to use.
  final EmailPasswordSignInFormType formType;
  @override
  ConsumerState<EmailPasswordSignInContents> createState() =>
      _EmailPasswordSignInContentsState();
}

class _EmailPasswordSignInContentsState
    extends ConsumerState<EmailPasswordSignInContents>
    with EmailAndPasswordValidators {
  final _formKey = GlobalKey<FormState>();
  final _node = FocusScopeNode();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String get email => _emailController.text;
  String get password => _passwordController.text;

  var _submitted = false;
  // track the formType as a local state variable
  late var _formType = widget.formType;

  @override
  void dispose() {
    // * TextEditingControllers should be always disposed
    _node.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitted = true);
    // only submit the form if validation passes
    if (_formKey.currentState!.validate()) {
      final controller =
          ref.read(emailPasswordSignInControllerProvider.notifier);
      final success = await controller.submit(
        email: email,
        password: password,
        formType: _formType,
      );
      if (success) {
        // widget.onSignedIn?.call();
        context.replaceNamed(AppRoute.home.name);
      }
    }
  }

  void _emailEditingComplete() {
    if (canSubmitEmail(email)) {
      _node.nextFocus();
    }
  }

  void _passwordEditingComplete() {
    if (!canSubmitEmail(email)) {
      _node.previousFocus();
      return;
    }
    _submit();
  }

  void _updateFormType() {
    // * Toggle between register and sign in form
    setState(() => _formType = _formType.secondaryActionFormType);
    // * Clear the password field when doing so
    _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue>(
      emailPasswordSignInControllerProvider,
      (_, state) => state.showAlertDialogOnError(context),
    );
    final state = ref.watch(emailPasswordSignInControllerProvider);
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Center(
        child: ResponsiveScrollableCard(
          child: FocusScope(
            node: _node,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  SizedBox(
                      height: 150,
                      width: 150,
                      child: CircleAvatar(
                          radius: 75,
                          backgroundColor: Colors.white,
                          child: Image.asset(
                            'assets/images/task.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ))),
                  gapH8,
                  // Email field
                  TextFormField(
                    key: EmailPasswordSignInScreen.emailKey,
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      hintText: 'test@test.com',
                      enabled: !state.isLoading,
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (email) =>
                        !_submitted ? null : emailErrorText(email ?? ''),
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    keyboardAppearance: Brightness.light,
                    onEditingComplete: () => _emailEditingComplete(),
                    inputFormatters: <TextInputFormatter>[
                      ValidatorInputFormatter(
                          editingValidator: EmailEditingRegexValidator()),
                    ],
                  ),
                  gapH8,
                  // Password field
                  TextFormField(
                    key: EmailPasswordSignInScreen.passwordKey,
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: _formType.passwordLabelText,
                      enabled: !state.isLoading,
                    ),
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    validator: (password) => !_submitted
                        ? null
                        : passwordErrorText(password ?? '', _formType),
                    obscureText: true,
                    autocorrect: false,
                    textInputAction: TextInputAction.done,
                    keyboardAppearance: Brightness.light,
                    onEditingComplete: () => _passwordEditingComplete(),
                  ),
                  gapH8,
                  PrimaryButton(
                    text: _formType.primaryButtonText,
                    isLoading: state.isLoading,
                    onPressed: state.isLoading ? null : () => _submit(),
                  ),
                  gapH8,
                  CustomTextButton(
                    text: _formType.secondaryButtonText,
                    onPressed: state.isLoading ? null : _updateFormType,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
