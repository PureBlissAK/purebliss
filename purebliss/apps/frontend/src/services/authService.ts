// src/services/authService.ts
// Placeholder for Keycloak OIDC integration
import axios from 'axios';

const KEYCLOAK_URL = 'https://dev.purebliss.app/keycloak';

export interface LoginPayload {
  username: string;
  password: string;
}

export interface AuthResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
}

export const login = async (payload: LoginPayload): Promise<AuthResponse> => {
  // Replace with real OIDC flow
  const response = await axios.post(`${KEYCLOAK_URL}/realms/codeserver/protocol/openid-connect/token`, {
    grant_type: 'password',
    client_id: 'purebliss-app',
    username: payload.username,
    password: payload.password,
  }, {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });
  return response.data;
};

export const logout = async (refreshToken: string) => {
  // Placeholder for logout
  return axios.post(`${KEYCLOAK_URL}/realms/codeserver/protocol/openid-connect/logout`, {
    client_id: 'purebliss-app',
    refresh_token: refreshToken,
  }, {
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
  });
};
