import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

const MenuScreen: React.FC = () => (
  <View style={styles.container}>
    <Text style={styles.header}>Smoothie Menu</Text>
    <Text style={styles.subtext}>Browse our delicious, healthy options!</Text>
  </View>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FFF',
  },
  header: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#3B82F6',
    marginBottom: 10,
  },
  subtext: {
    fontSize: 16,
    color: '#008080',
  },
});

export default MenuScreen;
