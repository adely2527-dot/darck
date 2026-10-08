import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DarckApp());
}

class DarckApp extends StatelessWidget {
  const DarckApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Darck',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        primaryColor: const Color(0xFF00FF88),
      ),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasData) return const DarckHome();
        return const LoginPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool loading = false;
  Future<void> signIn() async {
    setState(() => loading = true);
    try {
      final gUser = await GoogleSignIn().signIn();
      if (gUser == null) { setState(() => loading = false); return; }
      final gAuth = await gUser.authentication;
      final cred = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(cred);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => loading = false);
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('DARCK', style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, letterSpacing: 6)),
            const SizedBox(height: 8),
            const Text('UNIVERSAL 4.8.1', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 60),
            loading? const CircularProgressIndicator() :
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00FF88),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
              ),
              icon: const Icon(Icons.login),
              label: const Text('Sign in with Google'),
              onPressed: signIn,
            ),
          ],
        ),
      ),
    );
  }
}

class DarckHome extends StatefulWidget {
  const DarckHome({super.key});
  @override
  State<DarckHome> createState() => _DarckHomeState();
}

class _DarckHomeState extends State<DarckHome> {
  int index = 0;
  final pages = const [ChatPage(), ProfilePage()];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF111111),
        selectedItemColor: const Color(0xFF00FF88),
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Me'),
        ],
      ),
    );
  }
}

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController ctrl = TextEditingController();
  final FirebaseFirestore db = FirebaseFirestore.instance;
  final user = FirebaseAuth.instance.currentUser;
  void send() async {
    if (ctrl.text.trim().isEmpty) return;
    await db.collection('darck_messages').add({
      'text': ctrl.text.trim(),
      'uid': user!.uid,
      'email': user!.email,
      'time': FieldValue.serverTimestamp(),
    });
    ctrl.clear();
  }
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppBar(title: const Text('DARCK CHAT'), backgroundColor: const Color(0xFF111111), centerTitle: true),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: db.collection('darck_messages').orderBy('time', descending: true).limit(100).snapshots(),
            builder: (c, s) {
              if (!s.hasData) return const Center(child: CircularProgressIndicator());
              final docs = s.data!.docs;
              return ListView.builder(
                reverse: true,
                itemCount: docs.length,
                itemBuilder: (c, i) {
                  final m = docs[i].data() as Map<String, dynamic>;
                  final isMe = m['uid'] == user!.uid;
                  return Align(
                    alignment: isMe? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isMe? const Color(0xFF00FF88).withOpacity(0.2) : const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isMe? const Color(0xFF00FF88) : Colors.transparent),
                      ),
                      child: Text(m['text']?? ''),
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              Expanded(child: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'Write something...', border: OutlineInputBorder()))),
              const SizedBox(width: 8),
              IconButton(icon: const Icon(Icons.send, color: Color(0xFF00FF88)), onPressed: send),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 40, backgroundImage: u?.photoURL!= null? NetworkImage(u!.photoURL!) : null),
          const SizedBox(height: 16),
          Text(u?.displayName?? 'Darck User', style: const TextStyle(fontSize: 20)),
          Text(u?.email?? '', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async { await FirebaseAuth.instance.signOut(); await GoogleSignIn().signOut(); },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
