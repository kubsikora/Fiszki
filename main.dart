import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_circle_color_picker/flutter_circle_color_picker.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final database = await openDatabase(
    join(await getDatabasesPath(), 'f.db'),
    onCreate: (db, version) async {
      try{
        await db.execute(
          'CREATE TABLE fiszki(id INTEGER PRIMARY KEY, name TEXT, question TEXT, answer TEXT)',
        );
        await db.execute(
          'CREATE TABLE sets(id INTEGER PRIMARY KEY, name TEXT, color TEXT, textColor TEXT)',
        );
      }catch(e){
        print('Blad podczas tworzenia tabel: $e');
      }
      
    },
    version: 1,
  );

  runApp(MyApp(database: database));
}

class Fiszki {
  final int id;
  final String name;
  final String question;
  final String answer;

  Fiszki({
    required this.id,
    required this.name,
    required this.question,
    required this.answer,
  });

  factory Fiszki.fromMap(Map<String, dynamic> map) {
    return Fiszki(
      id: map['id'],
      name: map['name'],
      question: map['question'],
      answer: map['answer'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'question': question,
      'answer': answer,
    };
  }

  @override
  String toString() {
    return 'Fiszki{id: $id, name: $name, question: $question, answer: $answer}';
  }
}

class Set {
  final int id;
  final String name;
  final String color;
  final String textColor; // Nowy argument reprezentujący kolor tekstu

  Set({
    required this.id,
    required this.name,
    required this.color,
    required this.textColor, // Dodajemy argument textColor
  });

  factory Set.fromMap(Map<String, dynamic> map) {
    return Set(
      id: map['id'],
      name: map['name'],
      color: map['color'],
      textColor: map['textColor'], // Wczytujemy wartość koloru tekstu
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color': color,
      'textColor': textColor, // Zapisujemy wartość koloru tekstu
    };
  }

  @override
  String toString() {
    return 'Set{id: $id, name: $name, color: $color, textColor: $textColor}';
  }
}


class AppColors {
  static const Color background = Color(0xFFFAF1E6);
  static const Color button = Color(0xFFE4EFE7);
  static const Color text = Color(0xFF064420);
  static const Color inny = Color(0xFFFDFAF6);
}
class SetColors{
  static const Color jeden = Color(0xFFCD7979);
  static const Color dwa = Color(0xFFF5B35C);
  static const Color trzy = Color(0xFFEBF357);
  static const Color cztery = Color(0xFF5BDE4C);
  static const Color piec = Color(0xFF53E69C);
  static const Color szesc = Color(0xFF45EEC4);
  static const Color siedem = Color(0xFF46E8E5);
  static const Color osiem = Color(0xFF4C93DE);
  static const Color dziewiec = Color(0xFF4C73DE);
  static const Color dziesiec = Color(0xFF7F61ED);
  static const Color jedenascie = Color(0xFFA771E0);
  static const Color dwanascie = Color(0xFFE76BD6);
  static const Color trzynascie = Color(0xFFE9479D);
  static const Color czternascie = Color(0xFFEA5D64);
  static const Color pietnascie = Color(0xFFE85555);
}
class TextColors{
  static const Color czarny = Color(0xFF000000);
  static const Color bialy = Color(0xFFFFFFFF);
}



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
    final db = await widget.database;
    final List<Map<String, dynamic>> setMaps = await db.query('sets');
    List<Set> loadedSets = [];
    for (var setMap in setMaps) {
      if (setMap['id'] != 0) { // Ignorujemy zestaw o id = 0 ma nie pełne dane 
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
          selectionColor: AppColors.text,
          selectionHandleColor: AppColors.text,
        
        ),
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
          padding: const EdgeInsets.all(15), // Dodajemy margines 20 na wszystkich krawędziach
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await _addNewSetToDatabase();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.text,
                  ),
                  child: const Text('Create set'),
                ),
                const SizedBox(height: 20),
                Expanded( // Rozszerzamy Column, aby wypełnić dostępną przestrzeń
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
          MaterialPageRoute(builder: (context) => EmptyClass()), 
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.all(10),
        width: 200,
        height: 100,
        decoration: BoxDecoration(
          color: Color(int.tryParse(set.color) ?? 0xFF000000),
          borderRadius: BorderRadius.circular(15), // Zaokrąglenie rogów
        ),
        child: Row( // Wiersz umożliwiający umieszczenie tekstu z lewej strony i przycisku z prawej
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              set.name,
              style: TextStyle(
                color: Color(int.tryParse(set.textColor) ?? 0xFF000000), // Ustawiamy kolor tekstu
                fontSize: 16, // Domyślny rozmiar czcionki
              ),
            ),
            IconButton(
              onPressed: () {
                    Navigator.push(context, 
                        MaterialPageRoute(builder: (context) => NoteSetScreen()));
              },
              icon: Icon(Icons.edit, color: Color(int.tryParse(set.textColor) ?? 0xFF000000)),
            ),
          ],
        ),
      ),
    );
  }


  Future<void> _addNewSetToDatabase() async {
    final db = await widget.database;
    final List<Map<String, dynamic>> setsCount =
        await db.rawQuery('SELECT COUNT(*) FROM sets');
    final int id = setsCount[0]['COUNT(*)'] + 1;
    final newSet = Set(
      id: id,
      name: 'New set',
      color: '0xFF064420',
      textColor: '0xFFFAF1E6', // Domyślny kolor tekstu
    );
    await db.insert(
      'sets',
      newSet.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _loadSetsFromDatabase();
  }

}

// Pusta klasa, którą można rozwijać w przypadku potrzeby
class EmptyClass extends StatelessWidget {
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
      ),

    );
  }
}
class NoteSetScreen extends StatefulWidget {
  @override
  _NoteSetScreenState createState() => _NoteSetScreenState();
}

class _NoteSetScreenState extends State<NoteSetScreen> {
  late Color _selectedColor; // Domyślny kolor

  @override
  void initState() {
    super.initState();
    _selectedColor = Colors.white; // Ustaw domyślny kolor podczas inicjalizacji stanu
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const TextField(
              decoration: InputDecoration(labelText: 'Change name'),
              cursorColor: AppColors.inny,
            ),
            const SizedBox(height: 16.0),
            const Text(
                  'Set color',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.text
                    ), // Zwiększamy rozmiar tekstu przycisku

                ),
            const SizedBox(height: 8.0),
            Center(
              child: Container(
                width: 200, // Dostosuj szerokość kontenera według własnych preferencji
                height: 200, // Dostosuj wysokość kontenera według własnych preferencji
                child: CircleColorPicker(
                  onChanged: (textcolor) {
                    setState(() {
                      _selectedColor = textcolor;
                    });
                  },
                  // Ustaw domyślny kolor wewnątrz CircleColorPicker
                ),
              ),
            ),

            const SizedBox(height: 18.0),
            const Text(
                  'Set text color',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.text
                    ), // Zwiększamy rozmiar tekstu przycisku

                ),
            const SizedBox(height: 8.0),
            Center(
              child: Container(
                width: 200, // Dostosuj szerokość kontenera według własnych preferencji
                height: 200, // Dostosuj wysokość kontenera według własnych preferencji
                child: CircleColorPicker(
                  onChanged: (textcolor) {
                    setState(() {
                      _selectedColor = textcolor;
                    });
                  },
                  // Ustaw domyślny kolor wewnątrz CircleColorPicker
                ),
              ),
            ),
            const SizedBox(height: 18.0),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  // Tutaj dodaj logikę obsługi przycisku Zapisz
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.background,
                    foregroundColor: AppColors.text,
                    minimumSize: const Size(150, 50), // Tutaj określamy minimalny rozmiar przycisku

                  ),
                
                child: const Text(
                  'Save',
                  style: TextStyle(fontSize: 20), // Zwiększamy rozmiar tekstu przycisku

                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
