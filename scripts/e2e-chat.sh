#!/usr/bin/env bash
# P0 automated smoke: shared room + REST send + CMF WS receive + history.
# Requires: messenger :9010, CMF :8088, seed users. Run from repo root or any cwd.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
CMF_DIR="${CMF_DIR:-$ROOT/../cmf}"
API_HOST="${API_HOST:-http://127.0.0.1:9010}"
CMF_WS="${CMF_WS:-ws://127.0.0.1:8088}"

if [[ ! -d "$CMF_DIR/node_modules/ws" ]]; then
  echo "Install CMF deps first: cd $CMF_DIR && npm install" >&2
  exit 1
fi

cd "$CMF_DIR"
node << NODE
const WebSocket = require('ws');
const API = process.env.API_HOST || '$API_HOST';
const WS = process.env.CMF_WS || '$CMF_WS';

async function login(email) {
  const r = await fetch(API + '/msgr/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password: 'password' }),
  });
  if (!r.ok) throw new Error('login failed ' + email + ' ' + r.status);
  return r.json();
}

async function createRoom(tok, participantId) {
  const r = await fetch(API + '/msgr/chat/my-rooms', {
    method: 'POST',
    headers: { Authorization: 'Bearer ' + tok, 'Content-Type': 'application/json' },
    body: JSON.stringify({ participantIds: [participantId] }),
  });
  if (!r.ok) throw new Error('create room ' + r.status);
  return r.json();
}

async function main() {
  const alice = await login('alice@replicaz.local');
  const bob = await login('bob@replicaz.local');
  const at = alice.data.accessToken;
  const bt = bob.data.accessToken;
  const aid = alice.data.user.id;
  const bid = bob.data.user.id;

  const r1 = await createRoom(at, bid);
  const r2 = await createRoom(bt, aid);
  const room = r1.data.id;
  if (room !== r2.data.id) {
    console.error('FAIL same_room', room, r2.data.id);
    process.exit(1);
  }
  console.log('OK same_room', room);

  const msgBody = 'e2e-p0-' + Date.now();
  let got = false;

  await new Promise((resolve, reject) => {
    const ws = new WebSocket(WS);
    const t = setTimeout(() => {
      ws.close();
      resolve();
    }, 10000);

    ws.on('open', () => {
      ws.send(JSON.stringify({ type: 'join-chat-room', chatRoomId: room }));
      setTimeout(async () => {
        const sendRes = await fetch(API + '/msgr/chat/rooms/' + room + '/messages', {
          method: 'POST',
          headers: { Authorization: 'Bearer ' + at, 'Content-Type': 'application/json' },
          body: JSON.stringify({ content: msgBody }),
        });
        if (!sendRes.ok) {
          clearTimeout(t);
          reject(new Error('send ' + sendRes.status));
          return;
        }
        console.log('OK send', sendRes.status);
      }, 600);
    });

    ws.on('message', (buf) => {
      try {
        const data = JSON.parse(buf.toString());
        const content = data.content || data.message || '';
        if (data.type === 'chat-room-message-received' && content === msgBody) {
          got = true;
          clearTimeout(t);
          ws.close();
          resolve();
        }
      } catch (_) {}
    });
    ws.on('error', reject);
  });

  if (!got) {
    console.error('FAIL ws_receive');
    process.exit(1);
  }
  console.log('OK ws_receive');

  const hist = async (tok) => {
    const r = await fetch(API + '/msgr/chat/my-rooms/' + room + '/messages', {
      headers: { Authorization: 'Bearer ' + tok },
    });
    return r.json();
  };
  const ha = await hist(at);
  const hb = await hist(bt);
  const ba = (ha.data || []).map((m) => m.messageContent && m.messageContent.content);
  const bb = (hb.data || []).map((m) => m.messageContent && m.messageContent.content);
  if (!ba.includes(msgBody) || !bb.includes(msgBody)) {
    console.error('FAIL history', ba, bb);
    process.exit(1);
  }
  console.log('OK history both sides');
  console.log('P0 e2e PASS');
}

main().catch((e) => {
  console.error('FAIL', e);
  process.exit(1);
});
NODE
