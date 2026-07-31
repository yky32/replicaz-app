import { Controller, Get, UseGuards } from '@nestjs/common';
import { UsersService } from './users.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

@Controller('users')
@UseGuards(JwtAuthGuard)
export class UsersController {
  constructor(private readonly users: UsersService) {}

  @Get()
  async list(@CurrentUser() user: { userId: string }) {
    const others = await this.users.listOthers(user.userId);
    return { data: others.map((u) => this.users.toPublic(u)) };
  }

  @Get('me')
  async me(@CurrentUser() user: { userId: string }) {
    const me = await this.users.findById(user.userId);
    return { data: me ? this.users.toPublic(me) : null };
  }
}
