import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { UsersModule } from '../users/users.module';
import { ChatRoom } from './chat-room.entity';
import { ChatRoomMember } from './chat-room-member.entity';
import { ChatMessage } from './chat-message.entity';
import { ChatService } from './chat.service';
import { ChatController } from './chat.controller';

@Module({
  imports: [
    TypeOrmModule.forFeature([ChatRoom, ChatRoomMember, ChatMessage]),
    UsersModule,
  ],
  providers: [ChatService],
  controllers: [ChatController],
})
export class ChatModule {}
