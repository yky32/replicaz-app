import 'reflect-metadata';
import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  app.setGlobalPrefix('msgr');
  app.enableCors();
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
    }),
  );
  const port = Number(process.env.PORT || 9010);
  await app.listen(port, '0.0.0.0');
  console.log(`replicaz-messenger listening on :${port} (prefix /msgr)`);
}

bootstrap();
