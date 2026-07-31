import { Injectable, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { Kafka, Producer } from 'kafkajs';

@Injectable()
export class KafkaPublisher implements OnModuleInit, OnModuleDestroy {
  private producer!: Producer;

  async onModuleInit() {
    const broker = process.env.KAFKA_BROKER || 'localhost:9092';
    const kafka = new Kafka({
      clientId: 'replicaz-messenger',
      brokers: [broker],
      retry: { retries: 8 },
    });
    this.producer = kafka.producer();
    await this.producer.connect();
    console.log(`Kafka producer connected → ${broker}`);
  }

  async onModuleDestroy() {
    await this.producer?.disconnect();
  }

  async publish(topic: string, payload: unknown) {
    await this.producer.send({
      topic,
      messages: [{ value: JSON.stringify(payload) }],
    });
  }
}
