import 'package:flutter/material.dart';

class EcranDetails extends StatelessWidget {
  const EcranDetails({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails du profil'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Retour au profil'),
            ),
            const Text("leo be e "),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Text("test"),
                const SizedBox(width: 60),
              ],
             
            ),
          ],
        ),
      ),
    );
  }
}
