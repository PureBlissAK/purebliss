import React, { useState, useEffect } from 'react';
import { 
  View, 
  Text, 
  StyleSheet, 
  FlatList, 
  TouchableOpacity, 
  Image, 
  TextInput,
  ScrollView 
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

interface MenuItem {
  id: string;
  name: string;
  description: string;
  price: number;
  category: 'tropical' | 'protein' | 'detox' | 'classic';
  image: string;
  ingredients: string[];
  calories: number;
  isVegan: boolean;
  isGlutenFree: boolean;
}

const MENU_ITEMS: MenuItem[] = [
  {
    id: '1',
    name: 'Tropical Paradise',
    description: 'Mango, pineapple, coconut milk, and lime',
    price: 8.50,
    category: 'tropical',
    image: 'https://images.unsplash.com/photo-1505252585461-04db1eb84625?w=300&h=300&fit=crop',
    ingredients: ['Mango', 'Pineapple', 'Coconut Milk', 'Lime', 'Honey'],
    calories: 250,
    isVegan: true,
    isGlutenFree: true,
  },
  {
    id: '2',
    name: 'Green Goddess',
    description: 'Spinach, banana, apple, ginger, and coconut water',
    price: 9.00,
    category: 'detox',
    image: 'https://images.unsplash.com/photo-1610970881699-44a5587cabec?w=300&h=300&fit=crop',
    ingredients: ['Spinach', 'Banana', 'Green Apple', 'Ginger', 'Coconut Water'],
    calories: 180,
    isVegan: true,
    isGlutenFree: true,
  },
  {
    id: '3',
    name: 'Protein Power',
    description: 'Vanilla protein, banana, almond butter, oat milk',
    price: 10.50,
    category: 'protein',
    image: 'https://images.unsplash.com/photo-1578662996442-48f60103fc96?w=300&h=300&fit=crop',
    ingredients: ['Vanilla Protein', 'Banana', 'Almond Butter', 'Oat Milk', 'Dates'],
    calories: 320,
    isVegan: true,
    isGlutenFree: false,
  },
  {
    id: '4',
    name: 'Berry Bliss',
    description: 'Mixed berries, yogurt, honey, and granola',
    price: 8.00,
    category: 'classic',
    image: 'https://images.unsplash.com/photo-1564093497595-593f96d80180?w=300&h=300&fit=crop',
    ingredients: ['Strawberries', 'Blueberries', 'Greek Yogurt', 'Honey', 'Granola'],
    calories: 280,
    isVegan: false,
    isGlutenFree: false,
  },
  {
    id: '5',
    name: 'Açaí Energy',
    description: 'Açaí, banana, guarana, and coconut flakes',
    price: 9.50,
    category: 'tropical',
    image: 'https://images.unsplash.com/photo-1571771894821-ce9b6c11b08e?w=300&h=300&fit=crop',
    ingredients: ['Açaí', 'Banana', 'Guarana', 'Coconut Flakes', 'Agave'],
    calories: 220,
    isVegan: true,
    isGlutenFree: true,
  },
];

const CATEGORIES = [
  { id: 'all', name: 'All', icon: 'food-apple' },
  { id: 'tropical', name: 'Tropical', icon: 'palm-tree' },
  { id: 'protein', name: 'Protein', icon: 'dumbbell' },
  { id: 'detox', name: 'Detox', icon: 'leaf' },
  { id: 'classic', name: 'Classic', icon: 'heart' },
];

const MenuScreen: React.FC = () => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [menuItems, setMenuItems] = useState<MenuItem[]>(MENU_ITEMS);
  const [cartItems, setCartItems] = useState<{[key: string]: number}>({});

  useEffect(() => {
    let filtered = MENU_ITEMS;
    
    if (selectedCategory !== 'all') {
      filtered = filtered.filter(item => item.category === selectedCategory);
    }
    
    if (searchQuery) {
      filtered = filtered.filter(item => 
        item.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
        item.description.toLowerCase().includes(searchQuery.toLowerCase())
      );
    }
    
    setMenuItems(filtered);
  }, [searchQuery, selectedCategory]);

  const addToCart = (itemId: string) => {
    setCartItems(prev => ({
      ...prev,
      [itemId]: (prev[itemId] || 0) + 1
    }));
  };

  const removeFromCart = (itemId: string) => {
    setCartItems(prev => ({
      ...prev,
      [itemId]: Math.max((prev[itemId] || 0) - 1, 0)
    }));
  };

  const renderMenuItem = ({ item }: { item: MenuItem }) => (
    <View style={styles.menuItem}>
      <Image source={{ uri: item.image }} style={styles.itemImage} />
      <View style={styles.itemDetails}>
        <View style={styles.itemHeader}>
          <Text style={styles.itemName}>{item.name}</Text>
          <View style={styles.itemBadges}>
            {item.isVegan && <Text style={styles.veganBadge}>🌱</Text>}
            {item.isGlutenFree && <Text style={styles.gfBadge}>GF</Text>}
          </View>
        </View>
        <Text style={styles.itemDescription}>{item.description}</Text>
        <Text style={styles.itemCalories}>{item.calories} calories</Text>
        <View style={styles.itemFooter}>
          <Text style={styles.itemPrice}>${item.price.toFixed(2)}</Text>
          <View style={styles.cartControls}>
            {cartItems[item.id] > 0 && (
              <TouchableOpacity onPress={() => removeFromCart(item.id)} style={styles.cartButton}>
                <Icon name="minus" size={20} color="#FF6B6B" />
              </TouchableOpacity>
            )}
            {cartItems[item.id] > 0 && (
              <Text style={styles.cartQuantity}>{cartItems[item.id]}</Text>
            )}
            <TouchableOpacity onPress={() => addToCart(item.id)} style={styles.cartButton}>
              <Icon name="plus" size={20} color="#34D399" />
            </TouchableOpacity>
          </View>
        </View>
      </View>
    </View>
  );

  const renderCategory = ({ item }: { item: typeof CATEGORIES[0] }) => (
    <TouchableOpacity
      style={[
        styles.categoryButton,
        selectedCategory === item.id && styles.selectedCategory
      ]}
      onPress={() => setSelectedCategory(item.id)}
    >
      <Icon 
        name={item.icon} 
        size={24} 
        color={selectedCategory === item.id ? '#FFF' : '#34D399'} 
      />
      <Text style={[
        styles.categoryText,
        selectedCategory === item.id && styles.selectedCategoryText
      ]}>
        {item.name}
      </Text>
    </TouchableOpacity>
  );

  const totalCartItems = Object.values(cartItems).reduce((sum, qty) => sum + qty, 0);
  const totalCartValue = Object.entries(cartItems).reduce((sum, [itemId, qty]) => {
    const item = MENU_ITEMS.find(i => i.id === itemId);
    return sum + (item ? item.price * qty : 0);
  }, 0);

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <Text style={styles.headerTitle}>Pure Bliss Menu</Text>
        <Text style={styles.headerSubtitle}>Fresh • Healthy • Delicious</Text>
      </View>

      {/* Search Bar */}
      <View style={styles.searchContainer}>
        <Icon name="magnify" size={20} color="#666" style={styles.searchIcon} />
        <TextInput
          style={styles.searchInput}
          placeholder="Search smoothies..."
          value={searchQuery}
          onChangeText={setSearchQuery}
          placeholderTextColor="#999"
        />
      </View>

      {/* Categories */}
      <FlatList
        data={CATEGORIES}
        renderItem={renderCategory}
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.categoriesList}
        contentContainerStyle={styles.categoriesContent}
      />

      {/* Menu Items */}
      <FlatList
        data={menuItems}
        renderItem={renderMenuItem}
        keyExtractor={(item) => item.id}
        style={styles.menuList}
        contentContainerStyle={styles.menuContent}
        showsVerticalScrollIndicator={false}
      />

      {/* Cart Summary */}
      {totalCartItems > 0 && (
        <View style={styles.cartSummary}>
          <View style={styles.cartInfo}>
            <Text style={styles.cartText}>
              {totalCartItems} item{totalCartItems > 1 ? 's' : ''} • ${totalCartValue.toFixed(2)}
            </Text>
          </View>
          <TouchableOpacity style={styles.checkoutButton}>
            <Text style={styles.checkoutText}>View Cart</Text>
            <Icon name="cart" size={20} color="#FFF" />
          </TouchableOpacity>
        </View>
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
    backgroundColor: '#34D399',
    paddingTop: 60,
    paddingBottom: 20,
    paddingHorizontal: 20,
    borderBottomLeftRadius: 20,
    borderBottomRightRadius: 20,
  },
  headerTitle: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#FFF',
    textAlign: 'center',
  },
  headerSubtitle: {
    fontSize: 16,
    color: '#FFF',
    textAlign: 'center',
    marginTop: 4,
    opacity: 0.9,
  },
  searchContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    margin: 16,
    borderRadius: 12,
    paddingHorizontal: 16,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 4,
  },
  searchIcon: {
    marginRight: 8,
  },
  searchInput: {
    flex: 1,
    height: 48,
    fontSize: 16,
  },
  categoriesList: {
    marginVertical: 8,
  },
  categoriesContent: {
    paddingHorizontal: 16,
  },
  categoryButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFF',
    paddingHorizontal: 16,
    paddingVertical: 8,
    borderRadius: 20,
    marginRight: 12,
    borderWidth: 1,
    borderColor: '#34D399',
  },
  selectedCategory: {
    backgroundColor: '#34D399',
  },
  categoryText: {
    marginLeft: 8,
    fontSize: 14,
    fontWeight: '600',
    color: '#34D399',
  },
  selectedCategoryText: {
    color: '#FFF',
  },
  menuList: {
    flex: 1,
  },
  menuContent: {
    padding: 16,
  },
  menuItem: {
    backgroundColor: '#FFF',
    borderRadius: 16,
    marginBottom: 16,
    elevation: 3,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.1,
    shadowRadius: 8,
    overflow: 'hidden',
  },
  itemImage: {
    width: '100%',
    height: 200,
    resizeMode: 'cover',
  },
  itemDetails: {
    padding: 16,
  },
  itemHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  itemName: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1F2937',
    flex: 1,
  },
  itemBadges: {
    flexDirection: 'row',
  },
  veganBadge: {
    fontSize: 16,
    marginRight: 4,
  },
  gfBadge: {
    backgroundColor: '#FEF3C7',
    color: '#D97706',
    fontSize: 10,
    fontWeight: 'bold',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 8,
  },
  itemDescription: {
    fontSize: 14,
    color: '#6B7280',
    marginBottom: 8,
    lineHeight: 20,
  },
  itemCalories: {
    fontSize: 12,
    color: '#9CA3AF',
    marginBottom: 12,
  },
  itemFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  itemPrice: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#34D399',
  },
  cartControls: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  cartButton: {
    width: 32,
    height: 32,
    borderRadius: 16,
    backgroundColor: '#F3F4F6',
    justifyContent: 'center',
    alignItems: 'center',
  },
  cartQuantity: {
    marginHorizontal: 12,
    fontSize: 16,
    fontWeight: 'bold',
    color: '#1F2937',
  },
  cartSummary: {
    backgroundColor: '#FFF',
    flexDirection: 'row',
    alignItems: 'center',
    padding: 16,
    borderTopWidth: 1,
    borderTopColor: '#E5E7EB',
  },
  cartInfo: {
    flex: 1,
  },
  cartText: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1F2937',
  },
  checkoutButton: {
    backgroundColor: '#34D399',
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 20,
    paddingVertical: 12,
    borderRadius: 8,
  },
  checkoutText: {
    color: '#FFF',
    fontWeight: 'bold',
    marginRight: 8,
  },
});

export default MenuScreen;
