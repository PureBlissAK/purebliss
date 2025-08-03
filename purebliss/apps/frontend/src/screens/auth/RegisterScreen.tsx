import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

const RegisterScreen: React.FC = () => (
  <View style={styles.container}>
    <Text style={styles.header}>Register</Text>
    <Text style={styles.subtext}>Create your Pure Bliss account</Text>
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
    color: '#34D399',
    marginBottom: 10,
  },
  subtext: {
    fontSize: 16,
    color: '#008080',
  },
});

export default RegisterScreen;
