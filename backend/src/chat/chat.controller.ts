import {
  Body,
  Controller,
  Get,
  Param,
  Post,
  UseGuards,
} from '@nestjs/common';
import { CurrentUser } from '../auth/current-user.decorator';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { ChatService } from './chat.service';
import { CreateRoomDto, SendMessageDto } from './chat.dto';

@Controller('chat')
@UseGuards(JwtAuthGuard)
export class ChatController {
  constructor(private readonly chat: ChatService) {}

  @Get('my-rooms')
  myRooms(@CurrentUser() user: { userId: string }) {
    return this.chat.myRooms(user.userId);
  }

  @Post('my-rooms')
  createRoom(
    @CurrentUser() user: { userId: string; alias: string },
    @Body() dto: CreateRoomDto,
  ) {
    return this.chat.createRoom(user, dto);
  }

  @Get('my-rooms/:id/messages')
  messages(
    @CurrentUser() user: { userId: string },
    @Param('id') id: string,
  ) {
    return this.chat.listMessages(user.userId, id);
  }

  @Post('rooms/:id/messages')
  send(
    @CurrentUser() user: { userId: string; alias: string },
    @Param('id') id: string,
    @Body() dto: SendMessageDto,
  ) {
    return this.chat.sendMessage(user, id, dto);
  }
}
