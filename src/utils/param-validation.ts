// Argument validation utilities for SDK internal use
// Ensures input safety and throws clear errors when validation fails

import type { CioConfig, CustomAttributes } from '../types';

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
 * Returns true if the value is undefined or null.
 */
function isUndefined(value: unknown): boolean {
  return value === undefined || value === null;
}

/**
 * Throws an error if the condition is true.
 * Use this to fail validation checks with cleaner syntax.
 */
function failIf(condition: boolean, message: () => string): void {
  if (__DEV__ && condition) {
    throw new Error(`[CustomerIO] ${message()}`);
  }
}

/**
 * Logs a warning if the condition is true.
 * Use this for misconfigurations that degrade behavior but must not fail initialization.
 */
function warnIf(condition: boolean, message: () => string): void {
  if (__DEV__ && condition) {
    console.warn(`[CustomerIO] ${message()}`);
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
  failIf(isUndefined(value), () =>
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
    optional?: boolean;
  } = { allowEmpty: true }
) {
  const { allowEmpty, usage, optional } = options;
  if (optional && isUndefined(value)) {
    return; // Skip validation for optional fields
  }

  const prefix = usage ? `${usage} ` : '';

  failIfUndefined(value, fieldName, usage);
  failIf(
    typeof value !== 'string',
    () => `${prefix}"${fieldName}" must be a string.`
  );
  // Since typeof value is already checked to be a string,
  // we can safely cast it here without additional checks.
  const typedValue = value as string;
  failIf(
    !allowEmpty && typedValue.trim() === '',
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
    optional?: boolean;
  } = {}
) {
  const { usage, expectedType, optional } = options;
  if (optional && isUndefined(value)) {
    return; // Skip validation for optional fields
  }

  const prefix = usage ? `${usage} ` : '';
  const typeName = expectedType ?? 'plain';

  failIfUndefined(value, fieldName, usage);
  failIf(
    typeof value !== 'object' || Array.isArray(value),
    () => `${prefix}"${fieldName}" must be a valid ${typeName} object.`
  );
}

/**
 * Validates that a value is a valid CustomAttributes object.
 * Automatically converts Map objects to plain objects for compatibility.
 * This is a specialized version of validateRecord optimized for attribute validation.
 */
function validateAttributes(
  value: unknown,
  fieldName: string,
  options: {
    usage?: string;
    expectedType?: string;
    optional?: boolean;
  } = {}
): CustomAttributes | undefined {
  const exists = !isUndefined(value);
  if (options.optional && !exists) {
    return; // Skip validation for optional fields
  }

  let attributes: unknown;
  if (exists && value instanceof Map) {
    // Convert Map to plain object for native serialization
    attributes = Object.fromEntries(value);
  } else {
    attributes = value;
  }
  validateRecord(attributes, fieldName, options);
  return attributes as CustomAttributes;
}

/**
 * The placeholder the SDK substitutes with the unread count when rendering
 * `bellWithUnreadCount`.
 */
const COUNT_PLACEHOLDER = '{count}';

/**
 * Warns when `bellWithUnreadCount` is missing its `{count}` placeholder.
 *
 * The label is a template, not a finished string. A misspelled placeholder (`{COUNT}`,
 * `{{count}}`, `%d`) matches nothing, so the template is announced verbatim — braces and all —
 * and the count is never spoken. The check lives here rather than in either native layer
 * because neither can report it usefully: Android logs at `debug`, which the default `ERROR`
 * level discards, and iOS does not check at all. Warning from JavaScript reaches the
 * developer's console on both platforms, whatever the SDK log level.
 */
function validateInboxAccessibilityLabels(value: unknown): void {
  if (isUndefined(value) || typeof value !== 'object') {
    return;
  }

  const template = (value as { bellWithUnreadCount?: unknown })
    .bellWithUnreadCount;
  warnIf(
    typeof template === 'string' && !template.includes(COUNT_PLACEHOLDER),
    () =>
      `"inApp.notificationInboxAccessibilityLabels.bellWithUnreadCount" has no ` +
      `"${COUNT_PLACEHOLDER}" placeholder, so the unread count will not be announced.`
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
  validateInboxAccessibilityLabels(
    obj.inApp?.notificationInboxAccessibilityLabels
  );
}

// For type safety, we define a ConfigValidator type that asserts the value is a CioConfig
// This allows us to use it in the assert object without needing to redefine the function signature
type ConfigValidator = (value: unknown) => asserts value is CioConfig;

export const assert: {
  string: typeof validateString;
  record: typeof validateRecord;
  attributes: typeof validateAttributes;
  config: ConfigValidator;
} = {
  string: validateString,
  record: validateRecord,
  attributes: validateAttributes,
  config: validateConfig,
};

export const validate = {
  isUndefined: isUndefined,
};
