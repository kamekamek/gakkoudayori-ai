import 'package:flutter/material.dart';

/// 学級通信AI - 音声入力システム（リビルド版）
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(YutoriKyoshituApp());
}

class YutoriKyoshituApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '学級通信AI',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: HomePage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🎤 学級通信AI - 音声入力システム'),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '音声→AI→学級通信の自動生成',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40),

              // 次のPhaseで実装予定
              ElevatedButton.icon(
                onPressed: null, // Phase R2で実装
                icon: Icon(Icons.mic),
                label: Text('🎤 録音開始'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(200, 60),
                ),
              ),

              SizedBox(height: 20),
              Text(
                'Phase R1: プロジェクト初期化完了\n'
                'Phase R2: 音声録音機能（実装予定）',
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
