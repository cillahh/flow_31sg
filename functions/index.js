// 1. dotenv 라이브러리를 맨 위에 추가합니다.
require("dotenv").config();

// Firebase Functions 및 Admin SDK
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

// SendGrid Mail SDK
const sgMail = require("@sendgrid/mail");

// 2. process.env에서 API 키를 읽어옵니다.
const SENDGRID_API_KEY = process.env.SENDGRID_API_KEY;
sgMail.setApiKey(SENDGRID_API_KEY);

// [필수] SendGrid에 등록된 "보내는 사람" 이메일 주소
const SENDER_EMAIL = "flow.31sg@gmail.com"; // 캠프 공식 메일

/**
 * [수정] Firebase Functions v4+ 문법으로 변경
 */
exports.sendReplyEmail = functions.https.onCall(
  { region: "asia-northeast3" }, // 지역 설정
  async (request) => { // [수정] (data, context) -> (request)

    // [보안 TODO]
    // 현재는 누구나 이 함수를 호출할 수 있습니다.
    // 실제 운영 시에는 request.auth.uid를 확인하여
    // 관리자인지 확인하는 로직이 '반드시' 필요합니다.
    /*
    if (!request.auth || request.auth.token.email !== "admin@flow.com") {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "관리자만 이 기능을 사용할 수 있습니다."
      );
    }
    */

    // [수정] data -> request.data
    const { docId, replyMessage } = request.data;

    if (!docId || !replyMessage) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "문서 ID와 답변 메시지가 필요합니다." // <- 이 오류가 발생했었습니다.
      );
    }

    // 1. Firestore에서 원본 문의내역 가져오기
    const inquiryRef = admin.firestore().collection("inquiries").doc(docId);
    const doc = await inquiryRef.get();

    if (!doc.exists) {
      throw new functions.https.HttpsError("not-found", "해당 문의를 찾을 수 없습니다.");
    }

    const inquiryData = doc.data();
    const visitorEmail = inquiryData.replyToEmail;
    const originalMessage = inquiryData.message;

    if (!visitorEmail) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "방문자가 이메일 주소를 남기지 않아 답변할 수 없습니다."
      );
    }

    if (inquiryData.status === "Completed") {
         throw new functions.https.HttpsError(
        "failed-precondition",
        "이미 답변이 완료된 문의입니다."
      );
    }

    // 2. SendGrid로 보낼 답변 이메일 구성
    const msg = {
      to: visitorEmail, // (A) 방문자 이메일
      from: {
        name: "FLOW", // 보내는 사람 이름
        email: SENDER_EMAIL,  // (B) SendGrid 인증된 이메일
      },
      subject: `[FLOW 선거캠프] 문의하신 내용에 대한 답변입니다.`,
      // 이메일 본문 (HTML)
      html: `
      <p>안녕하세요. 제31대 총학생회 선거캠프 'FLOW' 선거운동본부장 천국인입니다.</p>
        <p>우선 저희 FLOW에 관심을 가지고 문의해주셔서 감사합니다.</p>
        <p>문의하신 내용에 대해 다음과 같이 답변드립니다.</p>
        <br>
        <div style="background-color: #f4f4f4; padding: 15px; border-radius: 5px;">
                  <strong>문의:</strong>
                  <p>${originalMessage.replace(/\n/g, "<br>")}</p>
                </div>
        <br>
        <div style="background-color: #f4f4f4; padding: 15px; border-radius: 5px;">
          <strong>답변:</strong>
          <p>${replyMessage.replace(/\n/g, "<br>")}</p>
        </div>
      `,
    };

    // 3. 이메일 발송
    try {
      await sgMail.send(msg);

      // 4. 발송 성공 시, Firestore 문서 상태 업데이트
      await inquiryRef.update({
        status: "Completed",
        replyMessage: replyMessage,
        repliedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, message: "답변이 성공적으로 발송되었습니다." };

    } catch (error) {
      console.error("SendGrid 발송 오류:", error);
      if (error.response) console.error(error.response.body);
      throw new functions.https.HttpsError(
        "internal",
        "SendGrid API 오류로 인해 메일 발송에 실패했습니다."
      );
    }
  }
);