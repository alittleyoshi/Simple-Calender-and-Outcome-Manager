import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:path/path.dart';

DynamicLibrary _lib = Platform.isLinux ?
  DynamicLibrary.open('database.so') :
  DynamicLibrary.open('database.dll');

final initDatabaseC = _lib
    .lookupFunction<Int32 Function(), int Function()>
  ('Dart_init');

final queryTaskListNum = _lib
    .lookupFunction<Int32 Function(), int Function()>
  ('Dart_query_tasklist_num');

final queryTaskNum = _lib
    .lookupFunction<Int32 Function(Int32 listId), int Function(int listID)>
  ('Dart_query_task_num');

final getTaskC = _lib
    .lookupFunction<TaskC Function(Int32 listId, Int32 taskId), TaskC Function(int listId, int taskId)>
  ('Dart_get_task');

final addTaskC = _lib
    .lookupFunction<Int32 Function(Int32, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Int32), int Function(int, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, Pointer<Utf8>, int)>
  ('Dart_create_task');

final testDll = _lib
    .lookupFunction<Int32 Function(), int Function()>
  ('Dart_test');

final test1 = _lib
    .lookupFunction<Int32 Function(), int Function()>
  ('Dart_test_f1');

final test2 = _lib
    .lookupFunction<Void Function(), void Function()>
  ('Dart_test_f2');

final test3 = _lib
    .lookupFunction<Int32 Function(Int32 val), int Function(int val)>
  ('Dart_test_f3');

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: "SCOM",
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
        ),
        home: MyHomePage(),
      ),
    );
  }
}

class MyAppState extends ChangeNotifier {
  var todoList = <TodoList>[];
  var initialized = false;

  void init() {
    // print("${test1()}");
    // test2();
    // print("${test3(2)}");
    if (!initialized) {
      initDatabaseC();
      // print("${queryTaskNum(0)}");
      var listNum = queryTaskListNum();
      print("listNum: $listNum");
      // print("${queryTaskNum(100)}");
      for (var i = 0; i < listNum; i++) {
        var list = TodoList();
        list.id = i;
        var taskNum = queryTaskNum(i);
        // print("1");
        print("List$i, taskNum: $taskNum");
        for (var j = 0; j < taskNum; j++) {
          var taskC = getTaskC(i, j);
          print(1);
          var task = changeTaskCtoTask(taskC);
          print(2);
          list.taskList.add(task);
          print(3);
        }
        todoList.add(list);
      }
      // print("${test1()}");
      // test2();
      // print("${test3(3)}");
      // initDatabaseC();
      initialized = true;
      // notifyListeners();
    }
  }

  void addTask(int listIndex, String title, String description, DateTime startTime, DateTime endTime, int status) {
    var newTask = Task(listIndex, 0, title, description, startTime, endTime, status);
    var newTaskId = addTaskC(listIndex, newTask.title.toNativeUtf8(), newTask.description.toNativeUtf8(), newTask.startTime.toIso8601String().toNativeUtf8(), newTask.endTime.toIso8601String().toNativeUtf8(), newTask.stat);
    print("$newTaskId");
    newTask.id = newTaskId;
    todoList[listIndex].taskList.add(newTask);
    notifyListeners();
  }

  void changeStatus() {
    notifyListeners();
  }
}

class MyHomePage extends StatefulWidget {
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    Widget page;

    switch (selectedIndex) {
      case 0:
        page = TodoPage();
        break;
      case 1:
        page = CalendarPage();
        break;
      case 2:
        page = SettingPage();
        break;
      default :
        throw UnimplementedError('no widget for $selectedIndex');
    }

    // var calendarState = context.watch<CalendarState>();

    IconData calendarIcon = Icons.calendar_month;
    // switch (calendarState.calendarIconIndex) {
    //   case 0:
    //     calendarIcon = Icons.calendar_view_day;
    //     break;
    //   case 1:
    //     calendarIcon = Icons.calendar_view_week;
    //     break;
    //   case 2:
    //     calendarIcon = Icons.calendar_view_month;
    //     break;
    //   default:
    //     throw UnimplementedError('no icon for ${calendarState.calendarIconIndex}');
    // }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row (
          children: [
            SafeArea(
              child:
                NavigationRail(
                  extended: constraints.maxWidth >= 800,
                  destinations: [
                    NavigationRailDestination(
                      icon: Icon(Icons.checklist),
                      label: Text('SCOM'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(calendarIcon),
                      label: Text('Calendar'),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings),
                      label: Text('Settings'),
                    ),
                  ],
                  selectedIndex: selectedIndex,
                  onDestinationSelected: (value){
                    setState(() {
                      selectedIndex = value;
                    });
                  },
                ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child : page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class TodoPage extends StatefulWidget {
  @override
  State<TodoPage> createState() => _TodoPageState();
}

final class TaskC extends Struct {
  @Int32()
  external int listId, id;

  external Pointer<Utf8> title, description, startTime, endTime;

  @Int32()
  external int status;
}

class Task {
  var listId = 0;
  var id = 0;
  var title = 'Task 1';
  var description = 'Task description.';
  var startTime = DateTime.now();
  var endTime = DateTime.now();
  var stat = 0;

  Task(this.listId, this.id, this.title, this.description, this.startTime, this.endTime, this.stat);
}

Task changeTaskCtoTask(TaskC task) {
  return Task(task.listId, 0, task.title.toDartString(), task.description.toDartString(), DateTime.parse(task.startTime.toDartString()), DateTime.parse(task.endTime.toDartString()), task.status);
}

// TaskC changeTaskCtoTask(Task task) {
//   return TaskC(task.title.toNativeUtf8(), task.description.toNativeUtf8(), task.startTime.toIso8601String().toNativeUtf8(), task.endTime.toIso8601String().toNativeUtf8(), task.stat);
// }

int getTodoListNum() {
  return 0;
}

int getTask(int listId) {
  return 0;
}

class TodoList {
  var id = 0;
  var taskList = <Task>[];
}

class _TodoPageState extends State<TodoPage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    appState.init();

    Widget page;

    // print("${appState.todoList}");

    var destination = appState.todoList.map((list) => NavigationRailDestination(
        icon: Icon(Icons.star),
        label: Text("Todo List ${list.id + 1}"),
    )).toList();

    // print("$destination");

    page = GeneratorTodoPage(listIndex: selectedIndex);

    // var destination = todoList[selectedIndex].taskList.map((task) => )

    return Scaffold(
      body: Row(
        children: [
          SafeArea(
            child:
            NavigationRail(
              backgroundColor: Color.lerp(Colors.white, Theme.of(context).colorScheme.primaryContainer, 0.5),
              extended: true,
              destinations: destination,
              selectedIndex: selectedIndex,
              onDestinationSelected: (value){
                setState(() {
                  selectedIndex = value;
                });
              },
            ),
          ),
          Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child : page,
            ),
          ),
        ],
      ),
    );
  }
}

class GeneratorTodoPage extends StatefulWidget {
  const GeneratorTodoPage({
    super.key,
    required this.listIndex,
  });

  final int listIndex;

  @override
  State<GeneratorTodoPage> createState() => _GeneratorTodoPageState();
}

class _GeneratorTodoPageState extends State<GeneratorTodoPage> {
  @override build(BuildContext context) {
    // widget.list.taskList.add(Task(1, 'eltiT', 'Todo2', DateTime.now(), DateTime.now(), 1));
    var appState = context.watch<MyAppState>();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          setState(() {
            appState.addTask(0, 'eltiT', 'Todo2', DateTime.now(), DateTime.now(), 1);
          });
        },
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 5),
            Container(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Row(
                children: [
                  SizedBox(width: 10),
                  Icon(Icons.star),
                  SizedBox(width: 10),
                  Text("Todo List ${widget.listIndex + 1}"),
                ],
              ),
            ),
            SizedBox(height: 5),
            Expanded(
              child: Container(
                color: Colors.white,
                child: Row(
                  children: [
                    SizedBox(width: 15),
                    Expanded(
                      child: ListView(
                        children: appState.todoList[widget.listIndex].taskList.map((task) => Container(
                          color: task.stat != 2 ? Theme.of(context).colorScheme.primaryContainer : Colors.deepOrange[300],
                          margin: EdgeInsets.all(10.0),
                          child: Row(
                            children: [
                              SizedBox(width: 10),
                              ElevatedButton.icon(
                                onPressed: (){
                                  setState((){
                                    task.stat = task.stat == 1 ? 0 : 1;
                                  });
                                },
                                icon: Icon(task.stat == 1 ? Icons.task_alt : Icons.circle),
                                label: SizedBox(),
                              ),
                              SizedBox(width: 10),
                              Text('Task ${task.title}'),
                            ],
                          ),
                        )).toList(),
                      ),
                    ),
                    SizedBox(width: 15),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class CalendarPage extends StatefulWidget {
  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  var selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    var appState = context.watch<MyAppState>();
    appState.init();

    // var calendarState = context.watch<CalendarState>();

    Widget page;

    switch (selectedIndex) {
      case 0:
        page = GeneratorHourPage();
        break;
      case 1:
        page = GeneratorWeekPage();
        break;
      case 2:
        page = GeneratorMonthPage();
        break;
      default:
        throw UnimplementedError("No implemented for ${selectedIndex}");
    }

    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                backgroundColor: Color.lerp(Colors.white, Theme.of(context).colorScheme.primaryContainer, 0.5),
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_view_day),
                    label: Text('Hours'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_view_week),
                    label: Text('Week'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.calendar_view_month),
                    label: Text('Month'),
                  ),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value){
                  setState((){
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Colors.white,
                child: page,
              ),
            ),
          ],
        ),
      );
    });

  }
}

class GeneratorHourPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var begin_time = DateTime.now().add(Duration(hours: -1));
    var end_time = begin_time.add(Duration(hours: 12));



    return Row(
      children: [
        SizedBox(width: 20),
        Expanded(
          child: Column(
            children: [
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Text(begin_time.toString()),
              ),
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(begin_time.add(Duration(hours: 1)).toString()),
              ),
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Text(begin_time.add(Duration(hours: 2)).toString()),
              ),
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(begin_time.add(Duration(hours: 3)).toString()),
              ),
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Text(begin_time.add(Duration(hours: 4)).toString()),
              ),
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(begin_time.add(Duration(hours: 5)).toString()),
              ),
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Text(begin_time.add(Duration(hours: 6)).toString()),
              ),
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(begin_time.add(Duration(hours: 7)).toString()),
              ),
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Text(begin_time.add(Duration(hours: 8)).toString()),
              ),
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(begin_time.add(Duration(hours: 9)).toString()),
              ),
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Text(begin_time.add(Duration(hours: 10)).toString()),
              ),
              Container(
                alignment: Alignment.center,
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: Text(begin_time.add(Duration(hours: 11)).toString()),
              ),
            ],
          ),
        ),
        SizedBox(width: 20),
      ],
    );
  }
}

class CalendarHourPageContainer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            alignment: Alignment.center,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: SizedBox(height: 30, width: 100),
          ),
          Container(
            alignment: Alignment.center,
            color: Theme.of(context).colorScheme.tertiaryContainer,
            child: Text(""),
          ),
        ],
      ),
    );
  }
}

class GeneratorWeekPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class GeneratorMonthPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

// Failed assertion: line 115 pos 16: 'destinations.length >= 2': is not true.
// must have at least 2 destinations