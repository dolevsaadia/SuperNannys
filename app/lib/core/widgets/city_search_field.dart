import 'package:flutter/material.dart';
import '../constants/israeli_cities.dart';
import '../theme/app_colors.dart';

/// A text field with autocomplete dropdown for Israeli cities.
class CitySearchField extends StatefulWidget {
  final String? initialValue;
  final String hint;
  final ValueChanged<String> onCitySelected;
  final TextEditingController? controller;

  const CitySearchField({
    super.key,
    this.initialValue,
    this.hint = 'Search city...',
    required this.onCitySelected,
    this.controller,
  });

  @override
  State<CitySearchField> createState() => _CitySearchFieldState();
}

class _CitySearchFieldState extends State<CitySearchField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions(_controller.text);
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _updateSuggestions(String query) {
    setState(() {
      _suggestions = IsraeliCities.search(query).take(8).toList();
    });
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _showOverlay() {
    _hideOverlay();
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: renderBox.size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, renderBox.size.height + 4),
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: _buildSuggestionsList(),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _hideOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Widget _buildSuggestionsList() {
    if (_suggestions.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('No cities found', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      );
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 250),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _suggestions.length,
        itemBuilder: (_, i) {
          final city = _suggestions[i];
          return InkWell(
            onTap: () {
              _controller.text = city;
              widget.onCitySelected(city);
              _hideOverlay();
              _focusNode.unfocus();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Text(city, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _hideOverlay();
    _focusNode.removeListener(_onFocusChanged);
    _focusNode.dispose();
    if (widget.controller == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: (value) {
          _updateSuggestions(value);
          if (_overlayEntry == null && _focusNode.hasFocus) _showOverlay();
        },
        onSubmitted: (value) {
          widget.onCitySelected(value);
          _hideOverlay();
        },
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
          isDense: true,
        ),
      ),
    );
  }
}
