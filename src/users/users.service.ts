import { Injectable } from '@nestjs/common';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import type { Repository } from 'typeorm';
import { User } from './entities/user.entity';
import { InjectRepository } from '@nestjs/typeorm';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(User) private readonly repository: Repository<User>,
  ) {}

  create(dto: CreateUserDto) {
    const user = this.repository.create(dto);

    return this.repository.save(user);
  }

  findAll() {
    return this.repository.find();
  }

  findOne(id: string) {
    return this.repository.findOneBy({ id });
  }

  async update(id: string, dto: UpdateUserDto) {
    const user = await this.repository.findOneBy({ id });
    if (!user) return null;
    this.repository.merge(user, dto);
    return this.repository.save(user);
  }

  async remove(id: string) {
    const user = await this.repository.findOneBy({ id });
    if (!user) return null;
    return this.repository.remove(user);
  }
}
