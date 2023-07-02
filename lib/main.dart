import 'package:firebase_core/firebase_core.dart';
import 'package:friday/screens/onboarding_page.dart';
import 'package:friday/screens/splash.dart';

import 'package:flutter/material.dart';
import 'package:friday/feedback.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:friday/utils/bottom_navbar_tabs.dart';
import 'package:flutter/services.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:is_first_run/is_first_run.dart';
import 'package:provider/provider.dart';

///Project Local Imports
import 'package:friday/services/authentication.dart';
import 'package:friday/services/user_info_services.dart';

import 'onboarding/introslider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isFirstRun = false;
    int backButtonPressCounter = 0;

  @override
  void initState() {
    super.initState();
    checkFirstRun();
  }

 Future<void> checkFirstRun() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    isFirstRun = IsFirstRun.isFirstRun() as bool;
    setState(() {
      isFirstRun = isFirstRun;
    });
    prefs.setBool('already_rated', false);
  }
   Future<void> showRatingDialog(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool alreadyRated = prefs.getBool('already_rated') ?? false;
    if (!alreadyRated) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Rate Our App'),
          content: Text('Please take a moment to provide feedback.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/feedback');
              },
              child: Text('Rate Now'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                prefs.setBool('already_rated', true);
              },
              child: Text('Maybe Later'),
            ),
          ],
        ),
      );
    }
  }

   Future<bool> onWillPop() async {
    backButtonPressCounter++;
    if (backButtonPressCounter == 2) {
      backButtonPressCounter = 0;
      await showRatingDialog(context);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
        SystemUiOverlayStyle(statusBarColor: Colors.transparent));

    return MultiProvider(
      ///Adding providers for App
      providers: [
        ChangeNotifierProvider(
          create: (context) => UserInfoServices(),
        ),
        ChangeNotifierProvider(
          create: (context) => BottomNavigationBarProvider(),
        )
      ],
      child: WillPopScope(
        onWillPop:onWillPop,
        child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Friday',
        theme: ThemeData(
          primaryColor: Color(0xFF202328),
          visualDensity: VisualDensity.adaptivePlatformDensity, 
          colorScheme: ColorScheme.fromSwatch()
          .copyWith(secondary: Color(0xFF651FFF))
          .copyWith(background: Color(0xFF12171D)),
        ),
        home: FutureBuilder(
          future: Future.delayed(Duration(seconds: 3)),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SplashScreen(key: UniqueKey());
            } else {
              if (isFirstRun) {
                return OnBoardingPage();
              } else {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) => showRatingDialog(context),
                );
                return AuthenticationService.handleEntryPoint(context);
              }
            }
          }
        ),
          routes: {
           '/feedback': (context) => FeedbackPage(),
          },
        ),
      ),
    );
  }
}
