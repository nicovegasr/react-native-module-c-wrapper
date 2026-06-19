import { useEffect, useRef, useState } from 'react';
import {
  ActivityIndicator,
  Animated,
  Easing,
  Pressable,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { SafeAreaProvider, useSafeAreaInsets } from 'react-native-safe-area-context';
import { decrypt, decryptSync, encrypt, encryptSync } from '@nicovegasr/caesar-rn';

type Op = 'encrypt' | 'decrypt' | 'encryptSync' | 'decryptSync';

type RunResult = {
  op: Op;
  inputLength: number;
  outputLength: number;
  preview: string;
  ms: number;
};

function App() {
  return (
    <SafeAreaProvider>
      <StatusBar barStyle="dark-content" />
      <AppContent />
    </SafeAreaProvider>
  );
}

function AppContent() {
  const insets = useSafeAreaInsets();
  const [text, setText] = useState('Hola, mundo!');
  const [shiftText, setShiftText] = useState('5');
  const [result, setResult] = useState<RunResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [running, setRunning] = useState<Op | null>(null);

  const shift = Number.parseInt(shiftText, 10) || 0;

  const run = async (op: Op) => {
    setError(null);
    setRunning(op);
    const start = Date.now();
    try {
      let out: string;
      switch (op) {
        case 'encrypt':
          out = await encrypt(text, shift);
          break;
        case 'decrypt':
          out = await decrypt(text, shift);
          break;
        case 'encryptSync':
          out = encryptSync(text, shift);
          break;
        case 'decryptSync':
          out = decryptSync(text, shift);
          break;
      }
      const ms = Date.now() - start;
      setResult({
        op,
        inputLength: text.length,
        outputLength: out.length,
        preview: out.length > 200 ? out.slice(0, 200) + '…' : out,
        ms,
      });
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e));
    } finally {
      setRunning(null);
    }
  };

  const generate = (size: number) => {
    // Repite el texto hasta alcanzar ~size caracteres
    const base = text.length > 0 ? text : 'Hola, mundo! ';
    const reps = Math.ceil(size / base.length);
    setText(base.repeat(reps).slice(0, size));
    setResult(null);
  };

  return (
    <ScrollView
      keyboardShouldPersistTaps="handled"
      contentContainerStyle={[styles.container, { paddingTop: insets.top + 16 }]}>
      <View style={styles.headerRow}>
        <Text style={styles.title}>caesar playground</Text>
        <FreezeIndicator />
      </View>
      <Text style={styles.subtitle}>El indicador de la derecha se congela cuando el hilo JS se bloquea.</Text>

      <View style={styles.labelRow}>
        <Text style={styles.label}>Texto ({text.length.toLocaleString()} chars)</Text>
        <Pressable
          onPress={() => {
            setText('');
            setResult(null);
            setError(null);
          }}
          style={({ pressed }) => [styles.clearBtn, pressed && styles.pressed]}>
          <Text style={styles.clearBtnText}>Limpiar</Text>
        </Pressable>
      </View>
      <TextInput
        value={text}
        onChangeText={setText}
        multiline
        style={styles.textInput}
        placeholder="Pega aquí tu texto…"
        autoCorrect={false}
        autoCapitalize="none"
      />

      <View style={styles.row}>
        <View style={{ flex: 1 }}>
          <Text style={styles.label}>Shift</Text>
          <TextInput
            value={shiftText}
            onChangeText={setShiftText}
            keyboardType="numeric"
            style={styles.smallInput}
          />
        </View>
        <View style={{ flex: 2, marginLeft: 12 }}>
          <Text style={styles.label}>Generar payload</Text>
          <View style={styles.row}>
            <SmallBtn label="10k" onPress={() => generate(10_000)} />
            <SmallBtn label="100k" onPress={() => generate(100_000)} />
            <SmallBtn label="1M" onPress={() => generate(1_000_000)} />
            <SmallBtn label="100M" onPress={() => generate(100_000_000)} />
          </View>
        </View>
      </View>

      <Text style={[styles.label, { marginTop: 16 }]}>Operaciones</Text>
      <View style={styles.opsGrid}>
        <OpBtn label="encrypt" sub="async" onPress={() => run('encrypt')} busy={running === 'encrypt'} />
        <OpBtn label="decrypt" sub="async" onPress={() => run('decrypt')} busy={running === 'decrypt'} />
        <OpBtn
          label="encryptSync"
          sub="bloquea JS"
          onPress={() => run('encryptSync')}
          busy={running === 'encryptSync'}
          danger
        />
        <OpBtn
          label="decryptSync"
          sub="bloquea JS"
          onPress={() => run('decryptSync')}
          busy={running === 'decryptSync'}
          danger
        />
      </View>

      {error && (
        <View style={styles.errorBox}>
          <Text style={styles.errorText}>{error}</Text>
        </View>
      )}

      {result && (
        <View style={styles.resultBox}>
          <View style={styles.resultHeader}>
            <Text style={styles.resultOp}>{result.op}</Text>
            <Text style={styles.resultMs}>{result.ms} ms</Text>
          </View>
          <Text style={styles.resultMeta}>
            in: {result.inputLength.toLocaleString()} chars · out: {result.outputLength.toLocaleString()} chars
          </Text>
          <Text style={styles.resultPreview} selectable>
            {result.preview}
          </Text>
        </View>
      )}
    </ScrollView>
  );
}

function FreezeIndicator() {
  const rot = useRef(new Animated.Value(0)).current;
  useEffect(() => {
    const loop = Animated.loop(
      Animated.timing(rot, {
        toValue: 1,
        duration: 1200,
        easing: Easing.linear,
        useNativeDriver: true,
      }),
    );
    loop.start();
    return () => loop.stop();
  }, [rot]);
  const spin = rot.interpolate({ inputRange: [0, 1], outputRange: ['0deg', '360deg'] });
  // Truco: además del Animated nativo (no se congela), mostramos un setInterval-driven
  // contador que SÍ se congela con sync; útil para verlo a simple vista.
  const [tick, setTick] = useState(0);
  useEffect(() => {
    const id = setInterval(() => setTick(t => t + 1), 100);
    return () => clearInterval(id);
  }, []);
  return (
    <View style={styles.freezeWrap}>
      <Animated.View style={[styles.freezeSpinner, { transform: [{ rotate: spin }] }]} />
      <Text style={styles.freezeTick}>{tick}</Text>
    </View>
  );
}

function SmallBtn({ label, onPress }: { label: string; onPress: () => void }) {
  return (
    <Pressable onPress={onPress} style={({ pressed }) => [styles.smallBtn, pressed && styles.pressed]}>
      <Text style={styles.smallBtnText}>{label}</Text>
    </Pressable>
  );
}

function OpBtn({
  label,
  sub,
  onPress,
  busy,
  danger,
}: {
  label: string;
  sub: string;
  onPress: () => void;
  busy: boolean;
  danger?: boolean;
}) {
  return (
    <View style={styles.opBtnCell}>
      <Pressable
        onPress={onPress}
        disabled={busy}
        style={({ pressed }) => [
          styles.opBtn,
          danger ? styles.opBtnDanger : styles.opBtnSafe,
          pressed && styles.pressed,
          busy && styles.opBtnBusy,
        ]}>
        <View style={styles.opBtnInner}>
          <Text style={[styles.opBtnLabel, danger && styles.opBtnLabelDanger]}>{label}</Text>
          <Text style={[styles.opBtnSub, danger && styles.opBtnSubDanger]}>{sub}</Text>
        </View>
        {busy && <ActivityIndicator color={danger ? '#fff' : '#333'} />}
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { paddingHorizontal: 20, paddingBottom: 48 },
  headerRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between' },
  title: { fontSize: 22, fontWeight: '700' },
  subtitle: { marginTop: 4, marginBottom: 16, color: '#666', fontSize: 12 },
  label: { fontSize: 11, color: '#888', textTransform: 'uppercase', letterSpacing: 0.5, marginBottom: 6 },
  labelRow: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  clearBtn: { paddingVertical: 4, paddingHorizontal: 10, borderRadius: 6, backgroundColor: '#f1f1f1', marginBottom: 6 },
  clearBtnText: { fontSize: 11, fontWeight: '600', color: '#555' },
  textInput: {
    minHeight: 100,
    maxHeight: 200,
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 10,
    fontFamily: 'Menlo',
    fontSize: 13,
    textAlignVertical: 'top',
  },
  row: { flexDirection: 'row', alignItems: 'center', marginTop: 12 },
  smallInput: {
    borderWidth: 1,
    borderColor: '#ddd',
    borderRadius: 8,
    padding: 8,
    fontFamily: 'Menlo',
    fontSize: 14,
  },
  smallBtn: {
    backgroundColor: '#eee',
    paddingVertical: 8,
    paddingHorizontal: 12,
    borderRadius: 6,
    marginRight: 6,
  },
  smallBtnText: { fontSize: 13, fontWeight: '500' },
  opsGrid: { flexDirection: 'row', flexWrap: 'wrap', marginHorizontal: -6 },
  opBtnCell: { width: '50%', padding: 6 },
  opBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 14,
    paddingHorizontal: 14,
    borderRadius: 10,
    borderWidth: 1,
  },
  opBtnSafe: { backgroundColor: '#fff', borderColor: '#cfd8e3' },
  opBtnDanger: { backgroundColor: '#c0392b', borderColor: '#a8311f' },
  opBtnInner: { flex: 1 },
  opBtnLabel: { fontSize: 15, fontWeight: '600', color: '#111' },
  opBtnLabelDanger: { color: '#fff' },
  opBtnSub: { fontSize: 11, color: '#666', marginTop: 2 },
  opBtnSubDanger: { color: '#fee' },
  opBtnBusy: { opacity: 0.6 },
  pressed: { opacity: 0.7 },
  errorBox: { marginTop: 16, padding: 12, backgroundColor: '#fee', borderRadius: 8 },
  errorText: { color: '#900', fontFamily: 'Menlo', fontSize: 12 },
  resultBox: {
    marginTop: 16,
    padding: 12,
    backgroundColor: '#f3f7ff',
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#dbe7ff',
  },
  resultHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'center' },
  resultOp: { fontWeight: '700', fontSize: 14 },
  resultMs: { fontWeight: '700', fontSize: 14, color: '#1f4ea1' },
  resultMeta: { fontSize: 11, color: '#666', marginTop: 4 },
  resultPreview: { fontFamily: 'Menlo', fontSize: 12, marginTop: 8, color: '#222' },
  freezeWrap: { flexDirection: 'row', alignItems: 'center', gap: 6 },
  freezeSpinner: {
    width: 14,
    height: 14,
    borderRadius: 7,
    borderWidth: 2,
    borderColor: '#1f4ea1',
    borderTopColor: 'transparent',
  },
  freezeTick: { fontFamily: 'Menlo', fontSize: 11, color: '#666', width: 32 },
});

export default App;
