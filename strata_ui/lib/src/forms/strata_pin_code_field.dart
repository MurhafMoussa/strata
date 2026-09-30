import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pinput/pinput.dart';
import 'package:typed_form_fields/typed_form_fields.dart';

class const StrataPinCodeField({
  super.key,
  required final String name,
  final int length = 6,
  final String? initialValue,
  final bool enabled = true,
  final bool readOnly = false,
  final bool obscureText = false,
  final String obscuringCharacter = '•',
  final Widget? obscuringWidget,
  final bool autofocus = false,
  final FocusNode? focusNode,
  final TextEditingController? controller,
  final ValueChanged<String>? onChanged,
  final ValueChanged<String>? onCompleted,
  final ValueChanged<String>? onSubmitted,
  final VoidCallback? onTap,
  final VoidCallback? onLongPress,
  final TapRegionCallback? onTapOutside,
  final ValueChanged<String>? onClipboardFound,
  final AppPrivateCommandCallback? onAppPrivateCommand,
  final PinTheme? pinTheme,
  final PinTheme? defaultPinTheme,
  final PinTheme? focusedPinTheme,
  final PinTheme? submittedPinTheme,
  final PinTheme? followingPinTheme,
  final PinTheme? disabledPinTheme,
  final PinTheme? errorPinTheme,
  final TextInputType keyboardType = TextInputType.number,
  final TextInputAction textInputAction = TextInputAction.done,
  final AutovalidateMode autovalidateMode = AutovalidateMode.onUserInteraction,
  final bool closeKeyboardWhenCompleted = true,
  final HapticFeedbackType hapticFeedbackType = HapticFeedbackType.disabled,
  final bool useNativeKeyboard = true,
  final bool toolbarEnabled = true,
  final bool enableSuggestions = true,
  final bool enableIMEPersonalizedLearning = false,
  final Iterable<String>? autofillHints,
  final SmsRetriever? smsRetriever,
  final TextCapitalization textCapitalization = TextCapitalization.none,
  final Curve animationCurve = Curves.easeIn,
  final Duration animationDuration = const Duration(milliseconds: 200),
  final PinAnimationType pinAnimationType = PinAnimationType.scale,
  final Offset? slideTransitionBeginOffset,
  final bool showCursor = true,
  final Widget? cursor,
  final bool isCursorAnimationEnabled = true,
  final Widget Function(int index)? separatorBuilder,
  final Widget? preFilledWidget,
  final MainAxisAlignment mainAxisAlignment = MainAxisAlignment.center,
  final CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  final AlignmentGeometry pinContentAlignment = Alignment.center,
  final EdgeInsets scrollPadding = const EdgeInsets.all(20),
  final Widget Function(BuildContext context, String? errorText)? errorBuilder,
  final TextStyle? errorTextStyle,
  final List<TextInputFormatter>? inputFormatters,
  final TextSelectionControls? selectionControls,
  final String? restorationId,
  final MouseCursor? mouseCursor,
  final Brightness? keyboardAppearance,
  final EditableTextContextMenuBuilder? contextMenuBuilder,
  final Duration? debounceTime,
  final String Function(String value)? transformValue,
}) extends StatefulWidget {
  @override
  State<StrataPinCodeField> createState() => _StrataPinCodeFieldState();
}

class _StrataPinCodeFieldState extends State<StrataPinCodeField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TypedFieldWrapper<String>(
      fieldName: widget.name,
      initialValue: widget.initialValue,
      debounceTime: widget.debounceTime,
      transformValue: widget.transformValue,
      builder: (context, field) {
        final value = field.value;
        final error = field.error;
        final hasError = field.hasError;

        if (_controller.text != (value ?? '')) {
          _controller.text = value ?? '';
        }

        final theme = Theme.of(context);

        final defaultPinTheme =
            widget.defaultPinTheme ??
            widget.pinTheme ??
            PinTheme(
              width: 56,
              height: 56,
              textStyle: theme.textTheme.titleLarge,
              decoration: BoxDecoration(
                border: Border.all(
                  color: theme.colorScheme.onSurface.withAlpha(80),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
            );

        return IgnorePointer(
          ignoring: widget.readOnly,
          child: Pinput(
            length: widget.length,
            controller: _controller,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: widget.readOnly,
            autofocus: widget.autofocus,
            obscureText: widget.obscureText,
            obscuringCharacter: widget.obscuringCharacter,
            obscuringWidget: widget.obscuringWidget,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            onChanged: (text) {
              widget.onChanged?.call(text);
              field.updateValue(text);
            },
            onCompleted: (pin) {
              widget.onCompleted?.call(pin);
            },
            onSubmitted: (value) {
              field.updateValue(value);
              widget.onSubmitted?.call(value);
            },
            onTap: widget.onTap,
            onLongPress: widget.onLongPress,
            onTapOutside: widget.onTapOutside,
            onClipboardFound: widget.onClipboardFound,
            onAppPrivateCommand: widget.onAppPrivateCommand,
            pinputAutovalidateMode: PinputAutovalidateMode.disabled,
            showCursor: widget.showCursor,
            cursor: widget.cursor,
            separatorBuilder: widget.separatorBuilder,
            forceErrorState: hasError,
            errorText: widget.errorBuilder == null ? error : null,
            errorTextStyle: widget.errorTextStyle,
            errorBuilder: widget.errorBuilder != null && hasError
                ? (error, _) => widget.errorBuilder!(context, error)
                : null,
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: widget.focusedPinTheme,
            submittedPinTheme: widget.submittedPinTheme,
            followingPinTheme: widget.followingPinTheme,
            disabledPinTheme: widget.disabledPinTheme,
            errorPinTheme: widget.errorPinTheme,
            preFilledWidget: widget.preFilledWidget,
            mainAxisAlignment: widget.mainAxisAlignment,
            crossAxisAlignment: widget.crossAxisAlignment,
            pinContentAlignment: widget.pinContentAlignment,
            animationCurve: widget.animationCurve,
            animationDuration: widget.animationDuration,
            pinAnimationType: widget.pinAnimationType,
            slideTransitionBeginOffset: widget.slideTransitionBeginOffset,
            useNativeKeyboard: widget.useNativeKeyboard,
            toolbarEnabled: widget.toolbarEnabled,
            isCursorAnimationEnabled: widget.isCursorAnimationEnabled,
            enableIMEPersonalizedLearning: widget.enableIMEPersonalizedLearning,
            enableSuggestions: widget.enableSuggestions,
            hapticFeedbackType: widget.hapticFeedbackType,
            closeKeyboardWhenCompleted: widget.closeKeyboardWhenCompleted,
            textCapitalization: widget.textCapitalization,
            keyboardAppearance: widget.keyboardAppearance,
            inputFormatters: widget.inputFormatters ?? [],
            autofillHints: widget.autofillHints,
            selectionControls: widget.selectionControls,
            restorationId: widget.restorationId,
            mouseCursor: widget.mouseCursor,
            scrollPadding: widget.scrollPadding,
            contextMenuBuilder: widget.contextMenuBuilder,
            smsRetriever: widget.smsRetriever,
          ),
        );
      },
    );
  }
}
