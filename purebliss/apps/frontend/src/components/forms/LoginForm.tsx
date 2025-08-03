import React, { useState } from 'react';
import { View, StyleSheet } from 'react-native';
import { Input, Button, Text } from 'react-native-elements';
import { login } from '../../services/authService';

interface Props {
  onSuccess: (token: string) => void;
  onError: (error: string) => void;
}

const LoginForm: React.FC<Props> = ({ onSuccess, onError }) => {
  const [username, setUsername] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const handleLogin = async () => {
    setLoading(true);
    setError('');
    try {
      const res = await login({ username, password });
      onSuccess(res.access_token);
    } catch (e: any) {
      setError('Invalid credentials');
      onError(e.message);
    } finally {
      setLoading(false);
    }
  };

  return (
    <View style={styles.container}>
      <Input
        placeholder="Username"
        value={username}
        onChangeText={setUsername}
        autoCapitalize="none"
        leftIcon={{ type: 'material', name: 'person' }}
      />
      <Input
        placeholder="Password"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
        leftIcon={{ type: 'material', name: 'lock' }}
      />
      {error ? <Text style={styles.error}>{error}</Text> : null}
      <Button
        title={loading ? 'Logging in...' : 'Login'}
        onPress={handleLogin}
        loading={loading}
        buttonStyle={styles.button}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: { width: '100%', padding: 16 },
  button: { backgroundColor: '#34D399', marginTop: 8 },
  error: { color: 'red', marginBottom: 8, textAlign: 'center' },
});

export default LoginForm;
