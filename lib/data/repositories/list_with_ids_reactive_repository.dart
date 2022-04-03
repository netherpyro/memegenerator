import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:memogenerator/data/repositories/list_reactive_repository.dart';

abstract class ListWithIdsReactiveRepository<T> extends ListReactiveRepository<T> {
  @protected
  dynamic getId(final T item);

  Future<bool> addItemOrReplaceById(final T newItem) async {
    final items = await getItems();
    final itemIndex = items.indexWhere((e) => getId(e) == getId(newItem));
    if (itemIndex == -1) {
      items.add(newItem);
    } else {
      items[itemIndex] = newItem;
    }
    return setItems(items);
  }

  Future<bool> removeFromItemsById(final dynamic id) async {
    final items = await getItems();
    items.removeWhere((e) => getId(e) == id);
    return setItems(items);
  }

  Future<T?> getItemById(final dynamic id) async {
    final items = await getItems();
    return items.firstWhereOrNull((e) => getId(e) == id);
  }
}
