import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UsersService } from '../users/users.service';
import { LoginDto, RegisterDto } from './auth.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly users: UsersService,
    private readonly jwt: JwtService,
  ) {}

  async register(dto: RegisterDto) {
    const existing = await this.users.findByEmail(dto.email);
    if (existing) throw new ConflictException('Email already registered');
    const user = await this.users.create(dto);
    return this.tokenResponse(user);
  }

  async login(dto: LoginDto) {
    const user = await this.users.findByEmail(dto.email);
    if (!user || !(await this.users.validatePassword(user, dto.password))) {
      throw new UnauthorizedException('Invalid credentials');
    }
    return this.tokenResponse(user);
  }

  private tokenResponse(user: {
    id: string;
    email: string;
    displayName: string;
    alias: string;
  }) {
    const accessToken = this.jwt.sign({
      sub: user.id,
      email: user.email,
      alias: user.alias,
    });
    return {
      data: {
        accessToken,
        user: {
          id: user.id,
          email: user.email,
          displayName: user.displayName,
          alias: user.alias,
        },
      },
    };
  }
}
