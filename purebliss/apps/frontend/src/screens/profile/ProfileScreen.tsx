import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Switch,
  Alert,
  Image,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

interface UserProfile {
  id: string;
  name: string;
  email: string;
  phone: string;
  avatar: string;
  memberSince: string;
  loyaltyLevel: string;
  points: number;
  totalOrders: number;
  favoriteSmoothie: string;
}

interface NotificationSettings {
  orderUpdates: boolean;
  promotions: boolean;
  challenges: boolean;
  newsletter: boolean;
}

interface PreferenceSettings {
  autoReorder: boolean;
  savePaymentInfo: boolean;
  locationServices: boolean;
  biometricAuth: boolean;
}

const MOCK_USER: UserProfile = {
  id: '1',
  name: 'Sarah Johnson',
  email: 'sarah.johnson@example.com',
  phone: '+1 (555) 123-4567',
  avatar: 'https://images.unsplash.com/photo-1494790108755-2616b9e6b298?w=150&h=150&fit=crop&crop=face',
  memberSince: '2023-06-15',
  loyaltyLevel: 'Bliss Member',
  points: 347,
  totalOrders: 23,
  favoriteSmoothie: 'Tropical Paradise',
};

const ProfileScreen: React.FC = () => {
  const [user, setUser] = useState<UserProfile>(MOCK_USER);
  const [notifications, setNotifications] = useState<NotificationSettings>({
    orderUpdates: true,
    promotions: true,
    challenges: false,
    newsletter: true,
  });
  const [preferences, setPreferences] = useState<PreferenceSettings>({
    autoReorder: false,
    savePaymentInfo: true,
    locationServices: true,
    biometricAuth: false,
  });

  const handleLogout = () => {
    Alert.alert(
      'Sign Out',
      'Are you sure you want to sign out?',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Sign Out', style: 'destructive', onPress: () => {
          Alert.alert('Signed Out', 'You have been signed out successfully');
        }},
      ]
    );
  };

  const handleDeleteAccount = () => {
    Alert.alert(
      'Delete Account',
      'This action cannot be undone. All your data will be permanently deleted.',
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Delete', style: 'destructive', onPress: () => {
          Alert.alert('Account Deleted', 'Your account has been deleted');
        }},
      ]
    );
  };

  const handleEditProfile = () => {
    Alert.alert('Edit Profile', 'This would open the profile editing screen');
  };

  const handlePaymentMethods = () => {
    Alert.alert('Payment Methods', 'This would show saved payment methods');
  };

  const handleAddresses = () => {
    Alert.alert('Addresses', 'This would show saved delivery addresses');
  };

  const handleOrderHistory = () => {
    Alert.alert('Order History', 'This would show detailed order history');
  };

  const handleSupport = () => {
    Alert.alert('Support', 'This would open the help & support section');
  };

  const handlePrivacyPolicy = () => {
    Alert.alert('Privacy Policy', 'This would show the privacy policy');
  };

  const handleTermsOfService = () => {
    Alert.alert('Terms of Service', 'This would show the terms of service');
  };

  const updateNotificationSetting = (key: keyof NotificationSettings, value: boolean) => {
    setNotifications(prev => ({ ...prev, [key]: value }));
  };

  const updatePreferenceSetting = (key: keyof PreferenceSettings, value: boolean) => {
    setPreferences(prev => ({ ...prev, [key]: value }));
  };

  const ProfileSection = ({ title, children }: { title: string; children: React.ReactNode }) => (
    <View style={styles.section}>
      <Text style={styles.sectionTitle}>{title}</Text>
      {children}
    </View>
  );

  const MenuItem = ({
    icon,
    title,
    subtitle,
    onPress,
    showArrow = true,
    rightComponent
  }: {
    icon: string;
    title: string;
    subtitle?: string;
    onPress: () => void;
    showArrow?: boolean;
    rightComponent?: React.ReactNode;
  }) => (
    <TouchableOpacity style={styles.menuItem} onPress={onPress} accessibilityLabel={title}>
      <View style={styles.menuItemLeft}>
        <Icon name={icon} size={24} color="#34D399" />
        <View style={styles.menuItemText}>
          <Text style={styles.menuItemTitle}>{title}</Text>
          {subtitle && <Text style={styles.menuItemSubtitle}>{subtitle}</Text>}
        </View>
      </View>
      <View style={styles.menuItemRight}>
        {rightComponent}
        {showArrow && <Icon name="chevron-right" size={20} color="#9CA3AF" />}
      </View>
    </TouchableOpacity>
  );

  const ToggleMenuItem = ({
    icon,
    title,
    subtitle,
    value,
    onToggle
  }: {
    icon: string;
    title: string;
    subtitle?: string;
    value: boolean;
    onToggle: (value: boolean) => void;
  }) => (
    <View style={styles.menuItem}>
      <View style={styles.menuItemLeft}>
        <Icon name={icon} size={24} color="#34D399" />
        <View style={styles.menuItemText}>
          <Text style={styles.menuItemTitle}>{title}</Text>
          {subtitle && <Text style={styles.menuItemSubtitle}>{subtitle}</Text>}
        </View>
      </View>
      <Switch
        value={value}
        onValueChange={onToggle}
        trackColor={{ false: '#E5E7EB', true: '#86EFAC' }}
        thumbColor={value ? '#34D399' : '#F3F4F6'}
        accessibilityLabel={title}
      />
    </View>
  );

  return (
    <ScrollView style={styles.container} showsVerticalScrollIndicator={false}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.profileInfo}>
          <Image source={{ uri: user.avatar }} style={styles.avatar} accessibilityLabel="User avatar" />
          <View style={styles.userDetails}>
            <Text style={styles.userName}>{user.name}</Text>
            <Text style={styles.userEmail}>{user.email}</Text>
            <Text style={styles.memberSince}>
              Member since {new Date(user.memberSince).toLocaleDateString('en-US', { month: 'long', year: 'numeric' })}
            </Text>
          </View>
        </View>
        <TouchableOpacity style={styles.editButton} onPress={handleEditProfile} accessibilityLabel="Edit profile">
          <Icon name="pencil" size={16} color="#34D399" />
          <Text style={styles.editButtonText}>Edit</Text>
        </TouchableOpacity>
      </View>

      {/* Stats */}
      <View style={styles.statsContainer}>
        <View style={styles.statItem}>
          <Text style={styles.statNumber}>{user.points}</Text>
          <Text style={styles.statLabel}>Points</Text>
        </View>
        <View style={styles.statDivider} />
        <View style={styles.statItem}>
          <Text style={styles.statNumber}>{user.totalOrders}</Text>
          <Text style={styles.statLabel}>Orders</Text>
        </View>
        <View style={styles.statDivider} />
        <View style={styles.statItem}>
          <Text style={styles.statLevel}>{user.loyaltyLevel}</Text>
          <Text style={styles.statLabel}>Level</Text>
        </View>
      </View>

      {/* Quick Actions */}
      <ProfileSection title="Quick Actions">
        <MenuItem
          icon="history"
          title="Order History"
          subtitle="View past orders and reorder"
          onPress={handleOrderHistory}
        />
        <MenuItem
          icon="credit-card"
          title="Payment Methods"
          subtitle="Manage cards and payment options"
          onPress={handlePaymentMethods}
        />
        <MenuItem
          icon="map-marker"
          title="Delivery Addresses"
          subtitle="Manage saved addresses"
          onPress={handleAddresses}
        />
      </ProfileSection>

      {/* Notifications */}
      <ProfileSection title="Notifications">
        <ToggleMenuItem
          icon="bell"
          title="Order Updates"
          subtitle="Get notified about order status"
          value={notifications.orderUpdates}
          onToggle={(value) => updateNotificationSetting('orderUpdates', value)}
        />
        <ToggleMenuItem
          icon="tag"
          title="Promotions & Offers"
          subtitle="Receive special deals and discounts"
          value={notifications.promotions}
          onToggle={(value) => updateNotificationSetting('promotions', value)}
        />
        <ToggleMenuItem
          icon="trophy"
          title="Challenges & Rewards"
          subtitle="Updates about gamification features"
          value={notifications.challenges}
          onToggle={(value) => updateNotificationSetting('challenges', value)}
        />
        <ToggleMenuItem
          icon="email"
          title="Newsletter"
          subtitle="Monthly updates and health tips"
          value={notifications.newsletter}
          onToggle={(value) => updateNotificationSetting('newsletter', value)}
        />
      </ProfileSection>

      {/* Preferences */}
      <ProfileSection title="Preferences">
        <ToggleMenuItem
          icon="refresh"
          title="Auto-Reorder"
          subtitle="Automatically reorder your favorites"
          value={preferences.autoReorder}
          onToggle={(value) => updatePreferenceSetting('autoReorder', value)}
        />
        <ToggleMenuItem
          icon="shield-check"
          title="Save Payment Info"
          subtitle="Securely store payment methods"
          value={preferences.savePaymentInfo}
          onToggle={(value) => updatePreferenceSetting('savePaymentInfo', value)}
        />
        <ToggleMenuItem
          icon="crosshairs-gps"
          title="Location Services"
          subtitle="Find nearby Pure Bliss locations"
          value={preferences.locationServices}
          onToggle={(value) => updatePreferenceSetting('locationServices', value)}
        />
        <ToggleMenuItem
          icon="fingerprint"
          title="Biometric Authentication"
          subtitle="Use Face ID or fingerprint"
          value={preferences.biometricAuth}
          onToggle={(value) => updatePreferenceSetting('biometricAuth', value)}
        />
      </ProfileSection>

      {/* Support & Legal */}
      <ProfileSection title="Support & Legal">
        <MenuItem
          icon="help-circle"
          title="Help & Support"
          subtitle="Get help with your account or orders"
          onPress={handleSupport}
        />
        <MenuItem
          icon="shield-account"
          title="Privacy Policy"
          subtitle="How we protect your data"
          onPress={handlePrivacyPolicy}
        />
        <MenuItem
          icon="file-document"
          title="Terms of Service"
          subtitle="Our terms and conditions"
          onPress={handleTermsOfService}
        />
      </ProfileSection>

      {/* Account Actions */}
      <ProfileSection title="Account">
        <MenuItem
          icon="logout"
          title="Sign Out"
          subtitle="Sign out of your account"
          onPress={handleLogout}
          showArrow={false}
        />
        <MenuItem
          icon="delete"
          title="Delete Account"
          subtitle="Permanently delete your account"
          onPress={handleDeleteAccount}
          showArrow={false}
        />
      </ProfileSection>

      {/* App Info */}
      <View style={styles.appInfo}>
        <Text style={styles.appVersion}>Pure Bliss v1.0.0</Text>
        <Text style={styles.buildInfo}>Build 2025.08.03</Text>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    backgroundColor: '#34D399',
    padding: 20,
    paddingTop: 60,
    borderBottomLeftRadius: 20,
    borderBottomRightRadius: 20,
  },
  profileInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 16,
  },
  avatar: {
    width: 80,
    height: 80,
    borderRadius: 40,
    marginRight: 16,
    borderWidth: 3,
    borderColor: '#FFF',
  },
  userDetails: {
    flex: 1,
  },
  userName: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#FFF',
    marginBottom: 4,
  },
  userEmail: {
    fontSize: 16,
    color: '#FFF',
    opacity: 0.9,
    marginBottom: 4,
  },
  memberSince: {
    fontSize: 14,
    color: '#FFF',
    opacity: 0.8,
  },
  editButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    alignSelf: 'flex-end',
  },
  editButtonText: {
    color: '#34D399',
    fontWeight: '600',
    marginLeft: 4,
  },
  statsContainer: {
    flexDirection: 'row',
    backgroundColor: '#FFF',
    margin: 16,
    borderRadius: 16,
    padding: 20,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  statItem: {
    flex: 1,
    alignItems: 'center',
  },
  statNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1F2937',
    marginBottom: 4,
  },
  statLevel: {
    fontSize: 14,
    fontWeight: 'bold',
    color: '#34D399',
    marginBottom: 4,
  },
  statLabel: {
    fontSize: 14,
    color: '#6B7280',
  },
  statDivider: {
    width: 1,
    backgroundColor: '#E5E7EB',
    marginHorizontal: 16,
  },
  section: {
    marginHorizontal: 16,
    marginBottom: 24,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1F2937',
    marginBottom: 12,
  },
  menuItem: {
    backgroundColor: '#FFF',
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    padding: 16,
    borderRadius: 12,
    marginBottom: 8,
    elevation: 1,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 1 },
    shadowOpacity: 0.05,
    shadowRadius: 2,
  },
  menuItemLeft: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  menuItemText: {
    marginLeft: 16,
    flex: 1,
  },
  menuItemTitle: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
    marginBottom: 2,
  },
  menuItemSubtitle: {
    fontSize: 14,
    color: '#6B7280',
  },
  menuItemRight: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  appInfo: {
    alignItems: 'center',
    padding: 20,
    marginBottom: 20,
  },
  appVersion: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 4,
  },
  buildInfo: {
    fontSize: 12,
    color: '#9CA3AF',
  },
});

export default ProfileScreen;
