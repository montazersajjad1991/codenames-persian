const express = require('express');
const http = require('http');
const fs = require('fs');
const path = require('path');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

const DATA_FILE = path.join(__dirname, 'data.json');

let db = { profiles: {}, friends: {}, recent: {} };
try {
  if (fs.existsSync(DATA_FILE)) db = JSON.parse(fs.readFileSync(DATA_FILE, 'utf8'));
} catch (e) {}
function saveDb() { try { fs.writeFileSync(DATA_FILE, JSON.stringify(db)); } catch (e) {} }

const online = new Map();
const socketToUser = new Map();
const rooms = new Map();

function userRoom(userId) {
  for (const r of rooms.values()) if (r.players.includes(userId)) return r;
  return null;
}
function roomList() {
  return [...rooms.values()]
    .filter(r => r.players.length < 4)
    .map(r => ({ code: r.code, roomName: r.name, players: r.players.length, inGame: !!r.inGame }));
}
function broadcastRooms() { io.emit('room_list', roomList()); }
function friendsOf(userId) {
  return (db.friends[userId] || []).map(fid => ({
    id: fid,
    name: db.profiles[fid] ? db.profiles[fid].name : '?',
    online: online.has(fid),
  }));
}
function emitFriends(userId) {
  const u = online.get(userId);
  if (u) io.to(u.socketId).emit('friends', friendsOf(userId));
}
function recentsOf(userId) {
  const rec = db.recent[userId] || {};
  return Object.entries(rec).map(([id, v]) => ({ id, name: v.name, games: v.games, online: online.has(id) }));
}
function playersPayload(room) {
  return room.players.map(id => ({ id, name: online.get(id) ? online.get(id).name : '?' }));
}
function migrateHost(room, leftId) {
  if (room.host === leftId && room.players.length > 0) {
    room.host = room.players[0];
    io.to(room.code).emit('host_changed', { hostId: room.host });
  }
}
function removePlayer(room, userId) {
  room.players = room.players.filter(id => id !== userId);
  const u = online.get(userId);
  if (u) io.to(u.socketId).emit('left_room');
  if (!room.players.length) {
    rooms.delete(room.code);
  } else {
    migrateHost(room, userId);
    if (room.inGame) {
      // توقف بازی؛ برگشت همه به لابی تا جوین شدن نفر جدید
      room.inGame = false;
      room.board = null;
      room.state = null;
      room.assignments = null;
      io.to(room.code).emit('game_aborted', { leftId: userId });
    }
    io.to(room.code).emit('player_left', { id: userId });
    io.to(room.code).emit('players', playersPayload(room));
  }
  broadcastRooms();
}

io.on('connection', (socket) => {
  socket.on('register', ({ userId, name }) => {
    if (!userId || !name) return;
    socketToUser.set(socket.id, userId);
    online.set(userId, { socketId: socket.id, name });
    db.profiles[userId] = { name, lastSeen: Date.now() };
    saveDb();
    socket.emit('friends', friendsOf(userId));
    socket.emit('recent_players', recentsOf(userId));
    broadcastRooms();
  });

  socket.on('search_user', (data, ack) => {
    const q = (data.query || '').trim().toLowerCase();
    const results = Object.entries(db.profiles)
      .filter(([id, p]) => q.length > 0 && (p.name.toLowerCase().includes(q) || id.toLowerCase().includes(q)))
      .slice(0, 10)
      .map(([id, p]) => ({ id, name: p.name, online: online.has(id) }));
    if (typeof ack === 'function') ack({ results });
  });

  socket.on('add_friend', ({ friendId }) => {
    const me = socketToUser.get(socket.id);
    if (!me || !friendId || friendId === me) return;
    db.friends[me] = db.friends[me] || [];
    if (!db.friends[me].includes(friendId)) db.friends[me].push(friendId);
    saveDb();
    emitFriends(me);
  });

  socket.on('remove_friend', ({ friendId }) => {
    const me = socketToUser.get(socket.id);
    if (!me) return;
    db.friends[me] = (db.friends[me] || []).filter(f => f !== friendId);
    saveDb();
    emitFriends(me);
  });

  socket.on('list_rooms', (data, ack) => {
    if (typeof ack === 'function') ack({ rooms: roomList() });
  });

  socket.on('create_room', (data, ack) => {
    const me = socketToUser.get(socket.id);
    if (!me) return;
    const existing = userRoom(me);
    if (existing) { if (ack) ack({ code: existing.code }); return; }
    let code;
    do { code = String(Math.floor(10000 + Math.random() * 90000)); } while (rooms.has(code));
    const name = online.get(me) ? online.get(me).name : 'Player';
    const room = { code, name: code, isPublic: !!data.isPublic, players: [me], host: me, inGame: false };
    rooms.set(code, room);
    socket.join(code);
    io.to(code).emit('players', playersPayload(room));
    broadcastRooms();
    if (ack) ack({ code });
  });

  socket.on('join_room', (data, ack) => {
    const me = socketToUser.get(socket.id);
    if (!me) return;
    const room = rooms.get(String(data.code || '').trim());
    if (!room) { if (ack) ack({ error: 'Room not found!' }); return; }
    if (room.players.length >= 4) { if (ack) ack({ error: 'Room full!' }); return; }
    if (!room.players.includes(me)) room.players.push(me);
    socket.join(room.code);
    // اگه بازی در جریانه، صندلی خالی به تازه‌وارد بده
    if (room.inGame && room.assignments) {
      const seat = room.assignments.find(a => !room.players.includes(a.id));
      if (seat) {
        seat.id = me;
        socket.emit('setup', { assignments: room.assignments, maxHands: room.maxHands || 3 });
      }
    }
    io.to(room.code).emit('players', playersPayload(room));
    broadcastRooms();
    if (ack) ack({ code: room.code });
  });

  socket.on('leave', () => {
    const me = socketToUser.get(socket.id);
    if (!me) return;
    const room = userRoom(me);
    if (room) removePlayer(room, me);
  });

  socket.on('setup', (data) => {
    const me = socketToUser.get(socket.id);
    const room = me ? userRoom(me) : null;
    if (!room) return;
    room.inGame = true;
    room.assignments = (data.assignments || []).map(a => ({ id: a.id, team: a.team, role: a.role }));
    room.maxHands = data.maxHands || 3;
    const ids = (data.assignments || []).map(a => a.id);
    for (const a of ids) {
      for (const b of ids) {
        if (a === b) continue;
        db.recent[a] = db.recent[a] || {};
        const entry = db.recent[a][b] || { games: 0, name: online.get(b) ? online.get(b).name : '?' };
        entry.games += 1;
        if (online.get(b)) entry.name = online.get(b).name;
        db.recent[a][b] = entry;
      }
    }
    saveDb();
    for (const id of ids) {
      const u = online.get(id);
      if (u) io.to(u.socketId).emit('recent_players', recentsOf(id));
    }
    io.to(room.code).emit('setup', data);
    broadcastRooms();
  });

  socket.on('board', (data) => {
    const me = socketToUser.get(socket.id);
    const room = me ? userRoom(me) : null;
    if (!room) return;
    room.board = data;
    socket.to(room.code).emit('board', data);
  });

  socket.on('state', (data) => {
    const me = socketToUser.get(socket.id);
    const room = me ? userRoom(me) : null;
    if (!room) return;
    room.state = data;
    socket.to(room.code).emit('state', data);
  });

  socket.on('resync', (data) => {
    const room = rooms.get(String((data && data.room) || ''));
    if (!room) return;
    socket.join(room.code);
    if (room.board) socket.emit('board', room.board);
    if (room.state) socket.emit('state', room.state);
  });

  socket.on('rejoin', ({ room: code }) => {
    const me = socketToUser.get(socket.id);
    const room = rooms.get(code);
    if (!room || !me) return;
    socket.join(code);
    io.to(code).emit('players', playersPayload(room));
  });

  socket.on('disconnect', () => {
    const me = socketToUser.get(socket.id);
    socketToUser.delete(socket.id);
    if (!me) return;
    online.delete(me);
    setTimeout(() => {
      if (!online.has(me)) {
        const room = userRoom(me);
        if (room) removePlayer(room, me);
      }
    }, 30000);
    broadcastRooms();
  });
});

const PORT = process.env.PORT || 3000;
server.listen(PORT, () => console.log('Codenames server running on http://localhost:' + PORT));