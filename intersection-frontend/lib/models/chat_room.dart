class ChatRoom {
  final int id;
  final int user1Id;
  final int user2Id;
  final int friendId;        // 상대방 ID
  final String? friendName;  // 상대방 이름
  final String? lastMessage;
  final String? lastMessageTime;
  final int unreadCount;
  final String createdAt;

  ChatRoom({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.friendId,
    this.friendName,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    required this.createdAt,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      friendId: json['friend_id'],
      friendName: json['friend_name'],
      lastMessage: json['last_message'],
      lastMessageTime: json['last_message_time'],
      unreadCount: json['unread_count'] ?? 0,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'friend_id': friendId,
      'friend_name': friendName,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime,
      'unread_count': unreadCount,
      'created_at': createdAt,
    };
  }
}

