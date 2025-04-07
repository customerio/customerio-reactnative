type StylableComponentProps<T extends object> = {
  style?: T | T[] | null | false;
};

const styleArray = <T extends object>(style?: T | T[] | null | false) => {
  if (!style) {
    return [];
  }
  if (Array.isArray(style)) {
    return style;
  }
  return [style];
};

export const mergeProps = <T extends object>(
  ...propsToMerge: StylableComponentProps<T>[]
) => {
  return {
    ...propsToMerge.reduce(
      (prev, curr) => {
        const prevStyles = styleArray(prev.style);
        const currStyles = styleArray(curr.style);

        return { ...prev, ...curr, style: [...prevStyles, ...currStyles] };
      },
      { style: null } satisfies StylableComponentProps<T>
    ),
  };
};
