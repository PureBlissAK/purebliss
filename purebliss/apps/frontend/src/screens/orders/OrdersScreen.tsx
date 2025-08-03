import React from 'react';
import { View, Text, StyleSheet } from 'react-native';

const OrdersScreen: React.FC = () => (
  <View style={styles.container}>
    <Text style={styles.header}>Your Orders</Text>
    <Text style={styles.subtext}>Track your smoothie orders in real time.</Text>
  </View>
);

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#FBBF24',
  },
  header: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FF7F50',
    marginBottom: 10,
  },
  subtext: {
    fontSize: 16,
    color: '#008080',
  },
});

export default OrdersScreen;
