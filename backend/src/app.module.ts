import { Module, OnModuleInit } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { JwtModule } from '@nestjs/jwt';
import { AuthModule } from './auth/auth.module';
import { ChatModule } from './chat/chat.module';
import { UsersModule } from './users/users.module';
import { KafkaModule } from './kafka/kafka.module';
import { User } from './users/user.entity';
import { ChatRoom } from './chat/chat-room.entity';
import { ChatRoomMember } from './chat/chat-room-member.entity';
import { ChatMessage } from './chat/chat-message.entity';
import { UsersService } from './users/users.service';

@Module({
  imports: [
    TypeOrmModule.forRoot({
      type: 'postgres',
      host: process.env.DB_HOST || 'localhost',
      port: Number(process.env.DB_PORT || 5436),
      username: process.env.DB_USER || 'replicaz',
      password: process.env.DB_PASSWORD || 'replicaz',
      database: process.env.DB_NAME || 'replicaz_messenger',
      entities: [User, ChatRoom, ChatRoomMember, ChatMessage],
      synchronize: true,
    }),
    JwtModule.register({
      global: true,
      secret: process.env.JWT_SECRET || 'replicaz-local-dev-secret',
      signOptions: { expiresIn: '30d' },
    }),
    KafkaModule,
    AuthModule,
    UsersModule,
    ChatModule,
  ],
})
export class AppModule implements OnModuleInit {
  constructor(private readonly users: UsersService) {}

  async onModuleInit() {
    if (process.env.SEED_DEMO_USERS === 'true') {
      await this.users.seedDemoUsers();
    }
  }
}
