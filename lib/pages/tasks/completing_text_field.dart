import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';

class CompletingTextFormField extends StatefulWidget {
  const CompletingTextFormField({
    Key? key,
    required this.controller,
    required this.suggestionsCallback,
    required this.labelText,
    required this.itemBuilder,
    this.validator,
  }) : super(key: key);

  final TextEditingController controller;
  final FutureOr<List<String>> Function() suggestionsCallback;
  final String labelText;
  final Widget Function(BuildContext, String) itemBuilder;
  final String? Function(String?)? validator;

  @override
  State<CompletingTextFormField> createState() =>
      CompletingTextFormFieldState();
}

class CompletingTextFormFieldState extends State<CompletingTextFormField>
    with AfterLayoutMixin {
  final suggestionsController = SuggestionsBoxController();

  // There seems to be a bug in the flutter_typeahead library,
  // where [SuggestionBoxController.isOpened()] errors because some member
  // variable has not been initialized yet. Calling it after the first
  // layout fixes it.
  bool isFirstLayout = true;

  final typeFocusNode = FocusNode();

  // FIXME: This sould actually keep the box open and update the entries,
  //  but it no workie
  void updateSuggestions() {
    setState(() => suggestionsController.toggle());
  }

  @override
  void initState() {
    super.initState();
    typeFocusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    typeFocusNode.dispose();
    super.dispose();
  }

  @override
  void afterFirstLayout(BuildContext context) =>
      setState(() => isFirstLayout = false);

  @override
  Widget build(BuildContext context) {
    return TypeAheadFormField(
      validator: widget.validator,
      textFieldConfiguration: TextFieldConfiguration(
        decoration: InputDecoration(
          alignLabelWithHint: true,
          labelText: widget.labelText,
          suffixIcon: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              widget.controller.text.isNotEmpty
                  ? IconButton(
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.close),
                      onPressed: () =>
                          setState(() => widget.controller.text = ''),
                    )
                  : const SizedBox(),
              IconButton(
                icon: AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isFirstLayout
                      ? 0
                      : suggestionsController.isOpened()
                          ? 0.504
                          : 0,
                  child: const Icon(Icons.arrow_drop_down),
                ),
                onPressed: () => setState(() => suggestionsController.toggle()),
              ),
            ],
          ),
        ),
        controller: widget.controller,
        focusNode: typeFocusNode,
      ),
      suggestionsCallback: (pattern) async {
        final suggestions = await widget.suggestionsCallback();
        if (pattern.isEmpty) return suggestions;

        // Fuzzy(?) insertion search
        // Checks that all characters from the pattern are in
        // the string in the order they appear in the pattern
        List<String> result = [];

        for (final suggestion in suggestions) {
          int patternIndex = 0;
          for (final char in suggestion.toLowerCase().characters) {
            if (char != pattern[patternIndex]) continue;
            patternIndex++;
            if (patternIndex >= pattern.length) break;
          }

          if (patternIndex >= pattern.length) {
            result.add(suggestion);
          }
        }

        return result;
      },
      suggestionsBoxController: suggestionsController,
      hideOnEmpty: true,
      hideOnError: true,
      itemBuilder: widget.itemBuilder,
      onSuggestionSelected: (suggestion) =>
          setState(() => widget.controller.text = suggestion as String? ?? ''),
    );
  }
}
