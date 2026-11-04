import 'package:flutter_test/flutter_test.dart';
import 'package:seiue_mac/api.dart';
import 'package:seiue_mac/controller.dart';
import 'package:seiue_mac/models.dart';
import 'package:seiue_mac/subject_models.dart';

class SemesterApi extends SeiueApi {
  final calls = <String>[];
  @override
  Future<List<CampusSubject>> subjects() async => const [
    CampusSubject(id: 'math', groupId: 'current-math', name: 'Math'),
  ];
  @override
  Future<SubjectPage<SubjectTask>> subjectTasks(CampusSubject subject, {int page = 1}) async {
    calls.add('${subject.groupId}:$page');
    return SubjectPage([
      SubjectTask(id: '$page', title: 'Current task'),
      const SubjectTask(id: 'done', title: 'Finished', status: 'submitted'),
    ], page == 1);
  }
}

void main() {
  testWidgets('todos only query current semester courses and fetch every page', (tester) async {
    final api = SemesterApi();
    final c = CampusController(api: api);
    c.session = CampusSession(token: 'test', identity: const Identity(
      id: 'one', name: 'Student', schoolId: '3', role: 'student'),
      expiresAt: DateTime.now().add(const Duration(days: 1)));
    c.todos = [const SubjectTask(id: 'old', title: 'Old semester')];
    await c.loadTodos();
    expect(api.calls, ['current-math:1', 'current-math:2']);
    expect(c.todos.map((t) => t.id), ['1', '2']);
    c.dispose();
  });
}
