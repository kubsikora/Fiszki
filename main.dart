import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await openDatabase(
    join(await getDatabasesPath(), 'f1.db'),
    onCreate: (db, version) async {
      try {
        await db.execute(
          'CREATE TABLE fiszki(id INTEGER PRIMARY KEY, setId INTEGER, name TEXT, question TEXT, answer TEXT)',
        );
        await db.execute(
          'CREATE TABLE sets(id INTEGER PRIMARY KEY, name TEXT, color TEXT, textColor TEXT)',
        );
      } catch (e) {
        print('Blad podczas tworzenia tabel: $e');
      }
    },
    version: 1,
  );

  runApp(MyApp(database: database));
}

class Fiszki {
  final int id;
  final int setId;
  final String name;
  final String question;
  final String answer;

  Fiszki({
    required this.id,
    required this.setId,
    required this.name,
    required this.question,
    required this.answer,
  });

  factory Fiszki.fromMap(Map<String, dynamic> map) {
    return Fiszki(
      id: map['id'],
      setId: map['setId'],
      name: map['name'],
      question: map['question'],
      answer: map['answer'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'setId': setId,
      'name': name,
      'question': question,
      'answer': answer,
    };
  }

  @override
  String toString() {
    return 'Fiszki{id: $id, setId: $setId, name: $name, question: $question, answer: $answer}';
  }
}

class Set {
  final int id;
  final String name;
  final String color;
  final String textColor;

  Set({
    required this.id,
    required this.name,
    required this.color,
    required this.textColor,
  });

  factory Set.fromMap(Map<String, dynamic> map) {
    return Set(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      textColor: map['textColor'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'textColor': textColor,
    };
  }

  @override
  String toString() {
    return 'Set{id: $id, name: $name, color: $color, textColor: $textColor}';
  }
}
//klasa kolorów
class AppColors {
  static const Color background = Color(0xFFFAF1E6);
  static const Color button = Color(0xFFE4EFE7);
  static const Color text = Color(0xFF064420);
  static const Color inny = Color(0xFFFDFAF6);
  static const Color bialy = Color(0xFFFFFFFF);
  static const Color czarny = Color(0x00000000);
}


//główna klasa z widokiem listy zestawów
class MyApp extends StatefulWidget {
  final Database database;

  const MyApp({Key? key, required this.database}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late List<Set> sets = [];

  @override
  void initState() {
    super.initState();
    _loadSetsFromDatabase();
  }

  Future<void> _loadSetsFromDatabase() async {
    final List<Set> loadedSets = await _loadSets();
    setState(() {
      sets = loadedSets;
    });
  }

  Future<List<Set>> _loadSets() async {
    final db = widget.database;
    final List<Map<String, dynamic>> setMaps = await db.query('sets');
    List<Set> loadedSets = [];
    for (var setMap in setMaps) {
      if (setMap['id'] != 0) {
        loadedSets.add(Set(
          id: setMap['id'],
          name: setMap['name'],
          color: setMap['color'],
          textColor: setMap['textColor'],
        ));
      }
    }
    return loadedSets;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.button,
      ),
      home: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AppBar(
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: Container(
              child: SizedBox(
                width: 150,
                height: 50,
                child: Image.asset(
                  'assets/logo.png',
                  fit: BoxFit.contain,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(15),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await _addNewSetToDatabase();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.text,
                    foregroundColor: AppColors.background,
                  ),
                  child: const Text('Create set'),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: sets.length,
                    itemBuilder: (context, index) {
                      return _buildSetWidget(context, sets[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSetWidget(BuildContext context, Set set) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EmptyClass(
              setId: set.id,
              database: widget.database, 
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(10),
        width: 200,
        height: 100,
        decoration: BoxDecoration(
          color: Color(int.tryParse(set.color) ?? 0xFF000000),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              set.name,
              style: TextStyle(
                color: Color(int.tryParse(set.textColor) ?? 0xFF000000),
                fontSize: 16,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => NoteSetScreen(
                      setId: set.id,
                      database: widget.database, 
                      refreshSets: _loadSetsFromDatabase,
                    ),
                  ),
                );
              },
              icon: Icon(Icons.edit, color: Color(int.tryParse(set.textColor) ?? 0xFF000000)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addNewSetToDatabase() async {
    final db = widget.database;
    final List<Map<String, dynamic>> setsCount = await db.rawQuery('SELECT COUNT(*) FROM sets');
    final int id = setsCount[0]['COUNT(*)'] + 1;
    final newSet = Set(
      id: id,
      name: 'New set',
      color: '0xFF064420',
      textColor: '0xFFFAF1E6',
    );
    await db.insert(
      'sets',
      newSet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _loadSetsFromDatabase();
  }
}

// klasa edycji zestawów - nazwa, kolory
class NoteSetScreen extends StatefulWidget {
  final int setId;
  final Database database;
  final Function refreshSets;


  NoteSetScreen({required this.setId, required this.database, required this.refreshSets});


  @override
  _NoteSetScreenState createState() => _NoteSetScreenState();
}

class _NoteSetScreenState extends State<NoteSetScreen> {
  late TextEditingController _nameController;
  late Color _selectedColor; 
  late Color _selectedTextColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = AppColors.text; 
    _selectedTextColor = AppColors.background;
    _nameController = TextEditingController(); 
    _loadSetDetails();

  }
  Future<void> _loadSetDetails() async {
    final db = widget.database;
    final List<Map<String, dynamic>> setMaps = await db.query(
      'sets',
      where: 'id = ?',
      whereArgs: [widget.setId],
    );

    if (setMaps.isNotEmpty) {
      final set = Set.fromMap(setMaps.first);
      setState(() {
        _nameController.text = set.name;
        _selectedColor = Color(int.parse(set.color));
        _selectedTextColor = Color(int.parse(set.textColor));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          flexibleSpace: Container(
            child: SizedBox(
              width: 150,
              height: 80,
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                color: AppColors.text,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController, 
                decoration: const InputDecoration(
                  labelText: 'Change name',
                  labelStyle: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text),
                  ),
                  errorBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text),
                  ),
                ),
                style: TextStyle(color: AppColors.text),
                cursorColor: AppColors.text,
              ),
              const SizedBox(height: 12.0),
              const Center(
                child: Text(
                  'Choose set color',
                  style: TextStyle(
                    fontSize: 19,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 5.0),
              Center(
                child: Container(
                  child: CircleColorPicker(
                    onChanged: (color) {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    size: const Size(200, 200),
                    strokeWidth: 4,
                    thumbSize: 36,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              const Center(
                child: Text(
                  'Choose text color',
                  style: TextStyle(
                    fontSize:19,
                    color: AppColors.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Center(
                child: Container(
                  child: CircleColorPicker(
                    onChanged: (textcolor) {
                      setState(() {
                        _selectedTextColor = textcolor;
                      });
                    },
                    size: const Size(200, 200),
                    strokeWidth: 4,
                    thumbSize: 36,
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    _saveChanges(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.text,
                    foregroundColor: AppColors.background,
                    minimumSize: const Size(150, 50), 
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(fontSize: 20), 
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveChanges(BuildContext context) async {
    final db = widget.database;
    final int setId = widget.setId;

    final String newName = _nameController.text;

    final String newColor = _selectedColor.value.toRadixString(16);
    final String newTextColor = _selectedTextColor.value.toRadixString(16);

    await db.update(
      'sets',
      {
        'name': newName,
        'color': '0x$newColor',
        'textColor': '0x$newTextColor',
      },
      where: 'id = ?',
      whereArgs: [setId],
    );
    widget.refreshSets();

    Navigator.pop(context);
  }


  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}

// klasa widoku konkretnego zestawu
class EmptyClass extends StatefulWidget {
  final int setId;
  final Database database;


  EmptyClass({required this.setId, required this.database});


  @override
  _EmptyClassState createState() => _EmptyClassState();
}

class _EmptyClassState extends State<EmptyClass> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          flexibleSpace: Container(
            child: SizedBox(
              width: 150,
              height: 80,
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                color: AppColors.text,
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddQuestionScreen(
                setId: widget.setId,
                database: widget.database, 
              ),
            ),
          );
        },
        backgroundColor: AppColors.text,
        child: const Icon(Icons.add, color: AppColors.background),
      ),
    );
  }
}

//klasa odpowiedzialna za dodawanie pytan i odpowiedzi 
class AddQuestionScreen extends StatefulWidget {
  final int setId;
  final Database database;


  AddQuestionScreen({required this.setId, required this.database});


  @override
  _AddQuestionScreenState createState() => _AddQuestionScreenState();
}
class _AddQuestionScreenState extends State<AddQuestionScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _answerController = TextEditingController();

  Future<void> _addFlashcard(BuildContext context) async {
    final db = widget.database;

    final List<Map<String, dynamic>> setMaps = await db.query(
      'sets',
      where: 'id = ?',
      whereArgs: [widget.setId],
    );
    final String setName = setMaps.first['name'];

    final List<Map<String, dynamic>> flashcardCount = await db.rawQuery('SELECT COUNT(*) FROM fiszki');
    final int newId = (Sqflite.firstIntValue(flashcardCount) ?? 0) + 1;

    await db.insert(
      'fiszki',
      {
        'id': newId,
        'setId': widget.setId,
        'name': setName,
        'question': _questionController.text,
        'answer': _answerController.text,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    _questionController.clear();
    _answerController.clear();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Center(child: Text('Added Q&A successfully'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        flexibleSpace: Container(
          child: SizedBox(
            width: 150,
            height: 80,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              color: AppColors.text,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              TextField(
                controller: _questionController,
                decoration: const InputDecoration(
                  labelText: 'Enter question',
                  labelStyle: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text),
                  ),
                ),
                style: const TextStyle(color: AppColors.text),
                cursorColor: AppColors.text,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _answerController,
                decoration: const InputDecoration(
                  labelText: 'Enter answer',
                  labelStyle: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text),
                  ),
                ),
                style: const TextStyle(color: AppColors.text),
                cursorColor: AppColors.text,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _addFlashcard(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.text,
                  foregroundColor: AppColors.background,
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    super.dispose();
  }
}
