import 'package:flutter/material.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/icon_mapper.dart';

class SelectableIconList extends StatefulWidget {
  final List<Map<String, dynamic>> options;
  final void Function(int index)? onSelect;
  final VoidCallback? onTap;
  final VoidCallback? onRefresh;
  final int? selectedIndex;

  const SelectableIconList({
    super.key,
    required this.options,
    this.onSelect,
    this.onTap,
    this.onRefresh,
    this.selectedIndex,
  });

  @override
  State<SelectableIconList> createState() => _SelectableIconListState();
}

class _SelectableIconListState extends State<SelectableIconList> {
  late List<Map<String, dynamic>> options;
  int? selectedIndex;

  @override
  void initState() {
    super.initState();
    options = widget.options;
    selectedIndex = widget.selectedIndex;
  }

  @override
  Widget build(BuildContext context) {
    return options.isNotEmpty
        ? ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              bool isSelected = selectedIndex == index;

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColorScheme.primaryLight,
                  foregroundColor: AppColorScheme.primaryColor,
                  child: Icon(
                    getIconFromName(
                      options[index]['icon'] ?? options[index]['code'],
                    ),
                    size: 18,
                  ),
                ),
                title: Text(options[index]['label'] ?? options[index]['name']),
                trailing: isSelected
                    ? Icon(Icons.circle, color: AppColorScheme.primaryColor)
                    : null,
                onTap: () {
                  setState(() {
                    selectedIndex = index;
                  });

                  if (options[index]['onTap'] != null) {
                    (options[index]['onTap'] as VoidCallback)();
                  }

                  if (widget.onTap != null) {
                    widget.onTap!();
                  }
                  if (widget.onSelect != null) {
                    widget.onSelect!(index);
                  }
                },
              );
            },
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Items found',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                if (widget.onRefresh != null) ...[
                  const SizedBox(height: 4),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColorScheme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: widget.onRefresh,
                    child: Text('Refresh'),
                  ),
                ],
              ],
            ),
          );
  }
}
