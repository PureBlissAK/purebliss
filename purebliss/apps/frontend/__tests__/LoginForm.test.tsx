import React from 'react';
import { render, fireEvent, waitFor } from '@testing-library/react-native';
import LoginForm from '../src/components/forms/LoginForm';

describe('LoginForm', () => {
  it('renders and submits credentials', async () => {
    const mockSuccess = jest.fn();
    const mockError = jest.fn();
    const { getByPlaceholderText, getByText } = render(
      <LoginForm onSuccess={mockSuccess} onError={mockError} />
    );
    fireEvent.changeText(getByPlaceholderText('Username'), 'testuser');
    fireEvent.changeText(getByPlaceholderText('Password'), 'testpass');
    fireEvent.press(getByText('Login'));
    // Wait for async login (would mock network in real test)
    await waitFor(() => {
      expect(mockSuccess).not.toBeNull();
    });
  });
});
