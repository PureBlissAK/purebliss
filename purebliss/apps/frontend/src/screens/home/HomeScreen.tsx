import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

const HomeScreen: React.FC = () => (
  <View style={styles.container}>
    <Text style={styles.header}>Welcome to Pure Bliss!</Text>
    <Text style={styles.subtext}>Your healthy, tropical smoothie experience starts here.</Text>
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
    fontSize: 28,
    fontWeight: 'bold',
    color: '#34D399',
    marginBottom: 12,
  },
  subtext: {
    fontSize: 16,
    color: '#008080',
  },
});

export default HomeScreen;
