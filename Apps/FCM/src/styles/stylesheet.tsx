import { StyleSheet } from 'react-native';
import * as Colors from '../constants/Colors';
import * as Fonts from '../constants/Fonts';
import * as Sizes from '../constants/Sizes';

export const styles = StyleSheet.create({
    container: {
        backgroundColor: Colors.CONTAINER_BACKGROUND_COLOR,
        flex: 1,
      },
      backButton: {
        marginLeft: Sizes.BACK_BUTTON_MARGIN_LEFT,
        marginRight: Sizes.BACK_BUTTON_MARGIN_RIGHT,
      },
      content: {
        flexGrow: 1,
        paddingHorizontal: 16,
        paddingTop: 8,
        paddingBottom: 16,
      },
      section: {
        marginBottom: 24,
      },
      sectionLabel: {
        alignSelf: 'flex-start',
        fontSize: 16,
        fontWeight: Fonts.FONT_WEIGHT_BOLD,
        marginBottom: 16,
      },
      textInputContainer: {
        marginTop: 8,
      },
      switchRow: {
        marginBottom: 4,
      },
      buttonContainer: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
      },
      saveButton: {
        marginTop: 8,
      },
      saveButtonText: {
        textTransform: 'uppercase',
      },
      restoreDefaultsButton: {
        marginTop: 16,
        width: Sizes.BUTTON_MAX_WIDTH,
      },
      note: {
        marginTop: 8,
      },
});