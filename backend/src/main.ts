import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { AppModule } from './app.module';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule);

  // Configure CORS for Flutter Web & Mobile Clients (Render compatible)
  app.enableCors({
    origin: true,
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
  await app.listen(port, '0.0.0.0');
  logger.log(`🚀 Digital Ekub REST API Server is running on port ${port} (0.0.0.0)`);
  logger.log(`🏥 Health Check Endpoint available at: /api/v1/health`);
}

bootstrap();
