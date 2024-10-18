import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:window_manager/window_manager.dart';



void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  windowManager.setAlwaysOnTop(true);

  // 300 x 222 -> +14.4, +43.2
  // 300 x 248 -> 314.4, 291.2
  // macos는 y offset -12 줄이기
  windowManager.setSize(Size(314.4, 291.2));
  // windowManager.setMaximumSize(Size(314.4, 249.6));
  // windowManager.setMinimumSize(Size(314.4, 249.6));
  windowManager.setResizable(false);
  windowManager.setMaximizable(false);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Wisp - Mini Translator App',
        theme: ThemeData(
          useMaterial3: true,
          fontFamily: 'Pretendard',
        ),
        home: const MyHomePage(),
      );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class FontSystem {
  static const regularTextStyle = TextStyle(
    fontWeight: FontWeight.w200,
    fontSize: 14,
    letterSpacing: -0.42,
  );
  static const buttonTextStyle = TextStyle(
    fontWeight: FontWeight.w300,
    fontSize: 14,
    letterSpacing: -0.42,
  );
  static const labelTextStyle = TextStyle(
    fontWeight: FontWeight.w500,
    fontSize: 10,
    height: 0.1,
    letterSpacing: -0.30,
  );
}

class ColorSystem {
  static final ColorSystem instance = ColorSystem._internal();
  factory ColorSystem() => instance;
  ColorSystem._internal();

  // Mode
  bool isLight = true;

  // Border Color
  Color defaultBorderColor = Color(0xFFDBDBDB);
  Color focusedBorderColor = Color(0xFF8F80FF);
  bool isFocused = false;

  // Surface Color
  Color backgroundColor = Colors.white;
  Color surfaceColor = Color(0xFFF4F5F6);
  Color buttonSurfaceColor = Color(0xFF5F4AFF);

  // Text Color
  Color primaryTextColor = Color(0xFF353535);
  Color secondaryTextColor = Color(0xFFA7A7A7);
  Color buttonTextColor = Colors.white;

  void toggleMode() {
    isLight = !isLight;
    chooseColor(isLight);
  }

  void chooseColor(bool isLight) {
    if(isLight) {
      defaultBorderColor = Color(0xFFDBDBDB);
      focusedBorderColor = Color(0xFF8F80FF);

      backgroundColor = Colors.white;
      surfaceColor = Color(0xFFF4F5F6);
      buttonSurfaceColor = Color(0xFF5F4AFF);

      primaryTextColor = Color(0xFF353535);
      secondaryTextColor = Color(0xFFA7A7A7);
      buttonTextColor = Colors.white;
    } else {
      defaultBorderColor = Color(0xFF505050);
      focusedBorderColor = Color(0xFF8F80FF);

      backgroundColor = Color(0xFF353535);
      surfaceColor = Color(0xFF484848);
      buttonSurfaceColor = Color(0xFF5F4AFF);

      primaryTextColor = Colors.white;
      secondaryTextColor = Color(0xFF636363);
      buttonTextColor = Colors.white;
    }
  }

  Color inputBorderColor() {
    return isFocused ? focusedBorderColor : defaultBorderColor;
  }

  void inputAreaFocused() {
    isFocused = true;
  }

  void inputAreaUnfocused() {
    isFocused = false;
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final myController = TextEditingController();

  final _apiKey = 'YOUR_API_KEY';

  final _korean = 'KOREAN';
  final _english = 'ENGLISH';

  String _translatedText = '';
  late String _translateFrom;
  late String _translateTo;

  bool isLight = true;
  ColorSystem colorSystem = ColorSystem();

  late Timer _timer;

  bool isCursorOnOutput = false;

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _translateFrom = _english;
    _translateTo = _korean;
    _translateText(myController.text);

    _timer = Timer(const Duration(milliseconds: 100), () {
      _translateText(myController.text);
    });
    _timer.cancel();
  }
  
  String unescape([String string = '']) {
  return string
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
}

  Future<void> _translateText(String text) async {
    // print("Execute translation : " + _translateFrom + " -> " + _translateTo);
    _translatedText = "번역중";
    String targetLanguage = _languageDetect(text);

    final url = 'https://translation.googleapis.com/language/translate/v2?key=$_apiKey';

    final tl = targetLanguage == _korean ? 'ko' : 'en';

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'q': text,
        'target': tl,
      }),
    );

    if(response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      setState(() {
        var res = responseData['data']['translations'][0]['translatedText'];
        // res = unescape(res);
        // print(res);
        // some characters have to be unescaped.
        _translatedText = unescape(res);
      });
    } else {
      setState(() {
        _translatedText = '번역 중 오류가 발생했습니다.';
      });
    }
  }

  // you don't have to use this method manually
  void _toggleLanguage() {
    if(_translateFrom == _english) {
      setState(() {
        _translateFrom = _korean;
        _translateTo = _english;
      });
    } else if(_translateFrom == _korean) {
      setState(() {
        _translateFrom = _english;
        _translateTo = _korean;
      });
    } 
  }

  // you don't have to use this method manually
  void _changeFromLanguage(String target) {
    if(_translateFrom != target) _toggleLanguage();
  }

  // you don't have to use this method manually
  // return : target language
  String _languageDetect(String target) {
    var englishPattern = RegExp(r'[a-zA-Z]');
    var koreanPattern = RegExp(r'[ㄱ-ㅎ|ㅏ-ㅣ|가-힣]');
    
    // character number of each language
    var engMatchCount = englishPattern.allMatches(target).length;
    var korMatchCount = koreanPattern.allMatches(target).length;
    
    if(engMatchCount >= korMatchCount) {
      _changeFromLanguage(_english);
    } else {
      _changeFromLanguage(_korean);
    }

    return _translateTo;
  }

  void _toggleThemeMode() {
    setState(() {
      colorSystem.toggleMode();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyT, control: true): () {
          setState(() {
            _toggleThemeMode();
          });
        }
      },
      child: Scaffold(
        backgroundColor: colorSystem.backgroundColor,
        body: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          child: Column(
            children: [
              //
              // Input Box
              //
              Container(
                height: 108,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorSystem.inputBorderColor(),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: 15,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 10,
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            _translateFrom,
                            style: FontSystem.labelTextStyle.copyWith(
                              color: colorSystem.secondaryTextColor,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 4),
                      SizedBox(
                        height: 68,
                        child: Focus(
                          onFocusChange: (hasFocus) {
                            if(hasFocus) {
                              // print('in');
                              setState(() {
                                colorSystem.inputAreaFocused();
                              });
                            } else {
                              // print('bye');
                              setState(() {
                                colorSystem.inputAreaUnfocused();
                              });
                            } 
                          },
                          child: TextField(
                            decoration: InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              
                              hintText: '번역할 내용을 입력하세요.',
                              hintStyle: FontSystem.regularTextStyle.copyWith(
                                height: 0.1,
                                color: colorSystem.secondaryTextColor,
                              ),
                            ),
                            style: FontSystem.regularTextStyle.copyWith(
                              color: colorSystem.primaryTextColor,
                            ),
                            keyboardType: TextInputType.multiline,
                            maxLines: null,
                            cursorHeight: 18,
                            cursorWidth: 1.0,
                                
                            controller: myController,
                            onEditingComplete: () {
                              String target = myController.text;
                              if(target.isNotEmpty) {
                                _translateText(myController.text);
                              }
                            },
                            onChanged: (value) {
                              // if(value.endsWith(' ')) {
                              //   _translateText(myController.text);
                              // }
                              if(_timer.isActive) {
                                _timer.cancel();
                              }
                              _timer = Timer(const Duration(milliseconds: 100), () {
                                _translateText(myController.text);
                                // print("Translated");
                              });
                              // _translateText(myController.text);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 8,),
              //
              // Output
              //
              MouseRegion(
                onEnter: (event) {
                  // print("Enter");
                  setState(() {
                    isCursorOnOutput = true;
                  });
                },
                onExit: (event) {
                  // print("Exit");
                  setState(() {
                    isCursorOnOutput = false;
                  });
                },
                // onHover: (event) {
                //   isCursorOnOutput = true;
                // },
                child: Container(
                  height: 108,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: colorSystem.defaultBorderColor,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: colorSystem.surfaceColor,
                  ),
                      
                  child: Stack(
                    children: [
                      Positioned.fill(
                        bottom: 9, top: 9,
                        left: 15, right: 15,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            SizedBox(
                              height: 10,
                              child: Center(
                                widthFactor: 1,
                                child: Text(
                                  _translateTo,
                                  style: FontSystem.labelTextStyle.copyWith(
                                    color: colorSystem.secondaryTextColor,
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(width: 268, height: 4,),
                            Expanded(
                              flex: 1,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.vertical,
                                child: SelectableText(
                                  _translatedText,
                                  style: FontSystem.regularTextStyle.copyWith(
                                    color: colorSystem.primaryTextColor,
                                    overflow: TextOverflow.visible
                                  ),
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                      Positioned(
                        width: 24,
                        height: 24,
                        bottom: 16,
                        right: 16,
                        child:  isCursorOnOutput ? IconButton(
                          onPressed: () {
                            // print("copy");
                            Clipboard.setData(ClipboardData(text: _translatedText));
                          }, 
                          style: IconButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            backgroundColor: Colors.black.withOpacity(0.4),
                            padding: EdgeInsets.zero,
                          ),
                          icon: SvgPicture.asset(
                            'assets/imgs/copy_icon.svg',
                          ),
                        ) : SizedBox.shrink(),
                      )
                    ],
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
