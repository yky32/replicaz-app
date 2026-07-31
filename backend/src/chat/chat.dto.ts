import { ArrayMinSize, IsArray, IsOptional, IsString, IsUUID } from 'class-validator';

export class CreateRoomDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsArray()
  @ArrayMinSize(1)
  @IsUUID('4', { each: true })
  participantIds!: string[];
}

export class SendMessageDto {
  @IsString()
  content!: string;
}
