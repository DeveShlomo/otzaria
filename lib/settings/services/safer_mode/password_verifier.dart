import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:otzaria/settings/engine/settings_engine_exports.dart';
import 'package:otzaria/ui/settings/services/safer_mode/password_verification_dialog.dart';

/// פונקציה עוזרת לבדיקה האם צריך הגנה
bool shouldProtectSettings(BuildContext context) {
  final state = context.read<SettingsBloc>().state;
  final repository = context.read<SettingsRepository>();
  return state.protectedModeEnabled && repository.hasProtectedModePassword();
}

/// פונקציה עוזרת לאימות סיסמה
Future<bool> verifyPasswordForAction(BuildContext context) async {
  if (!shouldProtectSettings(context)) {
    return true;
  }

  final repository = context.read<SettingsRepository>();

  final verified = await showDialog<bool>(
    context: context,
    builder: (context) => PasswordVerificationDialog(
      title: 'אמת סיסמה',
      hint: 'הנך במצב מוגן.\nהזן את הסיסמה כדי לבצע פעולה זו',
      onVerify: (password) async {
        return repository.verifyProtectedModePassword(password);
      },
    ),
  );

  return verified == true;
}
