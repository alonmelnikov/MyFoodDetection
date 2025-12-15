import 'dart:io';

import 'package:flutter/material.dart';

/// Generic list item widget with flexible detail fields
class GenericListItem extends StatelessWidget {
  const GenericListItem({
    super.key,
    required this.title,
    this.subtitle,
    this.imagePath,
    this.details = const [],
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final String? imagePath;
  final List<DetailItem> details;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final imageFile = imagePath != null ? File(imagePath!) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Image/Icon
                  if (imagePath != null)
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color:
                            Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: imageFile != null
                          ? FutureBuilder<bool>(
                              future: imageFile.exists(),
                              builder: (context, snapshot) {
                                if (snapshot.data == true) {
                                  return Image.file(
                                    imageFile,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return Icon(
                                  Icons.fastfood_outlined,
                                  color: Theme.of(context).colorScheme.outline,
                                );
                              },
                            )
                          : Icon(
                              Icons.fastfood_outlined,
                              color: Theme.of(context).colorScheme.outline,
                            ),
                    ),
                  if (imagePath != null) const SizedBox(width: 12),

                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),

                        // Subtitle
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],

                        // Details
                        if (details.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: details
                                .map((detail) => _DetailChip(detail: detail))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Model for detail items
class DetailItem {
  final String label;
  final String value;
  final Color? color;

  const DetailItem({required this.label, required this.value, this.color});
}

/// Internal widget for detail chips
class _DetailChip extends StatelessWidget {
  const _DetailChip({required this.detail});

  final DetailItem detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color:
            detail.color?.withValues(alpha: 0.15) ??
            Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${detail.label}: ${detail.value}',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: detail.color ?? Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
