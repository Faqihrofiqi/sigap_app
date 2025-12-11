import 'package:flutter/material.dart';

/// Search bar widget yang reusable untuk list screens
class SearchBarWidget extends StatefulWidget {
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final TextEditingController? controller;
  final List<Widget>? actions;
  
  const SearchBarWidget({
    super.key,
    this.hintText = 'Cari...',
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.controller,
    this.actions,
  });
  
  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _controller;
  bool _hasText = false;
  
  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _hasText = _controller.text.isNotEmpty;
    _controller.addListener(_onTextChanged);
  }
  
  @override
  void dispose() {
    if (widget.controller == null) {
      _controller.dispose();
    } else {
      _controller.removeListener(_onTextChanged);
    }
    super.dispose();
  }
  
  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });
    widget.onChanged?.call(_controller.text);
  }
  
  void _clearText() {
    _controller.clear();
    widget.onClear?.call();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? Colors.grey[900]
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          setState(() {
            _hasText = value.isNotEmpty;
          });
          widget.onChanged?.call(value);
        },
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: widget.hintText,
          prefixIcon: Icon(
            Icons.search,
            color: theme.colorScheme.primary,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _clearText,
                  color: Colors.grey[600],
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }
}

/// Filter chip widget untuk filter options
class FilterChipWidget extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  
  const FilterChipWidget({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16),
            const SizedBox(width: 4),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primary.withOpacity(0.2),
      checkmarkColor: theme.colorScheme.primary,
      labelStyle: TextStyle(
        color: selected ? theme.colorScheme.primary : Colors.grey[700],
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: selected ? theme.colorScheme.primary : Colors.grey[300]!,
        width: selected ? 1.5 : 1,
      ),
    );
  }
}

/// Filter bar untuk menampilkan multiple filter options
class FilterBar extends StatelessWidget {
  final List<FilterOption> options;
  final ValueChanged<String>? onFilterChanged;
  
  const FilterBar({
    super.key,
    required this.options,
    this.onFilterChanged,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = options[index];
          return FilterChipWidget(
            label: option.label,
            selected: option.selected,
            icon: option.icon,
            onTap: () {
              option.onTap();
              onFilterChanged?.call(option.value);
            },
          );
        },
      ),
    );
  }
}

/// Model untuk filter option
class FilterOption {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  
  FilterOption({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
    this.icon,
  });
}

