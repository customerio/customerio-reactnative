// Argument validation utilities for SDK internal use
// Ensures input safety and throws clear errors when validation fails

import type { CioConfig } from 'src/index';

/**
 * Builds a standardized error message for validation failures.
 */
function buildErrorMessage(
  usage: string | undefined,
  fieldName: string,
  error: string
): string {
  const prefix = usage ? `${usage} ` : '';
  return `${prefix}"${fieldName}" ${error}.`;
}

/**
 * Throws an error if the condition is true.
 * Use this to fail validation checks with cleaner syntax.
 */
function failIf(condition: boolean, message: () => string): void {
  if (condition) {
    throw new Error(`[CustomerIO] ${message()}`);
  }
}

/**
 * Validates that a value is defined (not undefined or null).
 * Useful for checking required fields.
 */
function failIfUndefined(
  value: unknown,
  fieldName: string,
  usage?: string
): void {
  failIf(value === undefined || value === null, () =>
    buildErrorMessage(usage, fieldName, 'is required')
  );
}

/**
 * Validates that a value is a string.
 * Throws if the value is not a string, or if it's empty (unless allowEmpty is true).
 */
function validateString(
  value: unknown,
  fieldName: string,
  options: {
    allowEmpty?: boolean;
    usage?: string;
  } = { allowEmpty: true }
) {
  const prefix = options.usage ? `${options.usage} ` : '';

  failIfUndefined(value, fieldName, options.usage);
  failIf(
    typeof value !== 'string',
    () => `${prefix}"${fieldName}" must be a string.`
  );
  // Since typeof value is already checked to be a string,
  // we can safely cast it here without additional checks.
  const typedValue = value as string;
  failIf(
    !options.allowEmpty && typedValue.trim() === '',
    () => `${prefix}"${fieldName}" must be a non-empty string.`
  );
}

/**
 * Validates that a value is a plain object (not null or an array).
 */
function validateRecord(
  value: unknown,
  fieldName: string,
  options: {
    usage?: string;
    expectedType?: string;
  } = {}
) {
  const prefix = options.usage ? `${options.usage} ` : '';
  const typeName = options.expectedType ?? 'plain';

  failIfUndefined(value, fieldName, options.usage);
  failIf(
    typeof value !== 'object' || Array.isArray(value),
    () => `${prefix}"${fieldName}" must be a valid ${typeName} object.`
  );
}

/**
 * Validates that the given value is a valid CioConfig object.
 * Throws if required fields are missing or incorrectly typed.
 */
function validateConfig(value: unknown): asserts value is CioConfig {
  const fieldName = 'config';
  const usage = 'SDK';

  validateRecord(value, fieldName, {
    expectedType: 'CioConfig',
    usage: usage,
  });

  const obj = value as CioConfig;
  validateString(obj.cdpApiKey, `${fieldName}.cdpApiKey`, {
    allowEmpty: false,
    usage: usage,
  });
}

// For type safety, we define a ConfigValidator type that asserts the value is a CioConfig
// This allows us to use it in the assert object without needing to redefine the function signature
type ConfigValidator = (value: unknown) => asserts value is CioConfig;

export const assert: {
  string: typeof validateString;
  record: typeof validateRecord;
  config: ConfigValidator;
} = {
  string: validateString,
  record: validateRecord,
  config: validateConfig,
};
