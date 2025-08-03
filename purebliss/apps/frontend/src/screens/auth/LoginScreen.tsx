
import React from 'react';
import { View, StyleSheet } from 'react-native';
import { Text } from 'react-native-elements';
import LoginForm from '../../components/forms/LoginForm';

const LoginScreen: React.FC = () => {
  const handleSuccess = (token: string) => {
    // TODO: Store token securely and navigate to main app
    console.log('Login success:', token);
  };
  const handleError = (error: string) => {
    // Optionally log error
    console.log('Login error:', error);
  };
  return (
    <View style={styles.container}>
      <Text h3 style={styles.header}>Sign In to Pure Bliss</Text>
      <LoginForm onSuccess={handleSuccess} onError={handleError} />
    </View>
  );
};

const styles = StyleSheet.create({
  container: { flex: 1, justifyContent: 'center', alignItems: 'center', backgroundColor: '#FFF' },
  header: { color: '#34D399', marginBottom: 24 },
});

export default LoginScreen;
