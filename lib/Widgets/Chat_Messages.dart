import 'package:chat_app/Widgets/MessageBubble.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/placeholder.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChatMessages extends StatefulWidget {
  const ChatMessages({super.key});

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  final auth = FirebaseAuth.instance.currentUser!.uid;
  var isMe = false;

  String addnl(String input) {
    if (input == null || input.isEmpty) {
      return input;
    }

    final int charsPerLine = 20;
    StringBuffer buffer = StringBuffer();

    for (int i = 0; i < input.length; i += charsPerLine) {
      int end = i + charsPerLine;
      buffer.write(input.substring(i, end < input.length ? end : input.length));
      if (end < input.length) {
        buffer.write('\n');
      }
    }

    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text("No Text Messages"),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text("Something went wrong"),
            );
          }
          final loadedMessages = snapshot.data!.docs;
          return ListView.builder(
            padding: EdgeInsets.only(bottom: 40, left: 13, right: 13),
            reverse: true,
            itemCount: loadedMessages.length,
            itemBuilder: (context, index) {
              if (auth == loadedMessages[index].data()['SenderID']) {
                isMe = true;
              } else {
                isMe = false;
              }
              String msg = loadedMessages[index].data()['Message'];
              print("${isMe}");
              return MessageBubble(
                message: msg.length > 35 ? addnl(msg) : msg,
                image: loadedMessages[index].data()['image'],
                name: loadedMessages[index].data()['SenderName'],
                isMe: isMe,
              );
            },
          );
        },
        stream: FirebaseFirestore.instance
            .collection('messages')
            .orderBy('CreatedAt', descending: true)
            .snapshots());
  }
}
