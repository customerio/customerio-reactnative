import React, { useMemo, useRef, useState } from 'react';
import {
  ActivityIndicator,
  type ActivityIndicatorProps,
  Animated,
  StyleSheet,
  View,
  type ViewStyle,
} from 'react-native';
import InlineMessageNativeComponent, {
  InlineMessageState,
  type NativeProps,
  type SizeChangeEvent,
  type StateChangeEvent,
} from '../specs/components/InlineMessageNativeComponent';

/**
 * Props for the InlineInAppMessageView component.
 */
interface InlineInAppMessageViewProps
  extends Omit<NativeProps, 'onSizeChange' | 'onStateChange'> {
  /** Custom loading component to display while message is loading */
  loadingComponent?: React.ReactNode;
  /** Props for the default ActivityIndicator with optional minimum height */
  loadingIndicatorProps?: ActivityIndicatorProps & {
    /** Minimum height for the loading state (default: 36) */
    minimumHeight?: number;
  };
  /** Custom styles for the loading container */
  loadingContainerStyle?: ViewStyle;
}

/**
 * A React Native component for displaying inline in-app messages with animated sizing
 * and customizable loading states.
 *
 * @example
 * ```tsx
 * <InlineInAppMessageView
 *   elementId="my-message"
 *   loadingIndicatorProps={{ minimumHeight: 50 }}
 *   style={{ width: '100%' }}
 * />
 * ```
 */
const InlineInAppMessageView: React.FC<InlineInAppMessageViewProps> = ({
  style,
  loadingComponent,
  loadingIndicatorProps,
  loadingContainerStyle,
  ...props
}) => {
  // Animation values for dynamic sizing
  const animatedWidth = useRef<Animated.Value | null>(null);
  const animatedHeight = useRef(new Animated.Value(0)).current;
  const [isLoading, setIsLoading] = useState(false);

  // Extract width from style prop for priority handling
  const styleProvidedWidth = useMemo(() => {
    const flatStyle = StyleSheet.flatten(style);
    return flatStyle?.width;
  }, [style]);

  // Type guard to check if a value is a valid number to ensure we only animate valid dimensions
  const isValidNumber = (value: any): value is number =>
    value !== null && value !== undefined;

  // Helper function to create an animation for width or height changes
  const createAnimation = (
    animatedValue: Animated.Value,
    value: number,
    duration: number
  ) =>
    Animated.timing(animatedValue, {
      toValue: value,
      duration,
      useNativeDriver: false, // Layout animations require JS driver
    });

  const handleSizeChange = (event: { nativeEvent: SizeChangeEvent }) => {
    const { width, height, duration = 200 } = event.nativeEvent;

    const animations: Animated.CompositeAnimation[] = [];

    if (isValidNumber(width)) {
      if (!animatedWidth.current) {
        animatedWidth.current = new Animated.Value(width);
      }
      animations.push(createAnimation(animatedWidth.current, width, duration));
    }
    if (isValidNumber(height)) {
      animations.push(createAnimation(animatedHeight, height, duration));
    }

    if (animations.length > 0) {
      Animated.parallel(animations).start();
    }
  };

  const handleStateChange = (event: { nativeEvent: StateChangeEvent }) => {
    // Native component sends state as 'result' property
    const state = (event.nativeEvent as any).result || event.nativeEvent.state;

    switch (state) {
      case InlineMessageState.LoadingStarted:
        setIsLoading(true);
        createAnimation(
          animatedHeight,
          loadingIndicatorProps?.minimumHeight ?? 36, // Default: ActivityIndicator + padding
          0 // Immediate height change for loading state
        ).start();
        break;
      case InlineMessageState.LoadingFinished:
      case InlineMessageState.NoMessageToDisplay:
        setIsLoading(false);
        break;
    }
  };

  const renderLoadingComponent = () => {
    if (loadingComponent) {
      return loadingComponent;
    }
    return (
      <View style={[styles.loadingContainer, loadingContainerStyle]}>
        <ActivityIndicator size="small" {...loadingIndicatorProps} />
      </View>
    );
  };

  return (
    <Animated.View
      style={[
        style,
        {
          // Priority: Style prop -> Native width -> Default (100%)
          width: styleProvidedWidth ?? (animatedWidth.current || '100%'),
          height: animatedHeight,
        },
      ]}
    >
      <InlineMessageNativeComponent
        {...props}
        style={styles.nativeComponent}
        onSizeChange={handleSizeChange}
        onStateChange={handleStateChange}
      />
      {isLoading && renderLoadingComponent()}
    </Animated.View>
  );
};

const styles = StyleSheet.create({
  nativeComponent: {
    width: '100%',
    height: '100%',
  },
  loadingContainer: {
    ...StyleSheet.absoluteFillObject,
    justifyContent: 'center',
    alignItems: 'center',
  },
});

export default InlineInAppMessageView;
