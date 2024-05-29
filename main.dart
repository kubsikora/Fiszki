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

  Future<void> _deleteSetFromDatabase(Set set) async {
    final db = widget.database;
    // Usuń fiszki powiązane z zestawem
    await db.delete(
      'fiszki',
      where: 'setId = ?',
      whereArgs: [set.id],
    );
    // Usuń zestaw
    await db.delete(
      'sets',
      where: 'id = ?',
      whereArgs: [set.id],
    );
    // Odśwież listę zestawów
    _loadSetsFromDatabase();
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
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: AppColors.text,
          selectionColor: AppColors.inny,
          selectionHandleColor: AppColors.text,
        )
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
              database: widget.database, // Przekazanie instancji bazy danych
            ),
          ),
        );
      },
      child: Dismissible(
        key: Key(set.id.toString()),
        onDismissed: (direction) {
          if (direction == DismissDirection.endToStart) {
            _deleteSetFromDatabase(set);
          } else if (direction == DismissDirection.startToEnd) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => NoteSetScreen(
                  setId: set.id,
                  database: widget.database, // Przekazanie instancji bazy danych
                  refreshSets: _loadSetsFromDatabase,
                ),
              ),
            );
          }
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: EdgeInsets.only(right: 20.0),
          color: Colors.red,
          child: Icon(Icons.delete, color: Colors.white),
        ),
        secondaryBackground: Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.only(left: 20.0),
          color: Colors.red,
          child: Icon(Icons.delete, color: Colors.white),
        ),
        direction: DismissDirection.horizontal,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.all(10),
          width: 400,
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
              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => NoteSetScreen(
                            setId: set.id,
                            database: widget.database, // Przekazanie instancji bazy danych
                            refreshSets: _loadSetsFromDatabase,
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.edit, color: Color(int.tryParse(set.textColor) ?? 0xFF000000)),
                  ),
                  IconButton(
                    onPressed: () {
                      _deleteSetFromDatabase(set);
                    },
                    icon: Icon(Icons.delete, color: Color(int.tryParse(set.textColor) ?? 0xFF000000)),
                  ),
                ],
              ),
            ],
          ),
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
  late Color _selectedColor; // Domyślny kolor
  late Color _selectedTextColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = AppColors.text; // Ustaw domyślny kolor podczas inicjalizacji stanu
    _selectedTextColor = AppColors.background;
    _nameController = TextEditingController(); // Inicjalizacja kontrolera dla pola tekstowego
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
                controller: _nameController, // Przypisanie kontrolera do pola tekstowego
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
                style: const TextStyle(color: AppColors.text),
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
                    _saveChanges(context); // Wywołanie metody do zapisu zmian
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.text,
                    foregroundColor: AppColors.background,
                    minimumSize: const Size(150, 50), // Tutaj określamy minimalny rozmiar przycisku
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

    // Pobranie wartości z pola tekstowego
    final String newName = _nameController.text;

    // Konwersja kolorów na wartości tekstowe
    final String newColor = _selectedColor.value.toRadixString(16);
    final String newTextColor = _selectedTextColor.value.toRadixString(16);

    // Aktualizacja danych w bazie danych
    await db.update(
      'sets',
      {
        'name': newName,
        'color': '0x$newColor', // Formatowanie koloru do postaci '0xRRGGBB'
        'textColor': '0x$newTextColor', // Formatowanie koloru do postaci '0xRRGGBB'
      },
      where: 'id = ?',
      whereArgs: [setId],
    );
    // Ponowne załadowanie zestawów z bazy danych po zapisaniu zmian
    widget.refreshSets();

    // Powrót do poprzedniego widoku
    Navigator.pop(context);
  }


  @override
  void dispose() {
    // Usunięcie kontrolera po zakończeniu
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
  late List<Fiszki> fiszki = [];
  late List<Set> sets = [];

  @override
  void initState() {
    super.initState();
    _loadFlashcardsFromDatabase();
    _loadSetsFromDatabase();
  }

  Future<void> _loadFlashcardsFromDatabase() async {
    final List<Fiszki> loadedFlashcards = await _loadFlashcards();
    setState(() {
      fiszki = loadedFlashcards;
    });
  }

  Future<List<Fiszki>> _loadFlashcards() async {
    final db = widget.database;
    final List<Map<String, dynamic>> flashcardMaps = await db.query(
      'fiszki',
      where: 'setId = ?',
      whereArgs: [widget.setId],
    );
    List<Fiszki> loadedFlashcards = [];
    for (var flashcardMap in flashcardMaps) {
      loadedFlashcards.add(Fiszki.fromMap(flashcardMap));
    }
    return loadedFlashcards;
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
      loadedSets.add(Set.fromMap(setMap));
    }
    return loadedSets;
  }

  Set? _getSetById(int setId) {
    return sets.firstWhere((set) => set.id == setId);
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
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AddQuestionScreen(
                        setId: widget.setId,
                        database: widget.database,
                      ),
                    ),
                  ).then((_) {
                    _loadFlashcardsFromDatabase(); // Odświeżenie listy fiszek po powrocie z ekranu dodawania fiszki
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.text,
                  foregroundColor: AppColors.background,
                ),
                child: const Text('Edit Flashcard'),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: fiszki.length,
                  itemBuilder: (context, index) {
                    final set = _getSetById(widget.setId);
                    final setColor = set != null ? int.parse(set.color) : 0xFF000000;
                    final setTextColor = set != null ? int.parse(set.textColor) : 0xFFFFFFFF;
                    return FlashcardItem(
                      question: fiszki[index].question,
                      answer: fiszki[index].answer,
                      setColor: Color(setColor),
                      setTextColor: Color(setTextColor),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class FlashcardItem extends StatefulWidget {
  final String question;
  final String answer;
  final Color setColor;
  final Color setTextColor;

  FlashcardItem({
    required this.question,
    required this.answer,
    required this.setColor,
    required this.setTextColor,
  });

  @override
  _FlashcardItemState createState() => _FlashcardItemState();
}

class _FlashcardItemState extends State<FlashcardItem> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showAnswer = !_showAnswer;
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.setColor,
          borderRadius: BorderRadius.circular(15),
        ),
        constraints: const BoxConstraints(
          minHeight: 100, // Ustaw minimalną wysokość
          minWidth: 200,  // Ustaw minimalną szerokość
        ),
        child: IntrinsicHeight(
          child: Column(
            children: [
              Flexible(
                child: Center(
                  child: Text(
                    _showAnswer ? widget.answer : widget.question,
                    style: TextStyle(
                      color: widget.setTextColor,
                      fontSize: 17,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
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
  String? _errorMessage;
  List<Fiszki> flashcards = [];
  Color? textColor;
  Color? containerColor;

  @override
  void initState() {
    super.initState();
    _loadFlashcardsFromDatabase();
  }

  Future<void> _loadFlashcardsFromDatabase() async {
    final List<Fiszki> loadedFlashcards = await _loadFlashcards();
    setState(() {
      flashcards = loadedFlashcards;
    });
  }

  Future<List<Fiszki>> _loadFlashcards() async {
    final db = widget.database;
    final List<Map<String, dynamic>> flashcardMaps = await db.query(
      'fiszki',
      where: 'setId = ?',
      whereArgs: [widget.setId],
    );
    List<Fiszki> loadedFlashcards = [];
    for (var flashcardMap in flashcardMaps) {
      loadedFlashcards.add(Fiszki.fromMap(flashcardMap));
    }

    // Pobierz kolor tekstu i kolor kontenera z tabeli sets
    final List<Map<String, dynamic>> setMaps = await db.query(
      'sets',
      where: 'id = ?',
      whereArgs: [widget.setId],
    );
    final String textColorString = setMaps.first['textColor'];
    final String containerColorString = setMaps.first['color'];
    textColor = Color(int.parse(textColorString));
    containerColor = Color(int.parse(containerColorString));

    return loadedFlashcards;
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
              // Dodawanie nowego pytania i odpowiedzi
              TextField(
                controller: _questionController,
                decoration: InputDecoration(
                  labelText: 'Enter question',
                  labelStyle: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text), // Kolor paska gdy nie jest aktywne
                  ),
                  errorText: _errorMessage != null && _questionController.text.trim().isEmpty ? _errorMessage : null,
                ),
                style: const TextStyle(color: AppColors.text),
                cursorColor: AppColors.text,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _answerController,
                decoration: InputDecoration(
                  labelText: 'Enter answer',
                  labelStyle: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                  focusedBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text),
                  ),
                  enabledBorder: const UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text), // Kolor paska gdy nie jest aktywne
                  ),
                  errorText: _errorMessage != null && _answerController.text.trim().isEmpty ? _errorMessage : null,
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
                child: const Text('Add Flashcard'),
              ),
              const SizedBox(height: 5),
              // Lista z wyświetlanymi pytaniami i odpowiedziami
              Expanded(
                child: ListView.builder(
                  itemCount: flashcards.length,
                  itemBuilder: (context, index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.5),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Question:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            flashcards[index].question,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Answer:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            flashcards[index].answer,
                            style: TextStyle(
                              fontSize: 14,
                              color: textColor,
                            ),
                          ),
                          SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                onPressed: () => _editFlashcard(context, flashcards[index]),
                                icon: Icon(Icons.edit, color: textColor),
                              ),
                              IconButton(
                                onPressed: () => _deleteFlashcard(context, flashcards[index]),
                                icon: Icon(Icons.delete, color: textColor),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _deleteFlashcard(BuildContext context, Fiszki flashcard) async {
    final db = widget.database;
    
    // Usunięcie fiszki z bazy danych
    await db.delete(
      'fiszki',
      where: 'id = ?',
      whereArgs: [flashcard.id],
    );

    // Odśwież listę fiszek
    _loadFlashcardsFromDatabase();
  }


  void _editFlashcard(BuildContext context, Fiszki flashcard) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          
          backgroundColor: AppColors.background,
          title: const Text(
            'Edit Flashcard',
            style: TextStyle(color: AppColors.text),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: TextEditingController(text: flashcard.question),
                cursorColor: AppColors.text,
                cursorErrorColor: AppColors.text,
                decoration: const InputDecoration(
                  labelText: 'Edit question',
                  fillColor: AppColors.text,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text), // Kolor paska w stanie domyślnym
                  ),
                  labelStyle: TextStyle(color: AppColors.text),
                ),
                
                
              ),
              TextField(
                controller: TextEditingController(text: flashcard.answer),
                cursorColor: AppColors.text,
                cursorErrorColor: AppColors.text,
                decoration: const InputDecoration(
                  labelText: 'Edit answer',
                  fillColor: AppColors.text,
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text),
                  ),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: AppColors.text), // Kolor paska w stanie domyślnym
                  ),
                  labelStyle: TextStyle(color: AppColors.text),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.text,
                foregroundColor: AppColors.background,
              ),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _updateFlashcard(context, flashcard.id);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.text,
                foregroundColor: AppColors.background,
              ),
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateFlashcard(BuildContext context, int flashcardId) async {
    final String newQuestion = _questionController.text.trim();
    final String newAnswer = _answerController.text.trim();
    final db = widget.database;

    await db.update(
      'fiszki',
      {
        'question': newQuestion,
        'answer': newAnswer,
      },
      where: 'id = ?',
      whereArgs: [flashcardId],
    );

    Navigator.pop(context);

    _loadFlashcardsFromDatabase();
  }


  // Metoda do dodawania nowej fiszki
  Future<void> _addFlashcard(BuildContext context) async {
    final db = widget.database;
    final String question = _questionController.text.trim();
    final String answer = _answerController.text.trim();

    // Sprawdź, czy pytanie i odpowiedź nie są puste
    if (question.isEmpty || answer.isEmpty) {
      setState(() {
        _errorMessage = 'Question and answer cannot be empty';
      });
      return;
    }

    // Pobierz nazwę zestawu z bazy danych
    final List<Map<String, dynamic>> setMaps = await db.query(
      'sets',
      where: 'id = ?',
      whereArgs: [widget.setId],
    );
    final String setName = setMaps.first['name'];

    // Policzenie obecnych fiszek w tabeli
    final List<Map<String, dynamic>> flashcardCount = await db.rawQuery('SELECT COUNT(*) FROM fiszki');
    final int newId = (Sqflite.firstIntValue(flashcardCount) ?? 0) + 1;

    // Dodanie nowej fiszki do bazy danych
    await db.insert(
      'fiszki',
      {
        'id': newId,
        'setId': widget.setId,
        'name': setName,
        'question': question,
        'answer': answer,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );

    // Wyczyść pola tekstowe i komunikat błędu
    _questionController.clear();
    _answerController.clear();
    setState(() {
      _errorMessage = null;
    });

    // Odśwież listę fiszek
    _loadFlashcardsFromDatabase();
  }
}
