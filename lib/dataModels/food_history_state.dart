import '../models/food_item.dart';

class FoodHistoryState {
  final List<FoodItem> items;
  final bool isLoading;
  final String? error;

  const FoodHistoryState({
    required this.items,
    required this.isLoading,
    required this.error,
  });

  const FoodHistoryState.initial()
      : items = const [],
        isLoading = false,
        error = null;

  FoodHistoryState copyWith({
    List<FoodItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return FoodHistoryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

