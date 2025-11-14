import 'package:flutter/material.dart';
// [추가] Firestore 패키지
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart'; // kPrimaryColor 사용을 위해

class ContactDialog extends StatefulWidget {
  const ContactDialog({super.key});

  @override
  State<ContactDialog> createState() => _ContactDialogState();
}

class _ContactDialogState extends State<ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // [수정] Cloud Function 호출 -> Firestore에 저장
  Future<void> _saveInquiry() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 'inquiries' 컬렉션에 데이터 추가
      await FirebaseFirestore.instance.collection('inquiries').add({
        'replyToEmail': _emailController.text.trim().isEmpty
            ? null // 이메일 안 썼으면 null
            : _emailController.text.trim(),
        'message': _messageController.text.trim(),
        'status': 'Pending', // 'Pending', 'Completed'
        'createdAt': FieldValue.serverTimestamp(), // 서버 시간 기준 생성
        'replyMessage': null, // 관리자 답변 (초기값 null)
      });

      // 성공
      setState(() {
        _isLoading = false;
        _isSent = true;
      });

    } catch (e) {
      // 실패
      setState(() {
        _isLoading = false;
        _errorMessage = "전송에 실패했습니다. 잠시 후 다시 시도해주세요. (오류: ${e.toString()})";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSent) {
      return AlertDialog(
        backgroundColor: Colors.white,
        title: Text('전송 완료!',style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold,fontSize: 16),),
        content: Text('소중한 의견 감사합니다. 빠른 시일 내에 확인하겠습니다.',style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(), // 팝업 닫기
            child: Text('닫기',style: Theme.of(context).textTheme.titleSmall?.copyWith(color: kPrimaryColor, fontSize: 12),),
          ),
        ],
      );
    }

    return AlertDialog(
      buttonPadding: EdgeInsets.zero,
      title: Text('캠프에 문의하기',style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold,fontSize: 16),),
      backgroundColor: Colors.white,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 400,
                child: Text(
                  '여러분의 소중한 의견을 보내주세요. \n답변이 필요한 경우, 회신받을 이메일 주소를 남겨주세요.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                scrollPadding: EdgeInsets.zero,
                cursorHeight: 11.3,
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  labelText: '답변받을 이메일',
                  // hintText: 'example@email.com',
                  border: OutlineInputBorder(),
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // 선택 사항이므로 비어있어도 OK
                  }
                  if (!RegExp(r'\S+@\S+\.\S+').hasMatch(value)) {
                    return '올바른 이메일 형식이 아닙니다.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                style: Theme.of(context).textTheme.bodyMedium,
                controller: _messageController,
                cursorHeight: 11.3,
                scrollPadding: EdgeInsets.zero,
                decoration: InputDecoration(
                  labelText: '문의 내용 (필수)',
                  labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '문의 내용을 입력해주세요.';
                  }
                  if (value.length < 10) {
                    return '최소 10자 이상 입력해주세요.';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('취소',style: Theme.of(context).textTheme.titleSmall?.copyWith(color: kPrimaryColor, fontSize: 12),),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveInquiry, // [수정]
          style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor, fixedSize: Size(70, 30),padding: EdgeInsets.zero),
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
              : Text('보내기', style:Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.white,fontSize: 12),),
        ),
      ],
    );
  }
}