import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // Configure CORS for Flutter Web & Mobile Clients
  app.enableCors({
    origin: '*',
    methods: 'GET,HEAD,PUT,PATCH,POST,DELETE,OPTIONS',
    credentials: true,
  });

  // Global Prefix for REST API
  app.setGlobalPrefix('api/v1');

  // Global Validation Pipe for DTO sanitation
  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      transform: true,
      forbidNonWhitelisted: true,
    }),
  );

  const port = process.env.PORT || 3000;
  await app.listen(port);
  logger.log(`🚀 Digital Ekub REST API Server is running on: http://localhost:${port}/api/v1`);
  logger.log(`🏥 Health Check Endpoint available at: http://localhost:${port}/api/v1/health`);
}

bootstrap();
