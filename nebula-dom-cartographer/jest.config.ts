import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  moduleFileExtensions: ['ts', 'tsx', 'js'],
  testMatch: ['**/*.test.ts'],
  maxWorkers: 64,
};

export default config;
