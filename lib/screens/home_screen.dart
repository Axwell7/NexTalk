import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/settings_sheet.dart';
import 'package:intl/intl.dart';
import 'dart:html' as html;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController messageController = TextEditingController();
  final FocusNode messageFocus = FocusNode();
  final ScrollController scrollController = ScrollController();

  final user = FirebaseAuth.instance.currentUser!;
  final firestore = FirebaseFirestore.instance;

  final Set<String> selectedMessages = {};

  String userName = 'Usuário';

  bool get selectionMode => selectedMessages.isNotEmpty;

  CollectionReference get messagesRef =>
      firestore.collection('users').doc(user.uid).collection('messages');

  @override
  void initState() {
    super.initState();
    loadUserName();

    html.document.onContextMenu.listen((event) {
      event.preventDefault();
    });
  }

  Future<void> loadUserName() async {
    final doc = await firestore.collection('users').doc(user.uid).get();

    if (doc.exists) {
      setState(() {
        userName =
            doc.data()?['displayName'] ??
            (user.email ?? 'usuario').split('@')[0];
      });
    }
  }

  Future<void> sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    await messagesRef.add({
      'texto': messageController.text.trim(),
      'senderId': user.uid,
      'senderName': userName,
      'dataHora': Timestamp.now(),
    });

    messageController.clear();

    Future.delayed(const Duration(milliseconds: 50), () {
      if (mounted) messageFocus.requestFocus();
    });

    Future.delayed(const Duration(milliseconds: 150), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> deleteSelectedMessages() async {
    for (final id in selectedMessages) {
      await messagesRef.doc(id).delete();
    }

    setState(() {
      selectedMessages.clear();
    });
  }

  Future<void> deleteSingleMessage(String id) async {
    await messagesRef.doc(id).delete();
  }

  void toggleSelection(String id) {
    setState(() {
      if (selectedMessages.contains(id)) {
        selectedMessages.remove(id);
      } else {
        selectedMessages.add(id);
      }
    });
  }

  void clearSelection() {
    setState(() {
      selectedMessages.clear();
    });
  }

  void editMessage(String id, String currentText) {
    final controller = TextEditingController(text: currentText);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar mensagem'),
        content: TextField(controller: controller),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              await messagesRef.doc(id).update({
                'texto': controller.text.trim(),
              });
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  void showMessageMenu(
  BuildContext context,
  Offset position,
  String id,
  String text,
) {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;

  showMenu(
    context: context,
    position: RelativeRect.fromRect(
      Rect.fromLTWH(position.dx, position.dy, 0, 0),
      Rect.fromLTWH(0, 0, overlay.size.width, overlay.size.height),
    ),
    items: [
      const PopupMenuItem(value: 'edit', child: Text('Editar')),
      const PopupMenuItem(value: 'delete', child: Text('Excluir')),
      const PopupMenuItem(value: 'select', child: Text('Selecionar')),
    ],
  ).then((value) {
    if (value == 'edit') {
      editMessage(id, text);
    } else if (value == 'delete') {
      deleteSingleMessage(id);
    } else if (value == 'select') {
      toggleSelection(id);
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF3CCB6C),
        title: Text(
          selectionMode
              ? '${selectedMessages.length} selecionada(s)'
              : 'NexTalk',
        ),
        leading: selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: clearSelection,
              )
            : null,
        actions: selectionMode
            ? [
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: deleteSelectedMessages,
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () => showSettingsSheet(context),
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () => FirebaseAuth.instance.signOut(),
                ),
              ],
      ),

      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: messagesRef.orderBy('dataHora').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: scrollController,
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;

                    final isMe = data['senderId'] == user.uid;
                    final selected = selectedMessages.contains(id);

                    final timestamp = data['dataHora'] as Timestamp?;
                    final horario = timestamp != null
                        ? DateFormat('HH:mm').format(timestamp.toDate())
                        : '';

                    return GestureDetector(
                      onSecondaryTapDown: (details) {
                        showMessageMenu(
                          context,
                          details.globalPosition,
                          id,
                          data['texto'] ?? '',
                        );
                      },

                      onLongPress: () => toggleSelection(id),

                      onTap: selectionMode ? () => toggleSelection(id) : null,

                      child: Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 12,
                          ),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.green.withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CircleAvatar(
                                    radius: 14,
                                    backgroundColor: const Color(0xFF3CCB6C),
                                    child: Text(
                                      (data['senderName'] ?? '?')
                                          .substring(0, 1)
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    data['senderName'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isMe
                                      ? const Color(0xFF3CCB6C)
                                      : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  data['texto'] ?? '',
                                  style: TextStyle(
                                    color: isMe ? Colors.white : Colors.black,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 4),

                              Text(
                                horario,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: messageController,
                    focusNode: messageFocus,
                    onSubmitted: (_) => sendMessage(),
                    textInputAction: TextInputAction.send,
                    decoration: const InputDecoration(
                      hintText: 'Digite uma mensagem',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Color(0xFF3CCB6C)),
                  onPressed: sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
