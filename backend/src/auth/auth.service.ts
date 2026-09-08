import { Injectable, ConflictException, UnauthorizedException, NotFoundException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { UserRole } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { RegisterDto } from './dto/register.dto';
import { LoginDto } from './dto/login.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwtService: JwtService,
  ) {}

  /**
   * Register a new user in PostgreSQL 18
   */
  async register(dto: RegisterDto) {
    const normalizedEmail = dto.email.toLowerCase().trim();
    const normalizedPhone = dto.phone.trim();

    // Prevent duplicate email
    const existingEmail = await this.prisma.user.findUnique({
      where: { email: normalizedEmail },
    });
    if (existingEmail) {
      throw new ConflictException('A user with this email address already exists');
    }

    // Prevent duplicate phone
    const existingPhone = await this.prisma.user.findUnique({
      where: { phone: normalizedPhone },
    });
    if (existingPhone) {
      throw new ConflictException('A user with this phone number already exists');
    }

    // Hash password securely with bcrypt
    const passwordHash = await bcrypt.hash(dto.password, 10);

    // Create user in PostgreSQL database
    const user = await this.prisma.user.create({
      data: {
        name: dto.fullName.trim(),
        email: normalizedEmail,
        phone: normalizedPhone,
        passwordHash,
        role: UserRole.MEMBER,
      },
    });

    // Generate JWT token
    const accessToken = this.generateToken(user.id, user.email, user.role);

    return {
      message: 'Registration successful',
      accessToken,
      user: this.sanitizeUser(user),
    };
  }

  /**
   * Login user with Email or Phone + Password
   */
  async login(dto: LoginDto) {
    const identifier = dto.emailOrPhone.trim();

    // Find user by email or phone
    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { email: identifier.toLowerCase() },
          { phone: identifier },
        ],
      },
    });

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Verify password hash
    const isPasswordValid = await bcrypt.compare(dto.password, user.passwordHash);
    if (!isPasswordValid) {
      throw new UnauthorizedException('Invalid credentials');
    }

    // Generate JWT token
    const accessToken = this.generateToken(user.id, user.email, user.role);

    return {
      message: 'Login successful',
      accessToken,
      user: this.sanitizeUser(user),
    };
  }

  /**
   * Fetch authenticated user details
   */
  async getMe(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
    });

    if (!user) {
      throw new NotFoundException('User profile not found');
    }

    return this.sanitizeUser(user);
  }

  /**
   * Generate JWT Access Token containing user ID and role
   */
  private generateToken(userId: string, email: string, role: string): string {
    const payload = { sub: userId, email, role };
    return this.jwtService.sign(payload);
  }

  /**
   * Remove sensitive fields (passwordHash) from user response
   */
  private sanitizeUser(user: any) {
    const { passwordHash, ...safeUser } = user;
    return safeUser;
  }
}
