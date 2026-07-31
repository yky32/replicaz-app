import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { In, Repository } from 'typeorm';
import * as bcrypt from 'bcryptjs';
import { User } from './user.entity';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private readonly users: Repository<User>,
  ) {}

  findByEmail(email: string) {
    return this.users.findOne({ where: { email: email.toLowerCase() } });
  }

  findById(id: string) {
    return this.users.findOne({ where: { id } });
  }

  async create(input: {
    email: string;
    password: string;
    displayName: string;
  }) {
    const email = input.email.trim().toLowerCase();
    const alias = input.displayName.trim() || email.split('@')[0];
    const user = this.users.create({
      email,
      displayName: alias,
      alias,
      passwordHash: await bcrypt.hash(input.password, 10),
    });
    return this.users.save(user);
  }

  async validatePassword(user: User, password: string) {
    return bcrypt.compare(password, user.passwordHash);
  }

  findByIds(ids: string[]) {
    if (ids.length === 0) return Promise.resolve([] as User[]);
    return this.users.find({ where: { id: In(ids) } });
  }

  async listOthers(excludeUserId: string) {
    return this.users
      .createQueryBuilder('u')
      .where('u.id != :id', { id: excludeUserId })
      .orderBy('u.displayName', 'ASC')
      .getMany();
  }

  async seedDemoUsers() {
    const demos = [
      { email: 'alice@replicaz.local', password: 'password', displayName: 'Alice' },
      { email: 'bob@replicaz.local', password: 'password', displayName: 'Bob' },
    ];
    for (const demo of demos) {
      const existing = await this.findByEmail(demo.email);
      if (!existing) {
        await this.create(demo);
        console.log(`Seeded demo user ${demo.email}`);
      }
    }
  }

  toPublic(user: User) {
    return {
      id: user.id,
      email: user.email,
      displayName: user.displayName,
      alias: user.alias,
    };
  }
}
