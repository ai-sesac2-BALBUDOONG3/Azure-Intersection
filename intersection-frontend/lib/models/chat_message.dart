// lib/models/chat_message.dart

class ChatMessage {
  final int id;
  final int roomId;
  final int senderId;
  final String content;
  final String messageType;  // normal, system, file, image
  final bool isRead;
  final String createdAt;
  
  // ✅ 파일 업로드 관련 필드 추가
  final String? fileUrl;
  final String? fileName;
  final int? fileSize;
  final String? fileType;

  ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderId,
    required this.content,
    this.messageType = "normal",
    required this.isRead,
    required this.createdAt,
    this.fileUrl,
    this.fileName,
    this.fileSize,
    this.fileType,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'],
      roomId: json['room_id'],
      senderId: json['sender_id'],
      content: json['content'],
      messageType: json['message_type'] ?? "normal",
      isRead: json['is_read'] ?? false,
      createdAt: json['created_at'],
      fileUrl: json['file_url'],
      fileName: json['file_name'],
      fileSize: json['file_size'],
      fileType: json['file_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'sender_id': senderId,
      'content': content,
      'message_type': messageType,
      'is_read': isRead,
      'created_at': createdAt,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size': fileSize,
      'file_type': fileType,
    };
  }
  
  // ✅ 헬퍼 메서드
  bool get isFile => messageType == 'file' || messageType == 'image';
  bool get isImage => messageType == 'image';
  bool get isNormalMessage => messageType == 'normal';
  bool get isSystemMessage => messageType == 'system';
  
  // ✅ 파일 크기를 읽기 쉬운 형식으로 변환
  String get fileSizeFormatted {
    if (fileSize == null) return '';
    final bytes = fileSize!;
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
  
  // ✅ 파일 확장자 추출
  String get fileExtension {
    if (fileName == null) return '';
    final parts = fileName!.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : '';
  }
}