import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class NewMessage extends StatefulWidget {
  const NewMessage({super.key});

  @override
  State<NewMessage> createState() => _NewMessageState();
}

class _NewMessageState extends State<NewMessage> {
  var _messagecontroller = TextEditingController();

  @override
  void sendMessage() async {
    // FocusScope.of(context).unfocus();
    var message = _messagecontroller.text;
    if (message == null || message.length == 0) {
      return;
    }
    final user = await FirebaseAuth.instance.currentUser;
    final userData = await FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get();
    await FirebaseFirestore.instance.collection("messages").add({
      'SenderID': user.uid,
      'CreatedAt': Timestamp.now(),
      'Message': message,
      'SenderName': userData.data()!['username'],
      'image': userData.data()!['imageURL']
    });
    _messagecontroller.clear();
  }

  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 15, right: 15, bottom: 5),
      child: Row(
        children: [
          Expanded(
              child: TextField(
            controller: _messagecontroller,
            textCapitalization: TextCapitalization.sentences,
            autocorrect: true,
            enableSuggestions: true,
            decoration: InputDecoration(hintText: "Send a message...."),
          )),
          IconButton(
            onPressed: sendMessage,
            icon: Icon(Icons.send),
            color: Theme.of(context).colorScheme.primary,
          )
        ],
      ),
    );
  }
}
