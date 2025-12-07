import 'package:flutter/material.dart';

/// Generic list widget with loading and empty states
class GenericList<T> extends StatelessWidget {
  const GenericList({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.isLoading = false,
    this.emptyMessage = 'No items yet',
    this.emptyIcon = Icons.inbox_outlined,
    this.padding = const EdgeInsets.all(16),
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final bool isLoading;
  final String emptyMessage;
  final IconData emptyIcon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              emptyIcon,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: padding,
      itemCount: items.length,
      itemBuilder: (context, index) {
        return itemBuilder(context, items[index], index);
      },
    );
  }
}

