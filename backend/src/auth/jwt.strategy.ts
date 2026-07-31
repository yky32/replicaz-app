import { Injectable } from '@nestjs/common';
import { PassportStrategy } from '@nestjs/passport';
import { ExtractJwt, Strategy } from 'passport-jwt';

@Injectable()
export class JwtStrategy extends PassportStrategy(Strategy) {
  constructor() {
    super({
      jwtFromRequest: ExtractJwt.fromAuthHeaderAsBearerToken(),
      ignoreExpiration: false,
      secretOrKey: process.env.JWT_SECRET || 'replicaz-local-dev-secret',
    });
  }

  validate(payload: { sub: string; email: string; alias: string }) {
    return {
      userId: payload.sub,
      email: payload.email,
      alias: payload.alias,
    };
  }
}
