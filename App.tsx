import { StatusBar } from 'expo-status-bar';
import { useEffect, useState } from 'react';
import { StyleSheet, Text, View } from 'react-native';

// Same LCG shuffle as LockWidget.swift — keeps app preview in sync with widget
function wordForMinute(minuteOfDay: number): string {
  const chars = ['a', 'b', 'c', 'd', 'e', 'f'];
  let seed = minuteOfDay * 1103515245 + 12345;
  for (let i = 5; i >= 1; i--) {
    seed = (seed * 1103515245 + 12345) | 0;
    const j = Math.abs(seed) % (i + 1);
    [chars[i], chars[j]] = [chars[j], chars[i]];
  }
  return chars.join('');
}

function currentMinuteOfDay(): number {
  const now = new Date();
  return now.getHours() * 60 + now.getMinutes();
}

export default function App() {
  const [word, setWord] = useState(() => wordForMinute(currentMinuteOfDay()));

  useEffect(() => {
    const tick = () => setWord(wordForMinute(currentMinuteOfDay()));

    // Align to the next minute boundary then tick every 60 s
    const msUntilNextMinute = (60 - new Date().getSeconds()) * 1000;
    const initial = setTimeout(() => {
      tick();
      const interval = setInterval(tick, 60_000);
      return () => clearInterval(interval);
    }, msUntilNextMinute);

    return () => clearTimeout(initial);
  }, []);

  return (
    <View style={styles.container}>
      <Text style={styles.label}>lock screen widget preview</Text>
      <Text style={styles.word}>{word}</Text>
      <Text style={styles.sub}>changes every minute</Text>
      <StatusBar style="light" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#000',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
  },
  label: {
    color: '#666',
    fontSize: 13,
    letterSpacing: 1,
    textTransform: 'uppercase',
  },
  word: {
    color: '#fff',
    fontSize: 48,
    fontFamily: 'Courier',
    fontWeight: 'bold',
    letterSpacing: 4,
  },
  sub: {
    color: '#444',
    fontSize: 12,
  },
});
