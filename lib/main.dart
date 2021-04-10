import 'package:flutter/material.dart';
import 'dart:ffi';

import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

void main() {
  runApp(MyApp());
}

String printMidiDevices() {
  String result = '';
  int nMidiDeviceNum;
  Pointer<MIDIINCAPS> caps = calloc<MIDIINCAPS>();

  nMidiDeviceNum = midiInGetNumDevs();
  if (nMidiDeviceNum == 0) {
    result = "midiInGetNumDevs() return 0...\n";
    return result;
  }

  result += '== PrintMidiDevices() == \n';
  for (int i = 0; i < nMidiDeviceNum; ++i) {
    midiInGetDevCaps(i, caps, sizeOf<MIDIINCAPS>());
    var name = caps.ref.szPname;
    result += '$i : name = $name\n';
  }
  result += '=====\n';

  free(caps);

  return result;
}

void onMidiData(
    int hMidiIn, int wMsg, int dwInstance, int dwParam1, int dwParam2) {
  switch (wMsg) {
    case MIM_OPEN:
      print('wMsg=MIM_OPEN\n');
      break;
    case MIM_CLOSE:
      print('wMsg=MIM_CLOSE\n');
      break;
    case MIM_DATA:
      print(
          'wMsg=MIM_DATA, dwInstance=$dwInstance, dwParam1=$dwParam1, dwParam2=$dwParam2\n');
      break;
    case MIM_LONGDATA:
      print('wMsg=MIM_LONGDATA\n');
      break;
    case MIM_ERROR:
      print('wMsg=MIM_ERROR\n');
      break;
    case MIM_LONGERROR:
      print('wMsg=MIM_LONGERROR\n');
      break;
    case MIM_MOREDATA:
      print('wMsg=MIM_MOREDATA\n');
      break;
    default:
      print('wMsg = unknown. Code: $wMsg\n');
      break;
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Windows MIDI Test'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String? title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final hMidiDevicePtr = calloc<IntPtr>();
  final pointer = Pointer.fromFunction<MidiInProc>(onMidiData);
  final nMidiDeviceNum = 1;

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();

    midiInStop(hMidiDevicePtr.value);
    midiInClose(hMidiDevicePtr.value);
    free(hMidiDevicePtr);
    free(pointer);
  }

  void onConnect() {
    print(
        'about to open midi connection. Currently, hMidiDevice is: ${hMidiDevicePtr.address}');
    final rv = midiInOpen(hMidiDevicePtr, nMidiDeviceNum, GetCurrentThread(), 0,
        CALLBACK_FUNCTION);
    switch (rv) {
      case MMSYSERR_NOERROR:
        print('midiInOpen() successfull!');
        break;
      case MMSYSERR_ALLOCATED:
        print('midiInOpen() failed! Device already in use.');
        break;
      case MMSYSERR_BADDEVICEID:
        print('midiInOpen() failed! Device unknown.');
        break;
      default:
        print('midiInOpen() failed for some reason!');
    }

    if (rv == MMSYSERR_NOERROR) {
      final rs = midiInStart(hMidiDevicePtr.value);
      if (rs == MMSYSERR_INVALHANDLE) {
        print(
            'midiInStart() failed! device handle \'${hMidiDevicePtr.value}\' is wrong');
      } else if (rs == MMSYSERR_NOERROR) {
        print('midiInStart() successfull');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title!),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Do you have MIDI devices?',
            ),
            Text(
              printMidiDevices(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onConnect,
        tooltip: 'Connect',
        child: Icon(Icons.link),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
