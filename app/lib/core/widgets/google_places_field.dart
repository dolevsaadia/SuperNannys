import 'dart:async';
import 'package:flutter/material.dart';
import '../network/api_client.dart';
import '../theme/app_colors.dart';
import '../constants/israeli_cities.dart';

/// A suggestion returned from the Places autocomplete API.
class PlaceSuggestion {
  final String description;
  final String mainText;
  final String secondaryText;
  final String placeId;

  const PlaceSuggestion({
    required this.description,
    required this.mainText,
    required this.secondaryText,
    required this.placeId,
  });

  factory PlaceSuggestion.fromJson(Map<String, dynamic> json) => PlaceSuggestion(
        description: json['description'] as String? ?? '',
        mainText: json['mainText'] as String? ?? '',
        secondaryText: json['secondaryText'] as String? ?? '',
        placeId: json['placeId'] as String? ?? '',
      );
}

/// A text field with Google Places autocomplete.
/// Falls back to the static Israeli cities list if the API is unavailable.
class GooglePlacesField extends StatefulWidget {
  final String? initialValue;
  final String label;
  final String hint;
  final ValueChanged<String> onPlaceSelected;
  final TextEditingController? controller;
  final String? types;
  final Icon? prefixIcon;

  const GooglePlacesField({
    super.key,
    this.initialValue,
    this.label = '',
    this.hint = 'Search city...',
    required this.onPlaceSelected,
    this.controller,
    this.types = '(cities)',
    this.prefixIcon,
  });

  @override
  State<GooglePlacesField> createState() => _GooglePlacesFieldState();
}

class _GooglePlacesFieldState extends State<GooglePlacesField> {
  late final TextEditingController _controller;
  final _focusNode = FocusNode();
  final _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  List<PlaceSuggestion> _suggestions = [];
  Timer? _debounce;
  bool _isLoading = false;
  bool _apiFailed = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController(text: widget.initialValue);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      if (_controller.text.isNotEmpty) {
        _fetchSuggestions(_controller.text);
      }
      _showOverlay();
    } else {
      _hideOverlay();
    }
  }

  void _onTextChanged(String query) {
    _debounce?.cancel();
    if (query.trim().length < 2) {
      setState(() => _suggestions = []);
      _overlayEntry?.markNeedsBuild();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _fetchSuggestions(query.trim());
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
        if (widget.types != null) 'types': widget.types,
      });
      final data = resp.data['data'] as List<dynamic>? ?? [];

      if (data.isNotEmpty) {
        _apiFailed = false;
        _suggestions = data.map((e) => PlaceSuggestion.fromJson(e as Map<String, dynamic>)).toList();
      } else {
        // Fall back to local cities list if API returns empty
        _suggestions = IsraeliCities.search(input).take(8).map((city) => PlaceSuggestion(
              description: city,
              mainText: city,
              secondaryText: 'Israel',
              placeId: '',
            )).toList();
      }
    } catch (_) {
      _apiFailed = true;
      // Fall back to local cities list on any error
      _suggestions = IsraeliCities.search(input).take(8).map((city) => PlaceSuggestion(
            description: city,
            mainText: city,
            secondaryText: 'Israel',
            placeId: '',
          )).toList();
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
            elevation: 6,
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            shadowColor: Colors.black26,
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
        padding: EdgeInsets.all(16),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (_suggestions.isEmpty) {
      if (_controller.text.trim().length < 2) return const SizedBox.shrink();
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Text('No results found', style: TextStyle(color: AppColors.textHint, fontSize: 13)),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 260),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 6),
        itemCount: _suggestions.length,
        separatorBuilder: (_, __) => Divider(height: 1, indent: 44, color: AppColors.divider.withValues(alpha: 0.5)),
        itemBuilder: (_, i) {
          final s = _suggestions[i];
          return InkWell(
            borderRadius: i == 0
                ? const BorderRadius.vertical(top: Radius.circular(14))
                : i == _suggestions.length - 1
                    ? const BorderRadius.vertical(bottom: Radius.circular(14))
                    : BorderRadius.zero,
            onTap: () {
              _controller.text = s.mainText;
              widget.onPlaceSelected(s.mainText);
              _hideOverlay();
              _focusNode.unfocus();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
              child: Row(
                children: [
                  Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.location_on_rounded, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.mainText, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        if (s.secondaryText.isNotEmpty)
                          Text(s.secondaryText, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Text(widget.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 6),
        ],
        CompositedTransformTarget(
          link: _layerLink,
          child: TextField(
            controller: _controller,
            focusNode: _focusNode,
            onChanged: _onTextChanged,
            onSubmitted: (value) {
              widget.onPlaceSelected(value);
              _hideOverlay();
            },
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 14),
              prefixIcon: widget.prefixIcon ?? const Icon(Icons.location_on_outlined, color: AppColors.textHint, size: 20),
              filled: true,
              fillColor: AppColors.bg,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
