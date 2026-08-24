const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);
const io = new Server(server, { cors: { origin: '*' } });

const rooms = {};

function makeCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  let code = '';
  for (let i = 0; i < 5; i++) {
    code += chars[Math.floor(Math.random() * chars.length)];
  }
  if (rooms[code]) return makeCode();
  return code;
}

io.on('connection', (socket) => {
  console.log('New connection:', socket.id);

  socket.on('create_room', (data, cb) => {
    const code = makeCode();
    rooms[code] = {
      players: [{ id: socket.id, name: data.name || 'بازیکن' }],
      roomName: data.roomName || 'اتاق ' + code,
      isPublic: data.isPublic !== false,
    };
    socket.join(code);
    socket.data.room = code;
    cb({ code });
    io.to(code).emit('players', rooms[code].players);
    console.log('Room created:', code, rooms[code].roomName);
  });

  socket.on('list_rooms', (data, cb) => {
    const publicRooms = Object.keys(rooms)
      .filter((c) => rooms[c].isPublic && rooms[c].players.length < 4)
      .map((c) => ({
        code: c,
        roomName: rooms[c].roomName,
        players: rooms[c].players.length,
      }));
    cb({ rooms: publicRooms });
  });

  socket.on('join_room', (data, cb) => {
    const code = (data.code || '').toUpperCase().trim();
    const room = rooms[code];
    if (!room) return cb({ error: 'اتاق پیدا نشد!' });
    if (room.players.length >= 4) return cb({ error: 'اتاق پر است!' });
    room.players.push({ id: socket.id, name: data.name || 'بازیکن' });
    socket.join(code);
    socket.data.room = code;
    cb({ code });
    io.to(code).emit('players', room.players);
    console.log('Player joined:', code, room.players.length);
  });

  ['setup', 'board', 'state'].forEach((ev) => {
    socket.on(ev, (data) => {
      const room = socket.data.room;
      if (room) socket.to(room).emit(ev, data);
    });
  });

  socket.on('disconnect', () => {
    const room = socket.data.room;
    if (room && rooms[room]) {
      io.to(room).emit('player_left', {});
      delete rooms[room];
      console.log('Room closed:', room);
    }
  });
});

server.listen(3000, () => {
  console.log('Codenames server running on http://localhost:3000');
});