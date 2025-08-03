import React, { useState } from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TouchableOpacity,
  Alert,
  RefreshControl,
  Modal,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialCommunityIcons';

interface Order {
  id: string;
  date: string;
  items: string[];
  total: number;
  status: 'preparing' | 'ready' | 'completed' | 'cancelled';
  canCancel: boolean;
}

const MOCK_ORDERS: Order[] = [
  {
    id: 'o1',
    date: '2025-08-01',
    items: ['Tropical Paradise', 'Berry Blast'],
    total: 13.98,
    status: 'preparing',
    canCancel: true,
  },
  {
    id: 'o2',
    date: '2025-07-30',
    items: ['Green Detox'],
    total: 6.99,
    status: 'completed',
    canCancel: false,
  },
  {
    id: 'o3',
    date: '2025-07-28',
    items: ['Mango Tango', 'Acai Bowl'],
    total: 15.48,
    status: 'cancelled',
    canCancel: false,
  },
];

const statusColor = (status: Order['status']): string => {
  switch (status) {
    case 'preparing': return '#FBBF24';
    case 'ready': return '#34D399';
    case 'completed': return '#60A5FA';
    case 'cancelled': return '#F87171';
    default: return '#6B7280';
  }
};

const OrderItem = React.memo(({ order, onCancel, onReorder }: {
  order: Order;
  onCancel: (id: string) => void;
  onReorder: (id: string) => void;
}) => (
  <View style={styles.orderCard} testID={`order-card-${order.id}`}> 
    <View style={styles.orderHeader}>
      <Text style={styles.orderId}>Order #{order.id}</Text>
      <Text style={styles.orderDate}>{order.date}</Text>
    </View>
    <Text style={styles.orderItems}>{order.items.join(', ')}</Text>
    <View style={styles.orderFooter}>
      <View style={styles.statusBadge}>
        <Icon name="circle" size={12} color={statusColor(order.status)} />
        <Text style={[styles.statusText, { color: statusColor(order.status) }]}>{order.status.toUpperCase()}</Text>
      </View>
      <Text style={styles.orderTotal}>${order.total.toFixed(2)}</Text>
    </View>
    <View style={styles.orderActions}>
      {order.canCancel && (
        <TouchableOpacity
          style={styles.cancelBtn}
          onPress={() => onCancel(order.id)}
          accessibilityLabel="Cancel order"
          testID={`cancel-btn-${order.id}`}
        >
          <Icon name="close-circle" size={20} color="#F87171" />
          <Text style={styles.cancelBtnText}>Cancel</Text>
        </TouchableOpacity>
      )}
      {order.status === 'completed' && (
        <TouchableOpacity
          style={styles.reorderBtn}
          onPress={() => onReorder(order.id)}
          accessibilityLabel="Reorder"
          testID={`reorder-btn-${order.id}`}
        >
          <Icon name="repeat" size={20} color="#34D399" />
          <Text style={styles.reorderBtnText}>Reorder</Text>
        </TouchableOpacity>
      )}
    </View>
  </View>
));
OrderItem.displayName = 'OrderItem';

const OrdersScreen: React.FC = () => {
  const [orders, setOrders] = useState<Order[]>(MOCK_ORDERS);
  const [refreshing, setRefreshing] = useState<boolean>(false);
  const [modalVisible, setModalVisible] = useState<boolean>(false);
  const [selectedOrder, setSelectedOrder] = useState<Order | null>(null);

  const onRefresh = () => {
    setRefreshing(true);
    setTimeout(() => setRefreshing(false), 1000); // Simulate fetch
  };

  const handleCancel = (id: string) => {
    setSelectedOrder(orders.find(o => o.id === id) || null);
    setModalVisible(true);
  };

  const confirmCancel = () => {
    if (selectedOrder) {
      setOrders(prev => prev.map(o => o.id === selectedOrder.id ? { ...o, status: 'cancelled', canCancel: false } : o));
      setModalVisible(false);
      Alert.alert('Order Cancelled', 'Your order has been cancelled.');
    }
  };

  const handleReorder = (id: string) => {
    Alert.alert('Reorder Placed', 'Your reorder has been placed!');
  };

  if (orders.length === 0) {
    return (
      <View style={[styles.container, { justifyContent: 'center', alignItems: 'center' }]}> 
        <Text>No orders found.</Text>
      </View>
    );
  }

  return (
    <ScrollView
      style={styles.container}
      refreshControl={<RefreshControl refreshing={refreshing} onRefresh={onRefresh} />}
    >
      <Text style={styles.header}>Your Orders</Text>
      {orders.map(order => (
        <OrderItem key={order.id} order={order} onCancel={handleCancel} onReorder={handleReorder} />
      ))}
      <Modal
        visible={modalVisible}
        animationType="slide"
        transparent
        onRequestClose={() => setModalVisible(false)}
        accessibilityViewIsModal
      >
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Cancel Order?</Text>
            <Text style={styles.modalDesc}>Are you sure you want to cancel this order?</Text>
            <View style={styles.modalActions}>
              <TouchableOpacity
                style={styles.modalButton}
                onPress={confirmCancel}
                accessibilityLabel="Confirm cancel order"
                testID="modal-confirm-cancel"
              >
                <Text style={styles.modalButtonText}>Yes, Cancel</Text>
              </TouchableOpacity>
              <TouchableOpacity
                style={styles.modalCancel}
                onPress={() => setModalVisible(false)}
                accessibilityLabel="Dismiss cancel order"
                testID="modal-dismiss-cancel"
              >
                <Text style={styles.modalCancelText}>No, Keep</Text>
              </TouchableOpacity>
            </View>
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
  },
  header: {
    fontSize: 28,
    fontWeight: 'bold',
    color: '#34D399',
    marginTop: 32,
    marginBottom: 16,
    alignSelf: 'center',
  },
  orderCard: {
    backgroundColor: '#FFF',
    borderRadius: 16,
    marginHorizontal: 16,
    marginBottom: 20,
    padding: 16,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 4,
    elevation: 2,
  },
  orderHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    marginBottom: 6,
  },
  orderId: {
    fontWeight: 'bold',
    color: '#1F2937',
    fontSize: 15,
  },
  orderDate: {
    color: '#6B7280',
    fontSize: 13,
  },
  orderItems: {
    fontSize: 15,
    color: '#374151',
    marginBottom: 8,
  },
  orderFooter: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 8,
  },
  statusBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F3F4F6',
    borderRadius: 10,
    paddingHorizontal: 8,
    paddingVertical: 2,
    marginRight: 8,
  },
  statusText: {
    fontWeight: '600',
    marginLeft: 4,
    fontSize: 13,
  },
  orderTotal: {
    fontWeight: 'bold',
    color: '#34D399',
    fontSize: 16,
  },
  orderActions: {
    flexDirection: 'row',
    justifyContent: 'flex-end',
    alignItems: 'center',
    marginTop: 4,
  },
  cancelBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FEE2E2',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 6,
    marginRight: 8,
  },
  cancelBtnText: {
    color: '#F87171',
    fontWeight: '600',
    marginLeft: 4,
  },
  reorderBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#D1FAE5',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 6,
  },
  reorderBtnText: {
    color: '#34D399',
    fontWeight: '600',
    marginLeft: 4,
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
  modalActions: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    width: '100%',
    marginTop: 12,
  },
  modalButton: {
    backgroundColor: '#F87171',
    borderRadius: 12,
    paddingVertical: 10,
    paddingHorizontal: 24,
    marginRight: 8,
  },
  modalButtonText: {
    color: '#FFF',
    fontWeight: 'bold',
    fontSize: 16,
  },
  modalCancel: {
    backgroundColor: '#E5E7EB',
    borderRadius: 12,
    paddingVertical: 10,
    paddingHorizontal: 24,
  },
  modalCancelText: {
    color: '#6B7280',
    fontSize: 16,
    fontWeight: '600',
  },
});

export default OrdersScreen;
