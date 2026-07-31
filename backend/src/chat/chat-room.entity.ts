import {
  Column,
  CreateDateColumn,
  Entity,
  OneToMany,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { ChatRoomMember } from './chat-room-member.entity';

@Entity('chat_rooms')
export class ChatRoom {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  name!: string;

  @Column({ default: 'direct' })
  type!: string;

  @Column()
  ownerId!: string;

  @Column({ type: 'text', nullable: true })
  lastMessagePreview!: string | null;

  @Column({ type: 'timestamptz', nullable: true })
  lastMessageAt!: Date | null;

  @OneToMany(() => ChatRoomMember, (m) => m.room, { cascade: true })
  members!: ChatRoomMember[];

  @CreateDateColumn()
  createdAt!: Date;

  @UpdateDateColumn()
  updatedAt!: Date;
}
