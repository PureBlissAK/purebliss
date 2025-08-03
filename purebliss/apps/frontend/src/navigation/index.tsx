import React from 'react';
import { NavigationContainer } from '@react-navigation/native';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import HomeScreen from '../screens/home/HomeScreen';
import MenuScreen from '../screens/menu/MenuScreen';
import OrdersScreen from '../screens/orders/OrdersScreen';
import SocialScreen from '../screens/social/SocialScreen';
import GamificationScreen from '../screens/gamification/GamificationScreen';
import ProfileScreen from '../screens/profile/ProfileScreen';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

const Tab = createBottomTabNavigator();

const AppNavigator = () => (
  <NavigationContainer>
    <Tab.Navigator
      screenOptions={({ route }) => ({
        tabBarIcon: ({ color, size }) => {
          let iconName = 'home';
          switch (route.name) {
            case 'Home':
              iconName = 'home';
              break;
            case 'Menu':
              iconName = 'food-apple';
              break;
            case 'Orders':
              iconName = 'cart';
              break;
            case 'Social':
              iconName = 'instagram';
              break;
            case 'Gamification':
              iconName = 'trophy';
              break;
            case 'Profile':
              iconName = 'account';
              break;
          }
          return <Icon name={iconName} size={size} color={color} />;
        },
      })}
    >
      <Tab.Screen name="Home" component={HomeScreen} />
      <Tab.Screen name="Menu" component={MenuScreen} />
      <Tab.Screen name="Orders" component={OrdersScreen} />
      <Tab.Screen name="Social" component={SocialScreen} />
      <Tab.Screen name="Gamification" component={GamificationScreen} />
      <Tab.Screen name="Profile" component={ProfileScreen} />
    </Tab.Navigator>
  </NavigationContainer>
);

export default AppNavigator;
