import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

const GamificationScreen: React.FC = () => (
  <View style={styles.container}>
    <Text style={styles.header}>BlissVibe Quests</Text>
    <Text style={styles.subtext}>Complete quests and earn rewards!</Text>
  </View>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#E0F7FA',
  },
  header: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#34D399',
    marginBottom: 10,
  },
  subtext: {
    fontSize: 16,
    color: '#008080',
  },
});

export default GamificationScreen;
