import { configureStore } from '@reduxjs/toolkit';
import { useDispatch } from 'react-redux';

// Example slice import (replace with actual slices)
// import authReducer from '../screens/auth/authSlice';

export const store = configureStore({
  reducer: {
    // auth: authReducer,
  },
  middleware: getDefaultMiddleware =>
    getDefaultMiddleware({
      serializableCheck: false,
    }),
});

export type RootState = ReturnType<typeof store.getState>;
export type AppDispatch = typeof store.dispatch;
export const useAppDispatch = () => useDispatch<AppDispatch>();
