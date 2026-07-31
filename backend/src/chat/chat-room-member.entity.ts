import {
  Column,
  CreateDateColumn,
  Entity,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { ChatRoom } from './chat-room.entity';

@Entity('chat_room_members')
@Unique(['roomId', 'userId'])
export class ChatRoomMember {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  roomId!: string;

  @Column()
  userId!: string;

  @ManyToOne(() => ChatRoom, (room) => room.members, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'roomId' })
  room!: ChatRoom;

  @CreateDateColumn()
  joinedAt!: Date;
}
