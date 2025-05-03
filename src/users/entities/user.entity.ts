import { BeforeInsert, Column, Entity, PrimaryColumn } from 'typeorm';
import { nanoid } from 'nanoid';

@Entity('users')
export class User {
  @PrimaryColumn()
  id: string;

  @Column()
  username: string;

  @Column()
  email: string;

  @Column()
  firstName: string;

  @Column()
  lastName: string;

  @BeforeInsert()
  generateId() {
    const date = new Date();
    this.id = `user_${nanoid()}_${date.toISOString()}`;
  }
}
