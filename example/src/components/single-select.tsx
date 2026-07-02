import { Colors } from '@colors';
import React, { Key, useState } from 'react';
import { StyleSheet, TouchableOpacity, View } from 'react-native';
import { BoldText } from './text';

type SelectionItem<T> = { label: string; value: T };

type SingleSelectProps<T extends Key> = {
  data: SelectionItem<T>[];
  selectedValue: T;
  onValueChange: (value: T) => void;
  label?: string;
  /** Stack the label above the options and stretch the options to fill the width. */
  fullWidth?: boolean;
};

export const SingleSelect = <T extends Key>({
  data,
  selectedValue,
  onValueChange,
  label,
  fullWidth,
}: SingleSelectProps<T>) => {
  const [value, setValue] = useState(selectedValue);

  return (
    <View style={[styles.container, fullWidth && styles.containerFullWidth]}>
      {label && <BoldText style={styles.label}>{label}</BoldText>}
      <View
        style={[
          styles.selectionItems,
          fullWidth && styles.selectionItemsFullWidth,
        ]}
      >
        {data.map((item, index) => (
          <TouchableOpacity
            key={item.value}
            style={[
              styles.itemContainer,
              fullWidth && styles.itemContainerFullWidth,
              item.value === value && styles.selectedItemContainer,
              index === 0 && styles.firstItemContainer,
              index === data.length - 1 && styles.lastItemContainer,
            ]}
            onPress={() => {
              onValueChange(item.value);
              setValue(item.value);
            }}
          >
            <BoldText
              style={[
                styles.itemText,
                item.value === value && styles.selectedItemText,
              ]}
            >
              {item.label}
            </BoldText>
          </TouchableOpacity>
        ))}
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    flexWrap: 'wrap',
    gap: 8,
  },

  containerFullWidth: {
    flexDirection: 'column',
    alignItems: 'stretch',
  },

  selectionItems: {
    flexDirection: 'row',
    alignItems: 'center',
    flexWrap: 'wrap',
  },

  selectionItemsFullWidth: {
    flexWrap: 'nowrap',
  },

  itemContainer: {
    padding: 8,
    backgroundColor: Colors.secondaryBg,
  },

  itemContainerFullWidth: {
    flex: 1,
  },

  selectedItemContainer: {
    backgroundColor: Colors.primaryBg,
  },

  firstItemContainer: {
    borderTopLeftRadius: 8,
    borderBottomLeftRadius: 8,
  },

  lastItemContainer: {
    borderTopRightRadius: 8,
    borderBottomRightRadius: 8,
  },

  selectedItemText: {
    color: Colors.primaryText,
  },

  itemText: {
    textAlign: 'center',
    textAlignVertical: 'center', // For vertical centering
    color: Colors.secondaryText,
  },
  label: {},
});
