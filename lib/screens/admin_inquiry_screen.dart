import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../main.dart'; // kPrimaryColor

class AdminInquiryScreen extends StatefulWidget {
  const AdminInquiryScreen({super.key});

  @override
  State<AdminInquiryScreen> createState() => _AdminInquiryScreenState();
}

class _AdminInquiryScreenState extends State<AdminInquiryScreen> {
  // [보안 경고]
  // 이 페이지는 현재 '/admin-inquiries' 링크를 아는 사람은 누구나 접근 가능합니다.
  // 반드시 Firebase Authentication을 사용하여 관리자 로그인을 구현해야 합니다.
  // 예: if (FirebaseAuth.instance.currentUser?.email != "admin@flow.com") { return Text("접근 권한 없음"); }

  // 문의 목록을 실시간으로 가져오기 위한 Stream
  final Stream<QuerySnapshot> _inquiriesStream = FirebaseFirestore.instance
      .collection('inquiries')
      .orderBy('createdAt', descending: true)
      .snapshots();

  final HttpsCallable _sendReplyFunction =
  FirebaseFunctions.instanceFor(region: 'asia-northeast3') // 서울 리전
      .httpsCallable('sendReplyEmail');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('관리자: 문의 내역'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              // TODO: 관리자 로그아웃 로직 (Firebase Auth)
              FirebaseAuth.instance.signOut();
              // 로그아웃 후 홈으로
              if (mounted) Navigator.of(context).pushReplacementNamed('/');
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _inquiriesStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('새로운 문의 내역이 없습니다.'));
          }

          // 데이터가 있을 경우 ListView 표시
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Map<String, dynamic> data =
              document.data()! as Map<String, dynamic>;
              bool isCompleted = data['status'] == 'Completed';
              String email = data['replyToEmail'] ?? '익명';
              String message = data['message'];
              Timestamp t = data['createdAt'] ?? Timestamp.now();
              String date = DateFormat('yy-MM-dd HH:mm').format(t.toDate());

              return Card(
                elevation: 2,
                color: isCompleted ? Colors.grey[200] : Colors.white,
                child: ListTile(
                  title: Text('$email ($date)'),
                  subtitle: Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    isCompleted ? Icons.check_circle : Icons.pending,
                    color: isCompleted ? Colors.green : Colors.orange,
                  ),
                  onTap: () {
                    // 탭하면 답변 다이얼로그 띄우기
                    _showReplyDialog(context, document.id, email, message, data['replyMessage']);
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  // 답변 작성 및 발송을 위한 팝업
  Future<void> _showReplyDialog(BuildContext context, String docId, String email, String message, String? existingReply) {
    final TextEditingController replyController = TextEditingController(text: existingReply);
    bool isLoading = false;
    String? errorMessage;

    // 이미 답변 완료된 건지 확인 (이메일이 없으면 답변 불가)
    bool canReply = email != '익명' && existingReply == null;

    return showDialog(
      context: context,
      builder: (context) {
        // [중요] Dialog는 자체적인 State를 가지므로 StatefulBuilder 사용
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('답변하기 ($email)'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('원문:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(message),
                    const Divider(height: 30),
                    const Text('답변 작성:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: replyController,
                      maxLines: 8,
                      readOnly: !canReply, // 답변 불가/완료 시 읽기 전용
                      decoration: InputDecoration(
                        hintText: canReply ? '답변을 입력하세요...' : (email == '익명' ? '이메일 주소가 없어 답변할 수 없습니다.' : '이미 답변 완료됨.'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                      )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('닫기'),
                ),
                // 답변 가능한 경우에만 '전송' 버튼 활성화
                if (canReply)
                  ElevatedButton(
                    onPressed: isLoading ? null : () async {
                      if (replyController.text.length < 10) {
                        setDialogState(() {
                          errorMessage = "답변을 10자 이상 입력하세요.";
                        });
                        return;
                      }

                      setDialogState(() {
                        isLoading = true;
                        errorMessage = null;
                      });

                      try {
                        // Cloud Function('sendReplyEmail') 호출
                        await _sendReplyFunction.call({
                          'docId': docId,
                          'replyMessage': replyController.text,
                        });

                        // 성공 시 다이얼로그 닫기
                        if (mounted) Navigator.of(context).pop();

                      } catch (e) {
                        setDialogState(() {
                          isLoading = false;
                          errorMessage = "발송 실패: ${e.toString()}";
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white,)
                        : const Text('답변 전송', style: TextStyle(color: Colors.white)),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}