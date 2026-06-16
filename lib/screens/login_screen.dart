import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final email = TextEditingController();
  final password = TextEditingController();

  Future<void> login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      showError(e.message);
    }
  }

  Future<void> register() async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      showError(e.message);
    }
  }

  Future<void> resetPassword() async {
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: email.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email de recuperação enviado")),
      );
    } on FirebaseAuthException catch (e) {
      showError(e.message);
    }
  }

  void showError(String? msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg ?? "Erro desconhecido")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [
              BoxShadow(color: Colors.black12, blurRadius: 10),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chat, size: 60, color: Color(0xFF3CCB6C)),
              const SizedBox(height: 10),
              const Text("NexTalk",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),

              TextField(controller: email, decoration: const InputDecoration(hintText: "Email")),
              TextField(controller: password, obscureText: true, decoration: const InputDecoration(hintText: "Senha")),

              const SizedBox(height: 20),

              ElevatedButton(onPressed: login, child: const Text("Entrar")),
              ElevatedButton(onPressed: register, child: const Text("Criar conta")),

              TextButton(onPressed: resetPassword, child: const Text("Esqueci minha senha")),
            ],
          ),
        ),
      ),
    );
  }
}