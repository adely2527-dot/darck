import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:audioplayers/audioplayers.dart';

const adminEmails = ['adely2527@gmail.com'];
const adminPass = '12008';
const superAdminName = 'VOIDWATCH';
const superAdminId = 'DARCK-8X47-K9';

bool verifyAdmin(String pass) {
  return sha256.convert(utf8.encode(pass)).toString() ==
         sha256.convert(utf8.encode(adminPass)).toString();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDummy-Build-Key-123456",
      appId: "1:123456789:android:abcdef123456",
      messagingSenderId: "123456789",
      projectId: "darck-v48-full",
      storageBucket: "darck-v48-full.appspot.com",
    ),
  );
  runApp(DarckFullApp());
}

class DarckFullApp extends StatefulWidget {
  @override
  _DarckFullAppState createState() => _DarckFullAppState();
}

class _DarckFullAppState extends State<DarckFullApp> {
  File? customBg;
  @override
  void initState() {
    super.initState();
    loadBg();
  }
  loadBg() async {
    final p = await SharedPreferences.getInstance();
    String? path = p.getString('custom_bg');
    if(path!= null && File(path).existsSync()){
      setState(()=> customBg = File(path));
    }
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: Colors.black),
      home: Stack(children: [
        if(customBg!= null)
          Opacity(opacity: 0.35, child: Image.file(customBg!, fit: BoxFit.cover, width: double.infinity, height: double.infinity)),
        AuthGate(onBgChanged: loadBg),
      ]),
    );
  }
}

class AuthGate extends StatelessWidget {
  final Function onBgChanged;
  AuthGate({required this.onBgChanged});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (c, snap) {
        if(snap.connectionState == ConnectionState.waiting) return Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF00FF41))));
        if(snap.hasData) return PasswordGate(user: snap.data!, onBgChanged: onBgChanged);
        return LoginScreen();
      },
    );
  }
}

class LoginScreen extends StatelessWidget {
  Future signIn() async {
    final g = GoogleSignIn();
    final gu = await g.signIn();
    if(gu == null) return;
    final ga = await gu.authentication;
    final cred = GoogleAuthProvider.credential(idToken: ga.idToken, accessToken: ga.accessToken);
    await FirebaseAuth.instance.signInWithCredential(cred);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shield, size: 90, color: Color(0xFF00FF41)),
        SizedBox(height: 15),
        Text("DARCK v4.8.1 FULL", style: TextStyle(color: Color(0xFF00FF41), fontSize: 22, fontFamily: 'monospace', fontWeight: FontWeight.bold)),
        SizedBox(height: 40),
        ElevatedButton.icon(
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.black, minimumSize: Size(250, 50)),
          onPressed: signIn,
          icon: Icon(Icons.login),
          label: Text("Sign in with Google"),
        ),
      ])),
    );
  }
}

class PasswordGate extends StatefulWidget {
  final User user;
  final Function onBgChanged;
  PasswordGate({required this.user, required this.onBgChanged});
  @override
  _PasswordGateState createState() => _PasswordGateState();
}

class _PasswordGateState extends State<PasswordGate> {
  final c = TextEditingController();
  bool isAdminEmail = false;
  @override
  void initState() {
    super.initState();
    isAdminEmail = adminEmails.contains(widget.user.email?.toLowerCase());
  }
  @override
  Widget build(BuildContext context) {
    if(!isAdminEmail) return DarckHome(user: widget.user, isSuperAdmin: false, onBgChanged: widget.onBgChanged);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, title: Text("👑 VOIDWATCH SECURITY GATE", style: TextStyle(color: Color(0xFF00FF41), fontSize: 14))),
      body: Padding(padding: EdgeInsets.all(25), child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("مرحبا ${widget.user.email}\nاكتب باس الادمن للمتابعة", style: TextStyle(color: Colors.white70), textAlign: TextAlign.center),
        SizedBox(height: 20),
        TextField(controller: c, obscureText: true, style: TextStyle(color: Color(0xFF00FF41)), decoration: InputDecoration(labelText: "Admin Pass", labelStyle: TextStyle(color: Colors.white54), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))))),
        SizedBox(height: 20),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00FF41), foregroundColor: Colors.black, minimumSize: Size(double.infinity, 50)),
          onPressed: (){
            if(verifyAdmin(c.text.trim())){
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => DarckHome(user: widget.user, isSuperAdmin: true, onBgChanged: widget.onBgChanged)));
            } else {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("باسورد غلط")));
            }
          },
          child: Text("دخول كـ Super Admin"),
        ),
      ])),
    );
  }
}

class DarckHome extends StatelessWidget {
  final User user;
  final bool isSuperAdmin;
  final Function onBgChanged;
  DarckHome({required this.user, required this.isSuperAdmin, required this.onBgChanged});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(isSuperAdmin? "DARCK v4.8.1 👑 VOIDWATCH" : "DARCK v4.8.1", style: TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace')),
        actions: [IconButton(icon: Icon(Icons.logout, color: Colors.white54), onPressed: ()=> FirebaseAuth.instance.signOut())],
      ),
      drawer: isSuperAdmin? AdminDrawer() : null,
      body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.shield, size: 70, color: Color(0xFF00FF41)),
        SizedBox(height: 10),
        Text(isSuperAdmin? "مرحبا $superAdminName" : "مرحبا ${user.displayName?? 'User'}", style: TextStyle(color: isSuperAdmin? Colors.amber : Colors.white, fontSize: 18)),
        if(isSuperAdmin) Text("ID: $superAdminId - GLOBAL", style: TextStyle(color: Colors.amber, fontSize: 12, fontFamily: 'monospace')),
        SizedBox(height: 30),
        _btn(context, "💬 شات + ريكورد", ChatScreen(user: user, isSuperAdmin: isSuperAdmin)),
        _btn(context, "🎨 ثيمك الخاص", ThemeScreen(onChanged: onBgChanged)),
        if(isSuperAdmin) _btn(context, "👑 لوحة تحكم الادمن", AdminPanel()),
      ])),
    );
  }
  Widget _btn(BuildContext c, String t, Widget s){
    return Container(margin: EdgeInsets.symmetric(vertical: 7), width: 260, child: ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: Colors.black, side: BorderSide(color: Color(0xFF00FF41))),
      onPressed: ()=> Navigator.push(c, MaterialPageRoute(builder: (_)=> s)),
      child: Text(t, style: TextStyle(color: Color(0xFF00FF41), fontFamily: 'monospace')),
    ));
  }
}

class ChatScreen extends StatefulWidget {
  final User user;
  final bool isSuperAdmin;
  ChatScreen({required this.user, required this.isSuperAdmin});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}
class _ChatScreenState extends State<ChatScreen> {
  final ctrl = TextEditingController();
  final fs = FirebaseFirestore.instance;
  final rec = AudioRecorder();
  final player = AudioPlayer();
  bool isRec = false;

  send() async {
    if(ctrl.text.trim().isEmpty) return;
    await fs.collection('darck_messages').add({
      'text': ctrl.text.trim(),
      'isVoice': false,
      'uid': widget.user.uid,
      'email': widget.user.email,
      'name': widget.isSuperAdmin? superAdminName : widget.user.displayName,
      'isSuperAdmin': widget.isSuperAdmin,
      'time': FieldValue.serverTimestamp(),
    });
    ctrl.clear();
  }

  toggleRecord() async {
    if(isRec){
      String? path = await rec.stop();
      setState(()=> isRec = false);
      if(path!= null){
        await fs.collection('darck_messages').add({
          'text': '🎤 Voice Message',
          'isVoice': true,
          'voicePath': path,
          'uid': widget.user.uid,
          'email': widget.user.email,
          'name': widget.isSuperAdmin? superAdminName : widget.user.displayName,
          'isSuperAdmin': widget.isSuperAdmin,
          'time': FieldValue.serverTimestamp(),
        });
      }
    } else {
      if(await Permission.microphone.request().isGranted){
        if(await rec.hasPermission()){
          await rec.start(const RecordConfig(), path: '/storage/emulated/0/Download/darck_${DateTime.now().millisecondsSinceEpoch}.m4a');
          setState(()=> isRec = true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("الشات - Server + Voice ON", style: TextStyle(color: Color(0xFF00FF41), fontSize: 14)), backgroundColor: Colors.black),
      backgroundColor: Colors.black,
      body: Column(children: [
        Expanded(child: StreamBuilder<QuerySnapshot>(
          stream: fs.collection('darck_messages').orderBy('time', descending: true).limit(100).snapshots(),
          builder: (c, s){
            if(!s.hasData) return Center(child: CircularProgressIndicator());
            return ListView.builder(reverse: true, itemCount: s.data!.docs.length, itemBuilder: (c,i){
              var d = s.data!.docs[i];
              bool admin = d['isSuperAdmin']?? false;
              bool isVoice = d['isVoice']?? false;
              return ListTile(
                title: Text(d['name']?? 'User', style: TextStyle(color: admin? Colors.amber : Color(0xFF00FF41), fontWeight: admin? FontWeight.bold : FontWeight.normal, fontSize: 13)),
                subtitle: isVoice? Row(children: [Icon(Icons.mic, color: Color(0xFF00FF41), size: 16), SizedBox(width: 5), Text("رسالة صوتية - اضغط للتشغيل", style: TextStyle(color: Colors.white70))]) : Text(d['text'], style: TextStyle(color: Colors.white)),
                leading: Icon(admin? Icons.verified : Icons.person, color: admin? Colors.amber : Colors.white54),
                onTap: isVoice? () async {
                  String p = d['voicePath'];
                  await player.play(DeviceFileSource(p));
                } : null,
              );
            });
          },
        )),
        Container(padding: EdgeInsets.all(10), color: Color(0xFF111111), child: Row(children: [
          IconButton(icon: Icon(isRec? Icons.stop : Icons.mic, color: isRec? Colors.red : Color(0xFF00FF41)), onPressed: toggleRecord),
          Expanded(child: TextField(controller: ctrl, style: TextStyle(color: Colors.white), decoration: InputDecoration(hintText: isRec? "بيسجل... دوس ستوب" : "اكتب رسالة او سجل ريكورد...", hintStyle: TextStyle(color: Colors.white38), enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41))), focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF00FF41)))))),
          SizedBox(width: 8),
          IconButton(icon: Icon(Icons.send, color: Color(0xFF00FF41)), onPressed: send)
        ]))
      ]),
    );
  }
}

class ThemeScreen extends StatefulWidget {
  final Function onChanged;
  ThemeScreen({required this.onChanged});
  @override
  _ThemeScreenState createState() => _ThemeScreenState();
}
class _ThemeScreenState extends State<ThemeScreen> {
  pick() async {
    final p = await ImagePicker().pickImage(source: ImageSource.gallery);
    if(p!= null){
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('custom_bg', p.path);
      widget.onChanged();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("تم حفظ ثيمك الخاص ✅ خلفية جديدة")));
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text("ثيمك الخاص 🎨"), backgroundColor: Colors.black), backgroundColor: Colors.black, body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.image, size: 60, color: Color(0xFF00FF41)),
      SizedBox(height: 20),
      ElevatedButton(onPressed: pick, style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF00FF41), foregroundColor: Colors.black, minimumSize: Size(220, 50)), child: Text("اختر صورة من المعرض")),
      SizedBox(height: 10),
      Text("الصورة هتبقى خلفية الاب كله", style: TextStyle(color: Colors.white54)),
    ])));
  }
}

class AdminDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(backgroundColor: Color(0xFF0A0A0A), child: ListView(children: [
      DrawerHeader(child: Text("👑 VOIDWATCH\nAdmin Control", style: TextStyle(color: Color(0xFF00FF41), fontSize: 18))),
      ListTile(title: Text("📜 View Ghost Logs", style: TextStyle(color: Colors.white)), onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> GhostLogs()))),
      ListTile(title: Text("🚫 Banned Users", style: TextStyle(color: Colors.white)), onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> BannedScreen()))),
      ListTile(title: Text("✅ Verified Users", style: TextStyle(color: Colors.white)), onTap: ()=> Navigator.push(context, MaterialPageRoute(builder: (_)=> VerifiedScreen()))),
    ]));
  }
}
class AdminPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("Admin Panel")), backgroundColor: Colors.black, body: Center(child: Text("Lock / Freeze / Emergency + BAN / TIMEOUT\nانت بس اللي شايف اللوحة دي", style: TextStyle(color: Colors.white), textAlign: TextAlign.center)));
}
class GhostLogs extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("Ghost Logs")), backgroundColor: Colors.black, body: StreamBuilder<QuerySnapshot>(stream: FirebaseFirestore.instance.collection('ghost_logs').orderBy('time', descending: true).snapshots(), builder: (c,s){ if(!s.hasData) return Center(child: CircularProgressIndicator()); return ListView(children: s.data!.docs.map((d)=> ListTile(title: Text(d['action']?? '', style: TextStyle(color: Colors.white)), subtitle: Text(d['email']?? '', style: TextStyle(color: Colors.white54)))).toList()); }));
}
class BannedScreen extends StatelessWidget { @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("Banned")), backgroundColor: Colors.black, body: Center(child: Text("قائمة المحظورين", style: TextStyle(color: Colors.white)))); }
class VerifiedScreen extends StatelessWidget { @override Widget build(BuildContext context) => Scaffold(appBar: AppBar(title: Text("Verified")), backgroundColor: Colors.black, body: Center(child: Text("قائمة الموثقين", style: TextStyle(color: Colors.white)))); }
