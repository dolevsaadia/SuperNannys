import 'dart:async';
import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../constants/israeli_cities.dart';
import '../theme/app_colors.dart';

/// A text field with autocomplete dropdown for cities.
/// Uses Google Places Autocomplete API via backend proxy, with fallback to
/// the static Israeli cities list.
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
  List<_CityResult> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _fetchSuggestions(_controller.text);
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _onTextChanged(String value) {
    _debounce?.cancel();
    if (value.trim().length < 2) {
      setState(() => _suggestions = []);
      _overlayEntry?.markNeedsBuild();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(value.trim());
    });
    if (_overlayEntry == null && _focusNode.hasFocus) _showOverlay();
  }

  Future<void> _fetchSuggestions(String input) async {
    if (input.length < 2) return;

    setState(() => _isLoading = true);
    _overlayEntry?.markNeedsBuild();

    try {
      final resp = await apiClient.dio.get('/places/autocomplete', queryParameters: {
        'input': input,
        'types': '(cities)',
      });
      final data = resp.data['data'] as List<dynamic>? ?? [];

      if (data.isNotEmpty) {
        _suggestions = data.map((e) {
          final map = e as Map<String, dynamic>;
          return _CityResult(
            name: map['mainText'] as String? ?? map['description'] as String? ?? '',
            secondary: map['secondaryText'] as String? ?? '',
          );
        }).toList();
      } else {
        // Fallback to local list
        _suggestions = IsraeliCities.search(input).take(8).map((c) => _CityResult(name: c, secondary: 'Israel')).toList();
      }
    } catch (_) {
      // Fallback to local list
      _suggestions = IsraeliCities.search(input).take(8).map((c) => _CityResult(name: c, secondary: 'Israel')).toList();
    }

    _isLoading = false;
    if (mounted) {
      setState(() {});
      _overlayEntry?.markNeedsBuild();
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
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (_suggestions.isEmpty) {
      if (_controller.text.trim().length < 2) return const SizedBox.shrink();
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
              _controller.text = city.name;
              widget.onCitySelected(city.name);
              _hideOverlay();
              _focusNode.unfocus();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 18, color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(city.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        if (city.secondary.isNotEmpty)
                          Text(city.secondary, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                      ],
                    ),
                  ),
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
    _debounce?.cancel();
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
        onChanged: _onTextChanged,
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

class _CityResult {
  final String name;
  final String secondary;
  const _CityResult({required this.name, this.secondary = ''});
}
