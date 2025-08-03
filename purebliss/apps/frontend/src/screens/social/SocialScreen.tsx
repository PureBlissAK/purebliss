import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  Image,
  TouchableOpacity,
  Modal,
  Share,
  Alert,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

interface InstagramPost {
  id: string;
  user: string;
  avatar: string;
  image: string;
  caption: string;
  likes: number;
  comments: number;
  timestamp: string;
}

interface Challenge {
  id: string;
  title: string;
  description: string;
  reward: string;
  completed: boolean;
}

const MOCK_POSTS: InstagramPost[] = [
  {
    id: '1',
    user: 'purebliss_smoothies',
    avatar: 'https://randomuser.me/api/portraits/women/44.jpg',
    image: 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=400',
    caption: 'Try our new Mango Bliss Bowl! #purebliss #smoothielove',
    likes: 128,
    comments: 12,
    timestamp: '2h ago',
  },
  {
    id: '2',
    user: 'wellness_journey',
    avatar: 'https://randomuser.me/api/portraits/men/32.jpg',
    image: 'https://images.unsplash.com/photo-1519864600265-abb23847ef2c?w=400',
    caption: 'Fueling up post-workout with Pure Bliss! #fitfam',
    likes: 89,
    comments: 7,
    timestamp: '4h ago',
  },
  {
    id: '3',
    user: 'smoothiequeen',
    avatar: 'https://randomuser.me/api/portraits/women/65.jpg',
    image: 'https://images.unsplash.com/photo-1464983953574-0892a716854b?w=400',
    caption: 'Nothing beats a berry blast on a sunny day! #berryblast',
    likes: 203,
    comments: 18,
    timestamp: '1d ago',
  },
];

const MOCK_CHALLENGES: Challenge[] = [
  {
    id: 'c1',
    title: 'Share Your Smoothie Moment',
    description: 'Post a photo with your favorite Pure Bliss smoothie and tag us!',
    reward: '+50 points',
    completed: false,
  },
  {
    id: 'c2',
    title: 'Tag a Friend',
    description: 'Tag a friend in your next order and both get a reward!',
    reward: '+30 points',
    completed: true,
  },
  {
    id: 'c3',
    title: 'Weekly Wellness',
    description: 'Complete 3 orders this week to unlock a special badge.',
    reward: 'Special Badge',
    completed: false,
  },
];

// Utility: sanitize captions (strip HTML tags)
const sanitize = (input: string): string => input.replace(/<[^>]*>?/gm, '');

// Fallback image for failed loads
const FALLBACK_IMAGE = 'https://via.placeholder.com/400x180?text=Image+Unavailable';

// Memoized post item
const PostItem = React.memo(({ post, onShare }: { post: InstagramPost; onShare: (post: InstagramPost) => void }) => {
  const [imgError, setImgError] = useState(false);
  return (
    <View style={styles.postCard} testID={`post-card-${post.id}`}>
      <View style={styles.postHeader}>
        <Image
          source={{ uri: post.avatar }}
          style={styles.avatar}
          accessibilityLabel={`${post.user} avatar`}
          onError={() => setImgError(true)}
        />
        <View style={styles.postUserInfo}>
          <Text style={styles.postUser}>{post.user}</Text>
          <Text style={styles.postTime}>{post.timestamp}</Text>
        </View>
      </View>
      <Image
        source={{ uri: imgError ? FALLBACK_IMAGE : post.image }}
        style={styles.postImage}
        accessibilityLabel={`Post image by ${post.user}`}
        onError={() => setImgError(true)}
      />
      <Text style={styles.postCaption}>{sanitize(post.caption)}</Text>
      <View style={styles.postActions}>
        <View style={styles.postStats}>
          <Icon name="heart" size={20} color="#F87171" accessibilityLabel="Likes" />
          <Text style={styles.postStatText}>{post.likes}</Text>
          <Icon name="comment" size={20} color="#60A5FA" style={{ marginLeft: 16 }} accessibilityLabel="Comments" />
          <Text style={styles.postStatText}>{post.comments}</Text>
        </View>
        <TouchableOpacity onPress={() => onShare(post)} accessibilityLabel="Share post" testID={`share-btn-${post.id}`}>
          <Icon name="share-variant" size={22} color="#34D399" />
        </TouchableOpacity>
      </View>
    </View>
  );
});
PostItem.displayName = 'PostItem';

// Memoized challenge item
const ChallengeItem = React.memo(({ challenge, onPress }: { challenge: Challenge; onPress: (c: Challenge) => void }) => (
  <TouchableOpacity
    style={[styles.challengeCard, challenge.completed && styles.challengeCompleted]}
    onPress={() => onPress(challenge)}
    disabled={challenge.completed}
    accessibilityLabel={challenge.title}
    testID={`challenge-card-${challenge.id}`}
  >
    <View style={styles.challengeInfo}>
      <Icon name={challenge.completed ? 'check-circle' : 'trophy'} size={24} color={challenge.completed ? '#34D399' : '#FBBF24'} />
      <View style={{ marginLeft: 12 }}>
        <Text style={styles.challengeTitle}>{challenge.title}</Text>
        <Text style={styles.challengeDesc}>{challenge.description}</Text>
      </View>
    </View>
    <Text style={styles.challengeReward}>{challenge.reward}</Text>
  </TouchableOpacity>
));
ChallengeItem.displayName = 'ChallengeItem';

const SocialScreen: React.FC = () => {
  const [posts, setPosts] = useState<InstagramPost[]>(MOCK_POSTS);
  const [challenges, setChallenges] = useState<Challenge[]>(MOCK_CHALLENGES);
  const [modalVisible, setModalVisible] = useState<boolean>(false);
  const [selectedChallenge, setSelectedChallenge] = useState<Challenge | null>(null);
  const [loading, setLoading] = useState<boolean>(false); // For future async fetch

  const handleShare = async (post: InstagramPost): Promise<void> => {
    try {
      await Share.share({
        message: `${sanitize(post.caption)} (via Pure Bliss App)`,
        url: post.image,
      });
    } catch (error) {
      Alert.alert('Share failed', 'Unable to share this post.');
    }
  };

  const openChallengeModal = (challenge: Challenge): void => {
    setSelectedChallenge(challenge);
    setModalVisible(true);
  };

  const closeChallengeModal = (): void => {
    setModalVisible(false);
    setSelectedChallenge(null);
  };

  const completeChallenge = (challengeId: string): void => {
    setChallenges((prev) =>
      prev.map((c) =>
        c.id === challengeId ? { ...c, completed: true } : c
      )
    );
    closeChallengeModal();
    Alert.alert('Challenge Completed!', 'You have earned a reward!');
  };

  // Loading and empty states
  if (loading) {
    return (
      <View style={[styles.container, { justifyContent: 'center', alignItems: 'center' }]}>
        <Text>Loading social feed...</Text>
      </View>
    );
  }

  return (
    <ScrollView style={styles.container}>
      <Text style={styles.header}>Social & Community</Text>
      <Text style={styles.subheader}>Instagram Feed</Text>
      {posts.length === 0 ? (
        <Text style={{ alignSelf: 'center', color: '#6B7280', marginTop: 24 }}>No posts to display.</Text>
      ) : (
        posts.map((post) => (
          <PostItem key={post.id} post={post} onShare={handleShare} />
        ))
      )}

      <Text style={styles.subheader}>Challenges</Text>
      {challenges.length === 0 ? (
        <Text style={{ alignSelf: 'center', color: '#6B7280', marginTop: 16 }}>No challenges available.</Text>
      ) : (
        challenges.map((challenge) => (
          <ChallengeItem key={challenge.id} challenge={challenge} onPress={openChallengeModal} />
        ))
      )}

      {/* Challenge Modal */}
      <Modal
        visible={modalVisible}
        animationType="slide"
        transparent
        onRequestClose={closeChallengeModal}
        accessibilityViewIsModal
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            {selectedChallenge && (
              <>
                <Text style={styles.modalTitle}>{selectedChallenge.title}</Text>
                <Text style={styles.modalDesc}>{selectedChallenge.description}</Text>
                <Text style={styles.modalReward}>Reward: {selectedChallenge.reward}</Text>
                <TouchableOpacity
                  style={styles.modalButton}
                  onPress={() => completeChallenge(selectedChallenge.id)}
                  accessibilityLabel="Mark challenge as complete"
                  testID="modal-complete-btn"
                >
                  <Text style={styles.modalButtonText}>Mark as Complete</Text>
                </TouchableOpacity>
                <TouchableOpacity
                  style={styles.modalCancel}
                  onPress={closeChallengeModal}
                  accessibilityLabel="Cancel challenge modal"
                  testID="modal-cancel-btn"
                >
                  <Text style={styles.modalCancelText}>Cancel</Text>
                </TouchableOpacity>
              </>
            )}
          </View>
        </View>
      </Modal>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#F8FAFC',
    paddingHorizontal: 0,
  },
  header: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#34D399',
    marginTop: 32,
    marginBottom: 8,
    alignSelf: 'center',
  },
  subheader: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1F2937',
    marginTop: 24,
    marginBottom: 8,
    marginLeft: 20,
  },
  postCard: {
    backgroundColor: '#FFF',
    borderRadius: 16,
    marginHorizontal: 16,
    marginBottom: 20,
    padding: 12,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 4,
    elevation: 2,
  },
  postHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  avatar: {
    width: 40,
    height: 40,
    borderRadius: 20,
    marginRight: 10,
  },
  postUserInfo: {
    flex: 1,
  },
  postUser: {
    fontWeight: 'bold',
    color: '#1F2937',
    fontSize: 15,
  },
  postTime: {
    color: '#6B7280',
    fontSize: 12,
  },
  postImage: {
    width: '100%',
    height: 180,
    borderRadius: 12,
    marginBottom: 8,
    backgroundColor: '#E5E7EB',
  },
  postCaption: {
    fontSize: 15,
    color: '#374151',
    marginBottom: 8,
  },
  postActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  postStats: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  postStatText: {
    fontSize: 14,
    color: '#6B7280',
    marginLeft: 4,
  },
  challengeCard: {
    backgroundColor: '#FFF',
    borderRadius: 14,
    marginHorizontal: 16,
    marginBottom: 14,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  challengeCompleted: {
    opacity: 0.5,
    backgroundColor: '#E5E7EB',
  },
  challengeInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  challengeTitle: {
    fontWeight: 'bold',
    fontSize: 16,
    color: '#1F2937',
    marginBottom: 2,
  },
  challengeDesc: {
    fontSize: 14,
    color: '#6B7280',
  },
  challengeReward: {
    fontWeight: '600',
    color: '#34D399',
    fontSize: 15,
    marginLeft: 12,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.3)',
    justifyContent: 'center',
    alignItems: 'center',
  },
  modalContent: {
    backgroundColor: '#FFF',
    borderRadius: 18,
    padding: 28,
    width: '80%',
    alignItems: 'center',
  },
  modalTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1F2937',
    marginBottom: 8,
    textAlign: 'center',
  },
  modalDesc: {
    fontSize: 15,
    color: '#374151',
    marginBottom: 12,
    textAlign: 'center',
  },
  modalReward: {
    fontSize: 16,
    color: '#34D399',
    fontWeight: '600',
    marginBottom: 18,
    textAlign: 'center',
  },
  modalButton: {
    backgroundColor: '#34D399',
    borderRadius: 12,
    paddingVertical: 10,
    paddingHorizontal: 24,
    marginBottom: 10,
  },
  modalButtonText: {
    color: '#FFF',
    fontWeight: 'bold',
    fontSize: 16,
  },
  modalCancel: {
    marginTop: 4,
  },
  modalCancelText: {
    color: '#6B7280',
    fontSize: 15,
  },
});

export default SocialScreen;
