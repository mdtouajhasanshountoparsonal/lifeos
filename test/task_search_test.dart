import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:lifeos/models/expense.dart';
import 'package:lifeos/models/note.dart';
import 'package:lifeos/models/task.dart';
import 'package:lifeos/services/task_search.dart';

void main() {
  late Directory tmp;

  setUpAll(() {
    tmp = Directory.systemTemp.createTempSync('lifos_search_test');
    Hive.init(tmp.path);
    Hive.registerAdapter(TaskAdapter());
    Hive.registerAdapter(ExpenseAdapter());
    Hive.registerAdapter(NoteAdapter());
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
    try {
      tmp.deleteSync(recursive: true);
    } catch (_) {}
  });

  setUp(() async {
    await Hive.openBox<Task>('tasks');
    await Hive.openBox<Expense>('expenses');
    await Hive.openBox<Note>('notes');
  });

  tearDown(() async {
    await Hive.box<Task>('tasks').clear();
    await Hive.box<Expense>('expenses').clear();
    await Hive.box<Note>('notes').clear();
  });

  Task task(String id, String title,
      {int priority = 0, double? cost, String? category, DateTime? deadline}) {
    return Task(
      id: id,
      title: title,
      priority: priority,
      createdAt: DateTime(2026, 9, 1),
      deadline: deadline,
      category: category,
      expectedCost: cost,
    );
  }

  void seed() {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    Hive.box<Task>('tasks').addAll([
      task('t1', 'মাছ ৫ কেজি কিনবো',
          cost: 600, category: 'Shopping', deadline: now.add(const Duration(hours: 30))),
      task('t2', 'কলম কিনবো', cost: 100, category: 'Shopping', deadline: now),
      task('t3', 'জরুরি পরীক্ষার প্রস্তুতি',
          priority: 2, category: 'Study', deadline: tomorrow),
      task('t4', 'ঘর মুছবো', deadline: now),
    ]);
  }

  test('cost filter — ৫০০ টাকার বেশি শুধু বড়টা', () {
    seed();
    final hits = TaskSearchService.run('৫০০ টাকার বেশি',
        tasks: Hive.box<Task>('tasks'),
        exps: Hive.box<Expense>('expenses'),
        notes: Hive.box<Note>('notes'));
    final tasks = hits.where((h) => h.kind == 'task').toList();
    expect(tasks.map((h) => h.title), ['মাছ ৫ কেজি কিনবো']);
    expect(tasks.single.amount, 600);
  });

  test('জরুরি → priority 2 task', () {
    seed();
    final hits = TaskSearchService.run('জরুরি',
        tasks: Hive.box<Task>('tasks'),
        exps: Hive.box<Expense>('expenses'),
        notes: Hive.box<Note>('notes'));
    expect(hits.where((h) => h.kind == 'task').map((h) => h.title),
        contains('জরুরি পরীক্ষার প্রস্তুতি'));
  });

  test('text match item নাম — মাছ', () {
    final t = task('t5', 'বাজার করবো',
            cost: 900, category: 'Shopping')
      ..setItemList(const [
        TaskItem(name: 'মাছ', qty: 2, unit: 'kg'),
      ]);
    Hive.box<Task>('tasks').add(t);
    final hits = TaskSearchService.run('মাছ',
        tasks: Hive.box<Task>('tasks'),
        exps: Hive.box<Expense>('expenses'),
        notes: Hive.box<Note>('notes'));
    expect(hits.map((h) => h.title), contains('বাজার করবো'));
  });

  test('আজ → আজকের ডেডলাইন', () {
    seed();
    final hits = TaskSearchService.run('আজ',
        tasks: Hive.box<Task>('tasks'),
        exps: Hive.box<Expense>('expenses'),
        notes: Hive.box<Note>('notes'));
    final tasks = hits.where((h) => h.kind == 'task').toList();
    expect(tasks.map((h) => h.title), isNot(contains('মাছ ৫ কেজি কিনবো'))); // কাল-মানা।
    expect(tasks.map((h) => h.title), contains('কলম কিনবো'));
  });

  test('expense টাইটেল খোঁজে', () {
    Hive.box<Expense>('expenses').add(Expense(
      id: 'e1',
      title: 'আলু বাজার',
      amount: 250,
      category: 'food',
      date: DateTime.now(),
    ));
    final hits = TaskSearchService.run('আলু',
        tasks: Hive.box<Task>('tasks'),
        exps: Hive.box<Expense>('expenses'),
        notes: Hive.box<Note>('notes'));
    expect(hits.map((h) => h.kind), contains('expense'));
    expect(hits.map((h) => h.title), contains('আলু বাজার'));
  });

  test('note খোঁজে', () {
    Hive.box<Note>('notes').add(Note(
      id: 'n1',
      title: 'গণিত সূত্র',
      content: 'a^2 + b^2 = c^2',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
    final hits = TaskSearchService.run('গণিত',
        tasks: Hive.box<Task>('tasks'),
        exps: Hive.box<Expense>('expenses'),
        notes: Hive.box<Note>('notes'));
    expect(hits.map((h) => h.kind), contains('note'));
  });
}