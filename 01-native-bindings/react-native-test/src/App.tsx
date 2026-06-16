import { useState } from 'react';
import { Text, TextInput, View, StyleSheet } from 'react-native';
import { Caesar } from '@nicovegasr/caesar-rn';

export default function App() {
  const [text, setText] = useState('Hello, World!');
  const [shiftInput, setShiftInput] = useState('3');

  const shift = parseInt(shiftInput, 10) || 0;
  const ciphered = Caesar.cipher(text, shift);
  const deciphered = Caesar.decipher(ciphered, shift);

  return (
    <View style={styles.container}>
      <Text style={styles.heading}>@nicovegasr/caesar-rn — smoke test</Text>

      <Text style={styles.label}>Text</Text>
      <TextInput
        style={styles.input}
        value={text}
        onChangeText={setText}
        autoCapitalize="none"
        autoCorrect={false}
      />

      <Text style={styles.label}>Shift</Text>
      <TextInput
        style={styles.input}
        value={shiftInput}
        onChangeText={setShiftInput}
        keyboardType="number-pad"
      />

      <View style={styles.resultBlock}>
        <Text style={styles.resultLabel}>cipher →</Text>
        <Text style={styles.resultValue}>{ciphered}</Text>
      </View>

      <View style={styles.resultBlock}>
        <Text style={styles.resultLabel}>decipher(cipher) →</Text>
        <Text style={styles.resultValue}>{deciphered}</Text>
      </View>

      <Text style={styles.note}>
        Nota: el módulo nativo aún es un stub que devuelve el texto sin
        transformar. El siguiente paso conecta el Swift Package (iOS) y el AAR
        (Android).
      </Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    padding: 24,
    paddingTop: 64,
    backgroundColor: '#fff',
  },
  heading: {
    fontSize: 18,
    fontWeight: '600',
    marginBottom: 24,
  },
  label: {
    fontSize: 14,
    color: '#555',
    marginBottom: 4,
  },
  input: {
    borderWidth: 1,
    borderColor: '#ccc',
    borderRadius: 6,
    paddingHorizontal: 12,
    paddingVertical: 8,
    marginBottom: 16,
    fontSize: 16,
  },
  resultBlock: {
    marginBottom: 12,
  },
  resultLabel: {
    fontSize: 12,
    color: '#888',
  },
  resultValue: {
    fontSize: 16,
    fontFamily: 'Courier',
  },
  note: {
    marginTop: 24,
    fontSize: 12,
    color: '#999',
    fontStyle: 'italic',
  },
});
