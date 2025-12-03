-- =========================================
-- 1) 채팅방: 나간 사용자 ID 컬럼 (나중에 나가기/숨기기 구현용)
-- =========================================
ALTER TABLE chatroom
  ADD COLUMN IF NOT EXISTS left_user_id integer;

-- =========================================
-- 2) 채팅 메시지: 타입 + 파일 메타데이터
--   - message_type: 'normal' | 'image' | 'file' 등
--   - file_* 컬럼은 이미지/파일 전송 시 정보 저장
-- =========================================
ALTER TABLE chatmessage
  ADD COLUMN IF NOT EXISTS message_type text NOT NULL DEFAULT 'normal',
  ADD COLUMN IF NOT EXISTS file_url text,
  ADD COLUMN IF NOT EXISTS file_name text,
  ADD COLUMN IF NOT EXISTS file_size integer,
  ADD COLUMN IF NOT EXISTS file_type text;

-- =========================================
-- 3) 사용자 차단 테이블
--   - 누가(user_id) 누구(blocked_user_id)를 차단했는지
-- =========================================
CREATE TABLE IF NOT EXISTS userblock (
    id              serial PRIMARY KEY,
    user_id         integer NOT NULL REFERENCES "user"(id),
    blocked_user_id integer NOT NULL REFERENCES "user"(id),
    created_at      timestamptz NOT NULL DEFAULT now()
);

-- =========================================
-- 4) 사용자 신고 테이블
--   - 누가(reporter_id) 누구(reported_user_id)를
--     어떤 이유(reason, content)로 신고했는지
-- =========================================
CREATE TABLE IF NOT EXISTS userreport (
    id               serial PRIMARY KEY,
    reporter_id      integer NOT NULL REFERENCES "user"(id),
    reported_user_id integer NOT NULL REFERENCES "user"(id),
    reason           text NOT NULL,
    content          text,
    created_at       timestamptz NOT NULL DEFAULT now()
);
