import 'package:flutter_test/flutter_test.dart';
import 'package:seiue_mac/subject_models.dart';
import 'package:seiue_mac/todos.dart';

void main() {
  GradeReport report(String score, String maximum) => GradeReport(
    score: score, fullScore: maximum, status: 'published', entries: [GradeEntry(id: 'one', name: 'Test', score: score, fullScore: maximum)],
  );

  test('score rates handle zero, missing, textual and bonus scores', () {
    expect(report('81', '90').currentScoreRateText, '90.00%');
    expect(report('0', '100').currentScoreRateText, '0.00%');
    expect(report('105', '100').currentScoreRateText, '105.00%');
    for (final pair in [('—', '100'), ('A', '100'), ('1', '0'),
        ('1', '-10'), ('NaN', '100'), ('1', 'Infinity')]) {
      expect(report(pair.$1, pair.$2).currentScoreRate, isNull);
    }
  });

  test('current maximum excludes ungraded items and scales nested weights', () {
    final report = GradeReport.fromJson({
      'full_score': 100,
      'grade': {'student_real_score': 19.7},
      'items': [
        {'id': 'category', 'pid': 'root', 'full_score': 30},
        {'id': 'graded', 'pid': 'category', 'full_score': 70},
        {'id': 'future', 'pid': 'category', 'full_score': 30},
        {'id': 'later', 'pid': 'root', 'full_score': 70},
      ],
    }, [{'item_id': 'graded', 'score': 65.6667}]);
    expect(report.currentMaximumScore, 21);
    expect(report.currentScoreRateText, '93.81%');
    expect(const GradeReport(score: '0', fullScore: '100', status: '', entries: []).currentScoreRate, isNull);
    expect(GradeReport.fromJson({'items': [{'id': 'zero', 'full_score': 10}]}, [{'item_id': 'zero', 'score': 0}]).currentMaximumScore, 10);
  });

  test('deadline buckets include their boundaries without gaps', () {
    final now = DateTime(2026, 11, 4, 10);
    expect(deadlineBucket(now.subtract(const Duration(days: 1)), now), 5);
    expect(deadlineBucket(now.subtract(const Duration(microseconds: 1)), now), 5);
    expect(deadlineBucket(now, now), 0);
    expect(deadlineBucket(now.add(const Duration(hours: 6)), now), 0);
    expect(deadlineBucket(now.add(const Duration(hours: 6, seconds: 1)), now), 1);
    expect(deadlineBucket(DateTime(2026, 11, 4, 23, 59), now), 1);
    expect(deadlineBucket(DateTime(2026, 11, 5), now), 2);
    expect(deadlineBucket(now.add(const Duration(days: 3)), now), 2);
    expect(deadlineBucket(now.add(const Duration(days: 3, seconds: 1)), now), 3);
    expect(deadlineBucket(null, now), 4);
  });

  test('six hours takes priority across midnight', () {
    final now = DateTime(2026, 11, 4, 23);
    expect(deadlineBucket(DateTime(2026, 11, 5, 4), now), 0);
    expect(deadlineBucket(DateTime(2026, 11, 5, 6), now), 2);
  });

  test('only completed task statuses are excluded', () {
    for (final status in ['done', 'finished', 'achieved', 'submitted']) {
      expect(SubjectTask(id: '1', title: 'Task', status: status).isCompleted, isTrue);
    }
    expect(const SubjectTask(id: '2', title: 'Pending', status: 'read').isCompleted, isFalse);
  });
}
