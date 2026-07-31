import { Module, Global } from '@nestjs/common';
import { KafkaPublisher } from './kafka.publisher';

@Global()
@Module({
  providers: [KafkaPublisher],
  exports: [KafkaPublisher],
})
export class KafkaModule {}
