import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:seiue_mac/controller.dart';
import 'package:seiue_mac/main.dart';
import 'package:seiue_mac/subject_models.dart';

// Include the empty personal/attendance rows visible in the reported bug,
// both at the root and inside a weighted group.
GradeReport mixedReport() => GradeReport.fromJson({
  'full_score': 100,
  'grade': {'student_real_score': 19.7},
  'items': [
    {'id': 'personal', 'name': '个性化评价'},
    {'id': 'attendance', 'name': '课程考勤（Attendance）'},
    {'id': 'category', 'pid': 'root', 'full_score': 30, 'type': 'dimension'},
    {'id': 'weekly', 'pid': 'category', 'full_score': 30, 'type': 'dimension'},
    {'id': 'empty', 'pid': 'weekly'},
    {'id': 'graded', 'pid': 'weekly', 'full_score': 70},
    {'id': 'future', 'pid': 'weekly', 'full_score': 30},
    {'id': 'later', 'pid': 'root', 'full_score': 70},
  ],
}, [{'item_id': 'graded', 'score': 65.6667}]);

void main() {
  test('empty informational rows do not erase the graded maximum', () {
    final report = mixedReport();
    expect(report.currentMaximumScore, 21);
    expect(report.currentScoreRateText, '93.81%');
  });

  test('missing maximum for an actual numeric grade remains unknown', () {
    final report = GradeReport.fromJson({
      'grade': {'score': 5},
      'items': [
        {'id': 'known', 'full_score': 10},
        {'id': 'unknown'},
      ],
    }, [
      {'item_id': 'known', 'score': 5},
      {'item_id': 'unknown', 'score': 2},
    ]);
    expect(report.currentScoreRate, isNull);
  });

  testWidgets('grade page shows percentage alongside blank assessment rows', (tester) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = CampusController()..booting = false;
    c.enterDemo();
    await tester.pumpWidget(SeiueApp(controller: c));
    c.selectSubject(c.subjects.first);
    await tester.pumpAndSettle();
    c.subjectSection.data = mixedReport();
    c.navigate(Destination.subjects);
    await tester.pumpAndSettle();
    expect(find.text('93.81%'), findsOneWidget);
    expect(find.text('当前可得满分 21'), findsOneWidget);
    expect(find.text('个性化评价'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });

  testWidgets('sidebar keeps schedule first and overdue tasks last', (tester) async {
    tester.view.physicalSize = const Size(1600, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final c = CampusController()..booting = false;
    c.enterDemo();
    final now = DateTime.now();
    c.todos = [
      SubjectTask(id: 'late', title: '逾期作业', due: now.subtract(const Duration(days: 1))),
      SubjectTask(id: 'soon', title: '即将截止', due: now.add(const Duration(hours: 1))),
      const SubjectTask(id: 'unscheduled', title: '没有DDL'),
    ];
    await tester.pumpWidget(SeiueApp(controller: c));
    await tester.pumpAndSettle();
    final labels = [
      '今天的安排', '待办事项', '6小时以内 · 1', '6小时到当天 · 0',
      '当天后到3天 · 0', '3天后 · 0', '无截止时间 · 1', '已逾期 · 1',
    ];
    var previous = double.negativeInfinity;
    for (final label in labels) {
      final finder = find.text(label);
      expect(finder, findsOneWidget);
      final y = tester.getTopLeft(finder).dy;
      expect(y, greaterThan(previous));
      previous = y;
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    c.dispose();
  });
}
