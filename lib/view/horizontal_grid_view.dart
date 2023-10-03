import 'package:flutter/cupertino.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

class HorizontalReorderableGridview<T> extends StatelessWidget {
  final List<T> items;
  final Function(int oldIndex, int newIndex) onReorder;
  final int cellPerColumn;
  final double cellSpacing;
  final double childAspectRatio;
  final Function(int index) onDragStart;
  final int itemCount;
  final Widget Function(T item) itemBuilder;

  const HorizontalReorderableGridview(
      {super.key,
      required this.items,
      required this.onReorder,
      this.cellPerColumn = 2,
      this.cellSpacing = 0,
      this.childAspectRatio = 1,
      required this.onDragStart,
      required this.itemCount,
      required this.itemBuilder});

  List<T> _mapper(List<T> list, int columnNumber, int rowNumber) {
    return List.generate(list.length, (index) {
      final newIndex = index ~/ rowNumber + (index % rowNumber) * columnNumber;
      return list[newIndex];
    });
  }

  @override
  Widget build(BuildContext context) {
    final numberColumn =
        itemCount ~/ cellPerColumn + (itemCount % cellPerColumn == 0 ? 0 : 1);
    final mapperItems = _mapper(items, numberColumn, cellPerColumn);
    return Transform.flip(
      flipY: true,
      child: RotatedBox(
        quarterTurns: -1,
        child: ReorderableGridView.builder(
          controller: ScrollController(),
          padding: const EdgeInsets.symmetric(vertical: 15),
          onReorder: onReorder,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cellPerColumn,
            crossAxisSpacing: cellSpacing,
            mainAxisSpacing: cellSpacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            final item = mapperItems[index];
            return Transform.flip(
              flipX: true,
              key: ValueKey(item),
              child: RotatedBox(
                quarterTurns: 1,
                child: itemBuilder(item),
              ),
            );
          },
          onDragStart: onDragStart,
          itemCount: itemCount,
        ),
      ),
    );
  }
}
