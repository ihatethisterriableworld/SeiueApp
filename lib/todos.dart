import 'package:flutter/material.dart';

import 'controller.dart';
import 'models.dart';
import 'rich_document.dart';
import 'subject_models.dart';
import 'theme.dart';

const deadlineLabels = ['6小时以内', '6小时到当天', '当天至3天', '3天后', '无截止时间'];

/// Six hours takes priority across midnight; the third bucket ends 72 hours
/// from now. Local midnight supplies the end-of-today boundary.
int deadlineBucket(DateTime? due, DateTime now) {
  if (due == null) return 4;
  if (!due.isAfter(now.add(const Duration(hours: 6)))) return 0;
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  if (due.isBefore(tomorrow)) return 1;
  if (!due.isAfter(now.add(const Duration(days: 3)))) return 2;
  return 3;
}

class TodosPanel extends StatelessWidget {
  const TodosPanel({super.key, required this.controller});
  final CampusController controller;

  @override
  Widget build(BuildContext context) {
    final c = controller, p = CampusPalette.of(context), now = DateTime.now();
    final groups = List.generate(5, (_) => <SubjectTask>[]);
    for (final task in c.todos.where((t) => !t.isCompleted)) {
      groups[deadlineBucket(task.due, now)].add(task);
    }
    for (final group in groups) {
      group.sort((a, b) => a.due == null ? a.title.compareTo(b.title)
          : a.due!.compareTo(b.due!));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text('待办事项', style: Theme.of(context).textTheme.titleMedium)),
          IconButton(tooltip: '刷新待办', onPressed: c.todosLoading ? null : c.loadTodos,
              icon: const Icon(Icons.refresh, size: 18)),
        ]),
        if (c.todosLoading) const LinearProgressIndicator(minHeight: 2),
        if (c.todosError != null) ...[
          Text(c.todosError!, style: TextStyle(color: p.muted)),
          TextButton(onPressed: c.loadTodos, child: const Text('重试')),
        ],
        for (var index = 0; index < groups.length; index++)
          if (index < 4 || groups[index].isNotEmpty) ...[
            const SizedBox(height: 12),
            Text('${deadlineLabels[index]} · ${groups[index].length}',
                style: TextStyle(color: index == 0 ? Colors.red : p.primary,
                    fontSize: 12, fontWeight: FontWeight.w600)),
            if (groups[index].isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text('暂无待办', style: TextStyle(color: p.muted, fontSize: 12))),
            for (final task in groups[index])
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                title: Text(task.title, style: const TextStyle(fontSize: 12)),
                subtitle: Text(task.due == null ? '无截止时间'
                    : '${task.due!.isBefore(now) ? '已逾期 · ' : ''}${dayKey(task.due!)} ${clockTime(task.due!)}',
                    style: TextStyle(fontSize: 11,
                        color: task.due?.isBefore(now) == true ? Colors.red : p.muted)),
                onTap: () => showDialog<void>(context: context, builder: (context) => AlertDialog(
                  title: Text(task.title),
                  content: SizedBox(width: 520, child: SingleChildScrollView(
                      child: RichDocument(content: task.content, mac: c.mac))),
                  actions: [
                    if (task.url?.isNotEmpty == true)
                      TextButton(onPressed: () => c.mac.openUrl(task.url!), child: const Text('打开任务资料')),
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('关闭')),
                  ],
                )),
              ),
          ],
      ],
    );
  }
}
