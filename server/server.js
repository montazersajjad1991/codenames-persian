const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');

const app = express();
app.use(cors());

const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: "*", // Allows your Flutter app and web clients to connect
    methods: ["GET", "POST"]
  },
  transports: ['polling', 'websocket'] // Matches your Flutter client's fallback strategy
});

// ==========================================
// 🗄️ IN-MEMORY DATABASE (Simple & Fast)
// ==========================================
const users = new Map(); // userId -> { id, name, socketId, lastSeen, friends: [], pendingRequests: [], recentPlayers: [] }
const rooms = new Map(); // roomCode -> { code, hostId, isPublic, players: [userId], inGame: false, assignments: [], maxHands: 3, board: null, state: null }
const disconnectTimers = new Map(); // userId -> timeout (مهلت برگشت بعد از قطعی)

// ==========================================
// 🛠️ HELPER FUNCTIONS
// ==========================================
function generateRoomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  do {
    code = '';
    for (let i = 0; i < 4; i++) {
      code += chars[Math.floor(Math.random() * chars.length)];
    }
  } while (rooms.has(code));
  return code;
}

function getUser(userId) {
  if (!users.has(userId)) {
    users.set(userId, {
      id: userId,
      name: 'کاربر جدید',
      socketId: null,
      lastSeen: Date.now(),
      friends: [],
      pendingRequests: [],
      recentPlayers: []
    });
  }
  return users.get(userId);
}

function updateUserLastSeen(userId) {
  const user = getUser(userId);
  user.lastSeen = Date.now();
}

function getRoomPlayers(roomCode) {
  const room = rooms.get(roomCode);
  if (!room) return [];
  return room.players.map(id => {
    const u = getUser(id);
    return { id: u.id, name: u.name, online: u.socketId !== null };
  });
}

function broadcastRoomList() {
  const publicRooms = Array.from(rooms.values())
    .filter(r => r.isPublic)
    .map(r => ({
      code: r.code,
      roomName: `اتاق ${r.code}`,
      players: r.players.length,
      inGame: r.inGame
    }));
  io.emit('room_list', publicRooms);
}

function sendFriendsList(socket) {
  const user = users.get(socket.userId);
  if (!user) return;

  const friendsData = user.friends.map(fid => {
    const f = getUser(fid);
    return { id: f.id, name: f.name, online: f.socketId !== null, lastSeen: f.lastSeen };
  });
  socket.emit('friends', friendsData);

  const pendingData = user.pendingRequests.map(fid => {
    const f = getUser(fid);
    return { from: f.id, name: f.name, online: f.socketId !== null, lastSeen: f.lastSeen };
  });
  socket.emit('pending_requests', pendingData);
}

function sendRecentPlayers(socket) {
  const user = users.get(socket.userId);
  if (!user) return;
  const recentData = user.recentPlayers.map(rp => {
    const p = getUser(rp.id);
    return {
      id: p.id,
      name: p.name,
      online: p.socketId !== null,
      lastSeen: p.lastSeen,
      games: rp.games || 1,
      isFriend: user.friends.includes(p.id),
      pendingSent: p.pendingRequests.includes(user.id)
    };
  });
  socket.emit('recent_players', recentData);
}

// 🔧 خروج کاربر از اتاق‌ها — exceptCode یعنی این اتاق دست نخوره می‌مونه
// قانون: هر کاربر فقط عضو «یک» اتاق؛ عضویت جدید = پاک‌سازی خودکار بقیه
function removeUserFromRooms(socket, userId, exceptCode = null) {
  for (const [code, room] of rooms.entries()) {
    if (code === exceptCode || !room.players.includes(userId)) continue;
    room.players = room.players.filter(id => id !== userId);
    if (socket) {
      try { socket.leave(code); } catch (_) {}
    }
    io.to(code).emit('player_left', {});
    if (room.players.length === 0) {
      rooms.delete(code);
      broadcastRoomList();
      continue;
    }
    if (room.hostId === userId) {
      if (room.inGame) {
        io.to(code).emit('game_aborted', {});
        rooms.delete(code);
        broadcastRoomList();
        continue;
      }
      room.hostId = room.players[0]; // اولین نفر باقی‌مونده = اولین جوین‌شده
      io.to(code).emit('host_changed', { hostId: room.hostId });
    }
    io.to(code).emit('players', getRoomPlayers(code));
    broadcastRoomList();
  }
}

// ==========================================
// 🔌 SOCKET.IO CONNECTION LOGIC
// ==========================================
io.on('connection', (socket) => {
  console.log('✅ کاربر متصل شد:', socket.id);

  // 1. ثبت نام کاربر
  socket.on('register', (data) => {
    const { userId, name } = data;
    const user = getUser(userId);
    user.name = name || user.name;
    user.socketId = socket.id;
    socket.userId = userId;

    // اگه تایمر حذف از اتاق فعال بوده، لغوش کن (کاربر برگشت)
    const pendingKick = disconnectTimers.get(userId);
    if (pendingKick) {
      clearTimeout(pendingKick);
      disconnectTimers.delete(userId);
    }

    socket.join(userId); // Join personal room for direct invites/messages

    const reportedRoom = data.room || null;

    // 🔧 همگام‌سازی عضویت: فقط اتاقی که کلاینت گزارش می‌ده باقی می‌مونه
    // (اتاق ارواح و اعضای سایه همین‌جا پاک می‌شن)
    removeUserFromRooms(socket, userId, reportedRoom);

    if (reportedRoom) {
      const room = rooms.get(reportedRoom);
      if (room && room.players.includes(userId)) {
        socket.join(reportedRoom);
        if (room.hostId === userId) {
          socket.emit('host_changed', { hostId: userId });
        }
        io.to(reportedRoom).emit('players', getRoomPlayers(reportedRoom));
      } else {
        // سرور این اتاق رو نداره (مثلاً ری‌استارت شده)
        socket.emit('left_room', {});
      }
    }

    sendFriendsList(socket);
    sendRecentPlayers(socket);
    broadcastRoomList();
  });

  // 2. ساخت اتاق
  socket.on('create_room', (data, callback) => {
    const userId = socket.userId;
    if (!userId) return callback({ error: 'ثبت نام نشده' });

    // 🔧 اول از اتاق‌های قبلی خارج شو (جلوگیری از اتاق ارواح)
    removeUserFromRooms(socket, userId);

    const code = generateRoomCode();
    rooms.set(code, {
      code,
      hostId: userId,
      isPublic: data.isPublic !== false,
      players: [userId],
      inGame: false,
      assignments: [],
      maxHands: 3,
      board: null,
      state: null
    });

    socket.join(code);
    callback({ code });
    io.to(code).emit('players', getRoomPlayers(code));
    broadcastRoomList();
  });

  // 3. پیوستن به اتاق
  socket.on('join_room', (data, callback) => {
    const userId = socket.userId;
    const { code } = data;
    const room = rooms.get(code);

    if (!room) return callback({ error: 'اتاق پیدا نشد' });

    const isMember = room.players.includes(userId);
    // 🔧 عضو برگشتی مستثنیه — «اتاق پر» فقط برای تازه‌واردهاست
    if (!isMember && room.players.length >= 4) return callback({ error: 'اتاق پر است' });
    if (!isMember && room.inGame) return callback({ error: 'بازی در حال جریان است' });

    // 🔧 اول از اتاق‌های دیگه خارج شو (جلوگیری از عضویت چندگانه)
    removeUserFromRooms(socket, userId, code);

    if (!isMember) {
      room.players.push(userId);
    }

    socket.join(code);
    callback({
      code,
      isHost: room.hostId === userId,
      inGame: room.inGame,
      assignments: room.assignments || [],
      maxHands: room.maxHands || 3,
    });
    io.to(code).emit('players', getRoomPlayers(code));
    broadcastRoomList();
  });

  // 4. خروج از اتاق
  socket.on('leave', () => {
    const userId = socket.userId;
    if (!userId) return;
    removeUserFromRooms(socket, userId); // از همه‌ی اتاق‌ها خارج شو
  });

  // 5. لیست اتاق‌های عمومی
  socket.on('list_rooms', (data, callback) => {
    const publicRooms = Array.from(rooms.values())
      .filter(r => r.isPublic)
      .map(r => ({ code: r.code, roomName: `اتاق ${r.code}`, players: r.players.length, inGame: r.inGame }));
    callback({ rooms: publicRooms });
  });

  // 6. جستجوی کاربر
  socket.on('search_user', (data, callback) => {
    const { query } = data;
    if (!query) return callback({ results: [] });

    const q = query.toLowerCase();
    const results = [];
    for (const [id, user] of users.entries()) {
      if (id === socket.userId) continue;
      if (user.name.toLowerCase().includes(q) || id.toLowerCase().includes(q)) {
        const currentUser = getUser(socket.userId);
        const isFriend = currentUser.friends.includes(id);
        const pendingSent = user.pendingRequests.includes(socket.userId);
        results.push({ id: user.id, name: user.name, online: user.socketId !== null, lastSeen: user.lastSeen, isFriend, pendingSent });
      }
    }
    callback({ results });
  });

  // 7. سیستم دوستی
  socket.on('add_friend', (data) => {
    const { friendId } = data;
    const user = getUser(socket.userId);
    const friend = getUser(friendId);

    if (friendId === socket.userId) return;
    if (user.friends.includes(friendId)) {
      socket.emit('request_result', { ok: false, name: friend.name, reason: 'already' });
      return;
    }
    if (!friend.pendingRequests.includes(socket.userId)) {
      friend.pendingRequests.push(socket.userId);
      const friendSocket = io.sockets.sockets.get(friend.socketId);
      if (friendSocket) {
        friendSocket.emit('friend_request', { from: socket.userId, name: user.name });
        sendFriendsList(friendSocket);
      }
    }
    // ✅ همیشه به فرستنده خبر بده (حتی اگه گیرنده آفلاین باشه)
    socket.emit('request_result', { ok: true, name: friend.name });
    sendRecentPlayers(socket);
  });

  socket.on('remove_friend', (data) => {
    const { friendId } = data;
    const user = getUser(socket.userId);
    const friend = getUser(friendId);
    user.friends = user.friends.filter(id => id !== friendId);
    friend.friends = friend.friends.filter(id => id !== socket.userId);
    sendFriendsList(socket);
  });

  socket.on('respond_friend', (data) => {
    const { from, accept } = data;
    const user = getUser(socket.userId);
    const friend = getUser(from);

    user.pendingRequests = user.pendingRequests.filter(id => id !== from);
    sendFriendsList(socket);

    if (accept) {
      if (!user.friends.includes(from)) user.friends.push(from);
      if (!friend.friends.includes(socket.userId)) friend.friends.push(socket.userId);
      // درخواست متقابل همزمان هم پاک بشه
      friend.pendingRequests = friend.pendingRequests.filter(id => id !== socket.userId);

      const friendSocket = io.sockets.sockets.get(friend.socketId);
      if (friendSocket) {
        friendSocket.emit('friend_accepted', { name: user.name });
        sendFriendsList(friendSocket);
      }
    }

    // 🔄 لیست‌های فرستنده‌ی درخواست هم آپدیت بشه (پاک شدن «در انتظار» یا تبدیل به دوست)
    const fromSocket = io.sockets.sockets.get(friend.socketId);
    if (fromSocket) {
      sendRecentPlayers(fromSocket);
      sendFriendsList(fromSocket);
    }
  });

  socket.on('invite_friend', (data) => {
    const { friendId } = data;
    const user = getUser(socket.userId);
    let roomCode = null;
    for (const [code, room] of rooms.entries()) {
      if (room.players.includes(socket.userId)) { roomCode = code; break; }
    }
    if (roomCode) {
      const friendSocket = io.sockets.sockets.get(getUser(friendId).socketId);
      if (friendSocket) friendSocket.emit('room_invite', { code: roomCode, fromName: user.name });
    }
  });

  // 8. منطق بازی
  socket.on('setup', (data) => {
    const userId = socket.userId;
    for (const room of rooms.values()) {
      if (room.players.includes(userId) && room.hostId === userId) {
        room.assignments = data.assignments;
        room.maxHands = data.maxHands || 3;
        room.inGame = true;
        // ➕ همه اعضای اتاق از لحظه شروع بازی در لیست «بازیکنان اخیر» ثبت می‌شن
        room.players.forEach(pid => {
          const pUser = getUser(pid);
          room.players.forEach(otherId => {
            if (otherId !== pid && !pUser.recentPlayers.some(rp => rp.id === otherId)) {
              pUser.recentPlayers.push({ id: otherId, games: 1 });
            }
          });
          pUser.recentPlayers = pUser.recentPlayers.slice(-20);
          const pSocket = io.sockets.sockets.get(pUser.socketId);
          if (pSocket) sendRecentPlayers(pSocket);
        });
        io.to(room.code).emit('setup', { assignments: room.assignments, maxHands: room.maxHands });
        break;
      }
    }
  });

  socket.on('resync', (data) => {
    const { room: roomCode } = data;
    const room = rooms.get(roomCode);
    if (room && room.players.includes(socket.userId)) {
      if (room.board) socket.emit('board', room.board);
      if (room.state) socket.emit('state', room.state);
    }
  });

  socket.on('rejoin', (data) => {
    const { room: roomCode, oldId } = data;
    const userId = socket.userId;
    const room = rooms.get(roomCode);
    if (room && room.players.includes(userId)) {
      getUser(userId).socketId = socket.id;
      socket.join(roomCode);
      if (room.board) socket.emit('board', room.board);
      if (room.state) socket.emit('state', room.state);
      io.to(roomCode).emit('players', getRoomPlayers(roomCode));
    }
  });

  socket.on('state', (data) => {
    const userId = socket.userId;
    for (const room of rooms.values()) {
      if (room.players.includes(userId)) {
        const prevWinner = room.state ? room.state.winner : null;
        room.state = data;
        io.to(room.code).emit('state', data);

        // شمردن «بازی» فقط وقتی یه دست واقعاً تموم بشه (برنده اعلام بشه)
        if (data.winner && !prevWinner) {
          room.players.forEach(pid => {
            if (pid !== userId) {
              const pUser = getUser(pid);
              const existing = pUser.recentPlayers.find(rp => rp.id === userId);
              if (existing) existing.games = (existing.games || 1) + 1;
              else pUser.recentPlayers.push({ id: userId, games: 1 });
              pUser.recentPlayers = pUser.recentPlayers.slice(-20);
            }
          });
          room.players.forEach(pid => {
            const pSocket = io.sockets.sockets.get(getUser(pid).socketId);
            if (pSocket) sendRecentPlayers(pSocket);
          });
        }
        break;
      }
    }
  });

  socket.on('board', (data) => {
    const userId = socket.userId;
    for (const room of rooms.values()) {
      if (room.players.includes(userId)) {
        room.board = data;
        io.to(room.code).emit('board', data);
        break;
      }
    }
  });

  // 9. قطع اتصال
  socket.on('disconnect', () => {
    const userId = socket.userId;
    if (userId) {
      updateUserLastSeen(userId);
      const user = getUser(userId);
      user.socketId = null;

      for (const friendId of user.friends) {
        const friendSocket = io.sockets.sockets.get(getUser(friendId).socketId);
        if (friendSocket) sendFriendsList(friendSocket);
      }

      for (const [code, room] of rooms.entries()) {
        if (!room.players.includes(userId)) continue;
        io.to(code).emit('player_left', {});
        if (room.inGame) {
          if (room.hostId === userId) {
            // خروج میزبان وسط بازی = لغو بازی
            io.to(code).emit('game_aborted', {});
            rooms.delete(code);
            broadcastRoomList();
          } else {
            // بقیه فوراً ببینن که این بازیکن آفلاین شده
            io.to(code).emit('players', getRoomPlayers(code));
            if (!disconnectTimers.has(userId)) {
              // داخل بازی ۲ دقیقه مهلت rejoin، بعدش حذف واقعی
              disconnectTimers.set(userId, setTimeout(() => {
                disconnectTimers.delete(userId);
                removeUserFromRooms(null, userId);
              }, 120000));
            }
          }
        } else {
          // لابی: فوراً آفلاین نشون بده، ۳۰ ثانیه بعد حذف واقعی
          io.to(code).emit('players', getRoomPlayers(code));
          if (!disconnectTimers.has(userId)) {
            disconnectTimers.set(userId, setTimeout(() => {
              disconnectTimers.delete(userId);
              removeUserFromRooms(null, userId);
            }, 30000));
          }
        }
      }
    }
    console.log('❌ کاربر قطع شد:', socket.id);
  });
});

// ==========================================
// 🚀 START SERVER
// ==========================================
const PORT = process.env.PORT || 3000;
server.listen(PORT, () => {
  console.log(`🚀 سرور بازی اسم رمز روی پورت ${PORT} اجرا شد`);
  console.log(`🌐 آدرس اتصال: http://boarderbros.ir`);
});