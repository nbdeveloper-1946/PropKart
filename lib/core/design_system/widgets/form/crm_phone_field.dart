import 'package:flutter/material.dart';
import '../../tokens/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../../tokens/app_typography.dart';
import '../../../utils/validators.dart';

class CRMPhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool isRequired;
  final bool enabled;

  const CRMPhoneField({
    super.key,
    required this.controller,
    required this.labelText,
    this.hintText = 'e.g. 98765 43210',
    this.validator,
    this.isRequired = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${labelText}${isRequired ? " *" : ""}',
          style: CRMTypography.bodyMedium.copyWith(color: CRMColors.textSecondaryOf(context)),
        ),
        const SizedBox(height: CRMSpacing.xs),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: TextInputType.phone,
          style: CRMTypography.body.copyWith(
            color: enabled ? CRMColors.textOf(context) : CRMColors.textMutedOf(context),
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: CRMTypography.body.copyWith(color: CRMColors.textMutedOf(context)),
            prefixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(width: CRMSpacing.m),
                Text(
                  '+91',
                  style: CRMTypography.body.copyWith(
                    color: CRMColors.textOf(context),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: CRMSpacing.s),
                Container(
                  width: 1,
                  height: 16,
                  color: CRMColors.borderOf(context).withOpacity(0.5),
                ),
                const SizedBox(width: CRMSpacing.s),
              ],
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: CRMSpacing.m,
              vertical: CRMSpacing.s,
            ),
            filled: true,
            fillColor: enabled ? CRMColors.cardBgOf(context) : CRMColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.borderOf(context), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(CRMBorderRadius.s),
              borderSide: BorderSide(color: CRMColors.primaryOf(context), width: 1.5),
            ),
          ),
          validator: (v) {
            if (isRequired) {
              if (v == null || v.trim().isEmpty) {
                return '$labelText is required';
              }
              return CRMValidators.indianMobile(v);
            }
            return validator?.call(v);
          },
        ),
      ],
    );
  }
}
