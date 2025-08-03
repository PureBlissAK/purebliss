import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

const SocialScreen: React.FC = () => (
  <View style={styles.container}>
    <Text style={styles.header}>Social Feed</Text>
    <Text style={styles.subtext}>See what the Pure Bliss community is sharing!</Text>
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

export default SocialScreen;
