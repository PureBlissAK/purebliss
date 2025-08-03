import React, { useState } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  FlatList, 
  TouchableOpacity,
  ScrollView,
  Alert,
  Dimensions
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

const { width } = Dimensions.get('window');

interface Achievement {
  id: string;
  title: string;
  description: string;
  icon: string;
  points: number;
  isUnlocked: boolean;
  progress?: number;
  maxProgress?: number;
  category: 'orders' | 'social' | 'streak' | 'special';
}

interface Reward {
  id: string;
  title: string;
  description: string;
  pointsCost: number;
  discount: number;
  validUntil: Date;
  isRedeemed: boolean;
  category: 'discount' | 'freebie' | 'upgrade';
}

interface LoyaltyLevel {
  level: number;
  name: string;
  minPoints: number;
  maxPoints: number;
  benefits: string[];
  color: string;
}

const LOYALTY_LEVELS: LoyaltyLevel[] = [
  { level: 1, name: 'Fresh Starter', minPoints: 0, maxPoints: 99, benefits: ['5% birthday discount'], color: '#10B981' },
  { level: 2, name: 'Smoothie Lover', minPoints: 100, maxPoints: 299, benefits: ['5% birthday discount', '10% off every 10th order'], color: '#3B82F6' },
  { level: 3, name: 'Bliss Member', minPoints: 300, maxPoints: 599, benefits: ['All previous benefits', 'Free size upgrade monthly'], color: '#8B5CF6' },
  { level: 4, name: 'Pure Legend', minPoints: 600, maxPoints: 999, benefits: ['All previous benefits', 'Exclusive flavors access'], color: '#F59E0B' },
  { level: 5, name: 'Bliss VIP', minPoints: 1000, maxPoints: 9999, benefits: ['All previous benefits', 'Personal smoothie concierge'], color: '#EF4444' },
];

const MOCK_ACHIEVEMENTS: Achievement[] = [
  {
    id: '1',
    title: 'First Order',
    description: 'Complete your first smoothie order',
    icon: 'trophy',
    points: 50,
    isUnlocked: true,
    category: 'orders',
  },
  {
    id: '2',
    title: 'Social Butterfly',
    description: 'Share 5 smoothie photos on social media',
    icon: 'camera',
    points: 100,
    isUnlocked: true,
    progress: 5,
    maxProgress: 5,
    category: 'social',
  },
  {
    id: '3',
    title: 'Weekly Warrior',
    description: 'Order smoothies 7 days in a row',
    icon: 'calendar-check',
    points: 200,
    isUnlocked: false,
    progress: 4,
    maxProgress: 7,
    category: 'streak',
  },
  {
    id: '4',
    title: 'Green Machine',
    description: 'Try all detox smoothies',
    icon: 'leaf',
    points: 150,
    isUnlocked: false,
    progress: 2,
    maxProgress: 4,
    category: 'orders',
  },
  {
    id: '5',
    title: 'Review Master',
    description: 'Leave 10 helpful reviews',
    icon: 'star',
    points: 75,
    isUnlocked: false,
    progress: 3,
    maxProgress: 10,
    category: 'social',
  },
];

const MOCK_REWARDS: Reward[] = [
  {
    id: '1',
    title: '10% Off Next Order',
    description: 'Save 10% on your next smoothie purchase',
    pointsCost: 100,
    discount: 10,
    validUntil: new Date('2024-02-15'),
    isRedeemed: false,
    category: 'discount',
  },
  {
    id: '2',
    title: 'Free Small Smoothie',
    description: 'Get any small smoothie for free',
    pointsCost: 200,
    discount: 100,
    validUntil: new Date('2024-03-01'),
    isRedeemed: true,
    category: 'freebie',
  },
  {
    id: '3',
    title: 'Size Upgrade',
    description: 'Free upgrade from small to large',
    pointsCost: 75,
    discount: 25,
    validUntil: new Date('2024-01-31'),
    isRedeemed: false,
    category: 'upgrade',
  },
  {
    id: '4',
    title: '20% Off Protein Smoothies',
    description: 'Special discount on all protein smoothies',
    pointsCost: 150,
    discount: 20,
    validUntil: new Date('2024-02-20'),
    isRedeemed: false,
    category: 'discount',
  },
];

const GamificationScreen: React.FC = () => {
  const [currentPoints, setCurrentPoints] = useState(347);
  const [achievements, setAchievements] = useState<Achievement[]>(MOCK_ACHIEVEMENTS);
  const [rewards, setRewards] = useState<Reward[]>(MOCK_REWARDS);
  const [selectedTab, setSelectedTab] = useState<'overview' | 'achievements' | 'rewards'>('overview');

  // Calculate current level
  const currentLevel = LOYALTY_LEVELS.find(level => 
    currentPoints >= level.minPoints && currentPoints <= level.maxPoints
  ) || LOYALTY_LEVELS[0];

  const nextLevel = LOYALTY_LEVELS.find(level => level.level === currentLevel.level + 1);
  const progressToNext = nextLevel 
    ? ((currentPoints - currentLevel.minPoints) / (nextLevel.minPoints - currentLevel.minPoints)) * 100
    : 100;

  const totalEarnedPoints = achievements
    .filter(achievement => achievement.isUnlocked)
    .reduce((sum, achievement) => sum + achievement.points, 0);

  const handleRedeemReward = (rewardId: string) => {
    const reward = rewards.find(r => r.id === rewardId);
    if (!reward) return;

    if (currentPoints < reward.pointsCost) {
      Alert.alert('Insufficient Points', 'You need more points to redeem this reward');
      return;
    }

    Alert.alert(
      'Redeem Reward',
      `Redeem ${reward.title} for ${reward.pointsCost} points?`,
      [
        { text: 'Cancel', style: 'cancel' },
        { text: 'Redeem', onPress: () => {
          setCurrentPoints(prev => prev - reward.pointsCost);
          setRewards(prev => prev.map(r => 
            r.id === rewardId ? { ...r, isRedeemed: true } : r
          ));
          Alert.alert('Success!', 'Reward redeemed successfully! Check your profile for the code.');
        }},
      ]
    );
  };

  const getCategoryColor = (category: Achievement['category']) => {
    switch (category) {
      case 'orders': return '#34D399';
      case 'social': return '#8B5CF6';
      case 'streak': return '#F59E0B';
      case 'special': return '#EF4444';
      default: return '#6B7280';
    }
  };

  const getRewardCategoryIcon = (category: Reward['category']) => {
    switch (category) {
      case 'discount': return 'percent';
      case 'freebie': return 'gift';
      case 'upgrade': return 'arrow-up-bold';
      default: return 'star';
    }
  };

  const renderAchievement = ({ item: achievement }: { item: Achievement }) => (
    <View style={[
      styles.achievementCard,
      achievement.isUnlocked && styles.achievementUnlocked
    ]}>
      <View style={[
        styles.achievementIcon,
        { backgroundColor: getCategoryColor(achievement.category) }
      ]}>
        <Icon 
          name={achievement.icon} 
          size={24} 
          color="#FFF" 
        />
      </View>
      
      <View style={styles.achievementContent}>
        <Text style={[
          styles.achievementTitle,
          achievement.isUnlocked && styles.achievementTitleUnlocked
        ]}>
          {achievement.title}
        </Text>
        <Text style={styles.achievementDescription}>
          {achievement.description}
        </Text>
        
        {achievement.progress !== undefined && achievement.maxProgress && (
          <View style={styles.progressContainer}>
            <View style={styles.progressBar}>
              <View 
                style={[
                  styles.progressFill,
                  { 
                    width: `${(achievement.progress / achievement.maxProgress) * 100}%`,
                    backgroundColor: getCategoryColor(achievement.category)
                  }
                ]} 
              />
            </View>
            <Text style={styles.progressText}>
              {achievement.progress}/{achievement.maxProgress}
            </Text>
          </View>
        )}
        
        <View style={styles.achievementFooter}>
          <Text style={styles.achievementPoints}>
            {achievement.points} points
          </Text>
          {achievement.isUnlocked && (
            <Text style={styles.unlockedText}>✓ Unlocked</Text>
          )}
        </View>
      </View>
    </View>
  );

  const renderReward = ({ item: reward }: { item: Reward }) => (
    <View style={[
      styles.rewardCard,
      reward.isRedeemed && styles.rewardRedeemed
    ]}>
      <View style={styles.rewardHeader}>
        <Icon 
          name={getRewardCategoryIcon(reward.category)} 
          size={24} 
          color="#34D399" 
        />
        <Text style={styles.rewardTitle}>{reward.title}</Text>
      </View>
      
      <Text style={styles.rewardDescription}>{reward.description}</Text>
      
      <View style={styles.rewardDetails}>
        <Text style={styles.rewardDiscount}>{reward.discount}% savings</Text>
        <Text style={styles.rewardExpiry}>
          Valid until: {reward.validUntil.toLocaleDateString()}
        </Text>
      </View>
      
      <View style={styles.rewardFooter}>
        <Text style={styles.rewardCost}>
          {reward.pointsCost} points
        </Text>
        
        <TouchableOpacity 
          style={[
            styles.redeemButton,
            (reward.isRedeemed || currentPoints < reward.pointsCost) && styles.redeemButtonDisabled
          ]}
          onPress={() => handleRedeemReward(reward.id)}
          disabled={reward.isRedeemed || currentPoints < reward.pointsCost}
        >
          <Text style={[
            styles.redeemButtonText,
            (reward.isRedeemed || currentPoints < reward.pointsCost) && styles.redeemButtonTextDisabled
          ]}>
            {reward.isRedeemed ? 'Redeemed' : 'Redeem'}
          </Text>
        </TouchableOpacity>
      </View>
    </View>
  );

  const renderOverview = () => (
    <ScrollView style={styles.overviewContainer} showsVerticalScrollIndicator={false}>
      {/* Level Progress */}
      <View style={styles.levelCard}>
        <View style={styles.levelHeader}>
          <Text style={styles.levelTitle}>Level {currentLevel.level}</Text>
          <Text style={styles.levelName}>{currentLevel.name}</Text>
        </View>
        
        <View style={styles.pointsContainer}>
          <Text style={styles.currentPoints}>{currentPoints}</Text>
          <Text style={styles.pointsLabel}>points</Text>
        </View>
        
        {nextLevel && (
          <View style={styles.progressToNext}>
            <View style={styles.progressBarContainer}>
              <View 
                style={[
                  styles.levelProgressFill,
                  { 
                    width: `${progressToNext}%`,
                    backgroundColor: currentLevel.color 
                  }
                ]} 
              />
            </View>
            <Text style={styles.nextLevelText}>
              {nextLevel.minPoints - currentPoints} points to {nextLevel.name}
            </Text>
          </View>
        )}
        
        <View style={styles.benefitsList}>
          <Text style={styles.benefitsTitle}>Your Benefits:</Text>
          {currentLevel.benefits.map((benefit, index) => (
            <Text key={index} style={styles.benefitItem}>• {benefit}</Text>
          ))}
        </View>
      </View>

      {/* Quick Stats */}
      <View style={styles.statsContainer}>
        <View style={styles.statCard}>
          <Icon name="trophy" size={32} color="#F59E0B" />
          <Text style={styles.statNumber}>
            {achievements.filter(a => a.isUnlocked).length}
          </Text>
          <Text style={styles.statLabel}>Achievements</Text>
        </View>
        
        <View style={styles.statCard}>
          <Icon name="star" size={32} color="#34D399" />
          <Text style={styles.statNumber}>{totalEarnedPoints}</Text>
          <Text style={styles.statLabel}>Total Earned</Text>
        </View>
        
        <View style={styles.statCard}>
          <Icon name="gift" size={32} color="#8B5CF6" />
          <Text style={styles.statNumber}>
            {rewards.filter(r => r.isRedeemed).length}
          </Text>
          <Text style={styles.statLabel}>Redeemed</Text>
        </View>
      </View>

      {/* Recent Achievements */}
      <View style={styles.sectionCard}>
        <Text style={styles.sectionTitle}>Recent Achievements</Text>
        {achievements
          .filter(a => a.isUnlocked)
          .slice(0, 3)
          .map((achievement, index) => (
            <View key={index} style={styles.recentAchievement}>
              <Icon 
                name={achievement.icon} 
                size={20} 
                color={getCategoryColor(achievement.category)} 
              />
              <Text style={styles.recentAchievementTitle}>
                {achievement.title}
              </Text>
              <Text style={styles.recentAchievementPoints}>
                +{achievement.points}
              </Text>
            </View>
          ))}
      </View>
    </ScrollView>
  );

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={[styles.header, { backgroundColor: currentLevel.color }]}>
        <Text style={styles.headerTitle}>Rewards & Achievements</Text>
        <View style={styles.headerPoints}>
          <Icon name="star" size={20} color="#FFF" />
          <Text style={styles.headerPointsText}>{currentPoints}</Text>
        </View>
      </View>

      {/* Tab Navigation */}
      <View style={styles.tabContainer}>
        <TouchableOpacity
          style={[styles.tab, selectedTab === 'overview' && styles.activeTab]}
          onPress={() => setSelectedTab('overview')}
        >
          <Icon name="view-dashboard" size={20} color={selectedTab === 'overview' ? '#FFF' : '#6B7280'} />
          <Text style={[styles.tabText, selectedTab === 'overview' && styles.activeTabText]}>
            Overview
          </Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={[styles.tab, selectedTab === 'achievements' && styles.activeTab]}
          onPress={() => setSelectedTab('achievements')}
        >
          <Icon name="trophy" size={20} color={selectedTab === 'achievements' ? '#FFF' : '#6B7280'} />
          <Text style={[styles.tabText, selectedTab === 'achievements' && styles.activeTabText]}>
            Achievements
          </Text>
        </TouchableOpacity>
        
        <TouchableOpacity
          style={[styles.tab, selectedTab === 'rewards' && styles.activeTab]}
          onPress={() => setSelectedTab('rewards')}
        >
          <Icon name="gift" size={20} color={selectedTab === 'rewards' ? '#FFF' : '#6B7280'} />
          <Text style={[styles.tabText, selectedTab === 'rewards' && styles.activeTabText]}>
            Rewards
          </Text>
        </TouchableOpacity>
      </View>

      {/* Content */}
      {selectedTab === 'overview' && renderOverview()}
      
      {selectedTab === 'achievements' && (
        <FlatList
          data={achievements}
          renderItem={renderAchievement}
          keyExtractor={(item) => item.id}
          style={styles.contentList}
          contentContainerStyle={styles.contentContainer}
          showsVerticalScrollIndicator={false}
        />
      )}
      
      {selectedTab === 'rewards' && (
        <FlatList
          data={rewards}
          renderItem={renderReward}
          keyExtractor={(item) => item.id}
          style={styles.contentList}
          contentContainerStyle={styles.contentContainer}
          showsVerticalScrollIndicator={false}
        />
      )}
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
  },
  header: {
    paddingTop: 60,
    paddingBottom: 20,
    paddingHorizontal: 20,
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    borderBottomLeftRadius: 20,
    borderBottomRightRadius: 20,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#FFF',
  },
  headerPoints: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: 'rgba(255, 255, 255, 0.2)',
    paddingHorizontal: 12,
    paddingVertical: 6,
    borderRadius: 16,
  },
  headerPointsText: {
    color: '#FFF',
    fontWeight: 'bold',
    marginLeft: 4,
  },
  tabContainer: {
    flexDirection: 'row',
    backgroundColor: '#FFF',
    margin: 16,
    borderRadius: 12,
    padding: 4,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  tab: {
    flex: 1,
    flexDirection: 'row',
    paddingVertical: 12,
    paddingHorizontal: 8,
    borderRadius: 8,
    alignItems: 'center',
    justifyContent: 'center',
  },
  activeTab: {
    backgroundColor: '#34D399',
  },
  tabText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#6B7280',
    marginLeft: 6,
  },
  activeTabText: {
    color: '#FFF',
  },
  contentList: {
    flex: 1,
  },
  contentContainer: {
    padding: 16,
  },
  overviewContainer: {
    flex: 1,
    padding: 16,
  },
  levelCard: {
    backgroundColor: '#FFF',
    borderRadius: 16,
    padding: 20,
    marginBottom: 16,
    elevation: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
  },
  levelHeader: {
    alignItems: 'center',
    marginBottom: 16,
  },
  levelTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1F2937',
  },
  levelName: {
    fontSize: 18,
    color: '#6B7280',
    marginTop: 4,
  },
  pointsContainer: {
    alignItems: 'center',
    marginBottom: 20,
  },
  currentPoints: {
    fontSize: 48,
    fontWeight: 'bold',
    color: '#34D399',
  },
  pointsLabel: {
    fontSize: 16,
    color: '#6B7280',
  },
  progressToNext: {
    marginBottom: 20,
  },
  progressBarContainer: {
    height: 8,
    backgroundColor: '#E5E7EB',
    borderRadius: 4,
    marginBottom: 8,
  },
  levelProgressFill: {
    height: '100%',
    borderRadius: 4,
  },
  nextLevelText: {
    textAlign: 'center',
    fontSize: 14,
    color: '#6B7280',
  },
  benefitsList: {
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
    paddingTop: 16,
  },
  benefitsTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1F2937',
    marginBottom: 8,
  },
  benefitItem: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 4,
  },
  statsContainer: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 16,
  },
  statCard: {
    backgroundColor: '#FFF',
    borderRadius: 12,
    padding: 16,
    flex: 1,
    marginHorizontal: 4,
    alignItems: 'center',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  statNumber: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1F2937',
    marginTop: 8,
  },
  statLabel: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 4,
  },
  sectionCard: {
    backgroundColor: '#FFF',
    borderRadius: 16,
    padding: 20,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  sectionTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1F2937',
    marginBottom: 16,
  },
  recentAchievement: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingVertical: 8,
  },
  recentAchievementTitle: {
    flex: 1,
    fontSize: 14,
    color: '#1F2937',
    marginLeft: 12,
  },
  recentAchievementPoints: {
    fontSize: 14,
    color: '#34D399',
    fontWeight: 'bold',
  },
  achievementCard: {
    backgroundColor: '#FFF',
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
    flexDirection: 'row',
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
    opacity: 0.6,
  },
  achievementUnlocked: {
    opacity: 1,
  },
  achievementIcon: {
    width: 48,
    height: 48,
    borderRadius: 24,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: 16,
  },
  achievementContent: {
    flex: 1,
  },
  achievementTitle: {
    fontSize: 16,
    fontWeight: 'bold',
    color: '#9CA3AF',
    marginBottom: 4,
  },
  achievementTitleUnlocked: {
    color: '#1F2937',
  },
  achievementDescription: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 8,
  },
  progressContainer: {
    marginBottom: 12,
  },
  progressBar: {
    height: 6,
    backgroundColor: '#E5E7EB',
    borderRadius: 3,
    marginBottom: 4,
  },
  progressFill: {
    height: '100%',
    borderRadius: 3,
  },
  progressText: {
    fontSize: 12,
    color: '#6B7280',
  },
  achievementFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  achievementPoints: {
    fontSize: 14,
    color: '#F59E0B',
    fontWeight: 'bold',
  },
  unlockedText: {
    fontSize: 12,
    color: '#10B981',
    fontWeight: 'bold',
  },
  rewardCard: {
    backgroundColor: '#FFF',
    borderRadius: 16,
    padding: 16,
    marginBottom: 16,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  rewardRedeemed: {
    opacity: 0.6,
  },
  rewardHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  rewardTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1F2937',
    marginLeft: 12,
  },
  rewardDescription: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 12,
  },
  rewardDetails: {
    marginBottom: 16,
  },
  rewardDiscount: {
    fontSize: 16,
    color: '#34D399',
    fontWeight: 'bold',
    marginBottom: 4,
  },
  rewardExpiry: {
    fontSize: 12,
    color: '#9CA3AF',
  },
  rewardFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  rewardCost: {
    fontSize: 16,
    color: '#F59E0B',
    fontWeight: 'bold',
  },
  redeemButton: {
    backgroundColor: '#34D399',
    paddingHorizontal: 20,
    paddingVertical: 8,
    borderRadius: 8,
  },
  redeemButtonDisabled: {
    backgroundColor: '#E5E7EB',
  },
  redeemButtonText: {
    color: '#FFF',
    fontWeight: 'bold',
  },
  redeemButtonTextDisabled: {
    color: '#9CA3AF',
  },
});

export default GamificationScreen;
