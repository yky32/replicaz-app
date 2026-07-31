import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
} from 'typeorm';

@Entity('chat_messages')
export class ChatMessage {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  roomId!: string;

  @Column()
  senderUserId!: string;

  @Column()
  senderAlias!: string;

  @Column({ type: 'text' })
  content!: string;

  @Column({ type: 'bigint' })
  sentTimestamp!: string;

  @CreateDateColumn()
  createdAt!: Date;
}
