import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import { KafkaPublisher } from '../kafka/kafka.publisher';
import { UsersService } from '../users/users.service';
import { ChatMessage } from './chat-message.entity';
import { ChatRoom } from './chat-room.entity';
import { ChatRoomMember } from './chat-room-member.entity';
import { CreateRoomDto, SendMessageDto } from './chat.dto';

const WS_CHAT_TOPIC = 'messenger-ws.chat-messages';
const CHAT_ROOM_TOPIC = 'messenger.chat-room';

@Injectable()
export class ChatService {
  constructor(
    @InjectRepository(ChatRoom) private readonly rooms: Repository<ChatRoom>,
    @InjectRepository(ChatRoomMember)
    private readonly members: Repository<ChatRoomMember>,
    @InjectRepository(ChatMessage)
    private readonly messageRepo: Repository<ChatMessage>,
    private readonly users: UsersService,
    private readonly kafka: KafkaPublisher,
  ) {}

  async createRoom(
    owner: { userId: string; alias: string },
    dto: CreateRoomDto,
  ) {
    const participantIds = Array.from(
      new Set([owner.userId, ...dto.participantIds]),
    );
    const people = await this.users.findByIds(participantIds);
    if (people.length !== participantIds.length) {
      throw new NotFoundException('One or more participants not found');
    }

    // 1:1 — reuse existing direct room so both sides share one chatRoomId (CMF join).
    if (participantIds.length === 2) {
      const existingId = await this.findExistingDirectRoomId(participantIds);
      if (existingId) {
        return { data: await this.toRoomDto(existingId, owner.userId) };
      }
    }

    const others = people.filter((p) => p.id !== owner.userId);
    const name =
      dto.name?.trim() ||
      (others.length === 1
        ? others[0].displayName
        : others.map((o) => o.displayName).join(', '));

    const room = await this.rooms.save(
      this.rooms.create({
        name,
        type: participantIds.length > 2 ? 'group' : 'direct',
        ownerId: owner.userId,
      }),
    );

    await this.members.save(
      participantIds.map((userId) =>
        this.members.create({ roomId: room.id, userId }),
      ),
    );

    await this.kafka.publish(CHAT_ROOM_TOPIC, {
      chatRoomId: room.id,
      type: room.type,
      name: room.name,
      participantIds,
      createdAt: Date.now(),
    });

    return { data: await this.toRoomDto(room.id, owner.userId) };
  }

  /** Exact member-set match for a direct (2-person) room. */
  private async findExistingDirectRoomId(
    participantIds: string[],
  ): Promise<string | null> {
    if (participantIds.length !== 2) return null;
    const [a, b] = participantIds;
    const memberships = await this.members.find({
      where: [{ userId: a }, { userId: b }],
    });
    const byRoom = new Map<string, Set<string>>();
    for (const m of memberships) {
      const set = byRoom.get(m.roomId) ?? new Set<string>();
      set.add(m.userId);
      byRoom.set(m.roomId, set);
    }
    const wanted = new Set(participantIds);
    for (const [roomId, members] of byRoom) {
      if (members.size !== 2) continue;
      if (![...wanted].every((id) => members.has(id))) continue;
      const room = await this.rooms.findOne({ where: { id: roomId } });
      if (room && room.type === 'direct') return roomId;
    }
    return null;
  }

  async myRooms(userId: string) {
    const memberships = await this.members.find({ where: { userId } });
    const roomIds = memberships.map((m) => m.roomId);
    if (roomIds.length === 0) return { data: [] as unknown[] };
    const rooms = await this.rooms.find({
      where: { id: In(roomIds) },
      order: { updatedAt: 'DESC' },
    });
    const data = [];
    for (const room of rooms) {
      data.push(await this.toRoomDto(room.id, userId));
    }
    return { data };
  }

  async listMessages(userId: string, roomId: string) {
    await this.assertMember(userId, roomId);
    const rows = await this.messageRepo.find({
      where: { roomId },
      order: { createdAt: 'ASC' },
    });
    return {
      data: rows.map((m) => ({
        id: m.id,
        chatRoomId: m.roomId,
        createDt: m.createdAt.toISOString(),
        updateDt: m.createdAt.toISOString(),
        sentAt: m.createdAt.toISOString(),
        messageContent: {
          content: m.content,
          from: m.senderAlias,
          to: roomId,
          sentTimestamp: Number(m.sentTimestamp),
          messageId: m.id,
          chatRoomId: roomId,
        },
      })),
    };
  }

  async sendMessage(
    sender: { userId: string; alias: string },
    roomId: string,
    dto: SendMessageDto,
  ) {
    await this.assertMember(sender.userId, roomId);
    const content = dto.content.trim();
    if (!content) throw new ForbiddenException('Empty message');

    const sentTimestamp = Date.now();
    const saved = await this.messageRepo.save(
      this.messageRepo.create({
        roomId,
        senderUserId: sender.userId,
        senderAlias: sender.alias,
        content,
        sentTimestamp: String(sentTimestamp),
      }),
    );

    await this.rooms.update(roomId, {
      lastMessagePreview: content.slice(0, 140),
      lastMessageAt: new Date(sentTimestamp),
      updatedAt: new Date(),
    });

    const event = {
      chatRoomId: roomId,
      messageId: saved.id,
      from: sender.alias,
      to: roomId,
      content,
      sentTimestamp,
    };
    await this.kafka.publish(WS_CHAT_TOPIC, event);

    return { data: event };
  }

  private async assertMember(userId: string, roomId: string) {
    const member = await this.members.findOne({ where: { roomId, userId } });
    if (!member) throw new ForbiddenException('Not a member of this room');
  }

  private async toRoomDto(roomId: string, viewerId: string) {
    const room = await this.rooms.findOne({ where: { id: roomId } });
    if (!room) throw new NotFoundException('Room not found');
    const memberships = await this.members.find({ where: { roomId } });
    const people = await this.users.findByIds(memberships.map((m) => m.userId));
    return {
      id: room.id,
      name: room.name,
      type: room.type,
      createDt: room.createdAt.toISOString(),
      updateDt: room.updatedAt.toISOString(),
      metadata: {
        lastMessagePreview: room.lastMessagePreview,
        lastMessageAt: room.lastMessageAt?.toISOString(),
        participants: people.map((p) => ({
          alias: p.alias,
          name: p.displayName,
          iconUrl: '',
          joinedAt: memberships
            .find((m) => m.userId === p.id)
            ?.joinedAt.toISOString(),
          isOwner: p.id === room.ownerId,
          isMe: p.id === viewerId,
        })),
      },
    };
  }
}
