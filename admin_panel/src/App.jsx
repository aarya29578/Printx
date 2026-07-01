import { useEffect } from 'react'
import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { Helmet } from 'react-helmet'
import AdminShell from './components/layout/AdminShell'
import { useAuthStore } from './store/authStore'
import { useUiStore } from './store/uiStore'
import LoginPage from './pages/auth/LoginPage'
import DashboardPage from './pages/dashboard/DashboardPage'
import ProductsPage from './pages/products/ProductsPage'
import AddEditProductPage from './pages/products/AddEditProductPage'
import CategoriesPage from './pages/categories/CategoriesPage'
import CategoryDetailsPage from './pages/categories/CategoryDetailsPage'
import BannersPage from './pages/banners/BannersPage'
import AddEditBannerPage from './pages/banners/AddEditBannerPage'
import OrdersPage from './pages/orders/OrdersPage'
import OrderDetailPage from './pages/orders/OrderDetailPage'
import OrdersByCategoryPage from './pages/orders/OrdersByCategoryPage'
import OrdersByProductPage from './pages/orders/OrdersByProductPage'
import CustomersPage from './pages/customers/CustomersPage'
import CustomerDetailPage from './pages/customers/CustomerDetailPage'
import CouponsPage from './pages/coupons/CouponsPage'
import ReviewsPage from './pages/reviews/ReviewsPage'
import PushNotificationsPage from './pages/notifications/PushNotificationsPage'
import DeliverySettingsPage from './pages/delivery/DeliverySettingsPage'
import PricingRulesPage from './pages/pricing/PricingRulesPage'
import AdminUsersPage from './pages/adminUsers/AdminUsersPage'
import GeneralSettingsPage from './pages/settings/GeneralSettingsPage'
import { useProductsStore } from './store/productsStore'
import { useOrdersStore } from './store/ordersStore'
import { useCategoriesStore } from './store/categoriesStore'
import { useBannersStore } from './store/bannersStore'

function ProtectedRoute({ children }) {
  const isAuthenticated = useAuthStore((state) => state.isAuthenticated)
  return isAuthenticated ? children : <Navigate to="/login" replace />
}

export default function App() {
  const setSearchOpen = useUiStore((state) => state.setSearchOpen)
  const loadProducts = useProductsStore((state) => state.loadProducts)
  const loadOrders = useOrdersStore((state) => state.loadOrders)
  const loadCategories = useCategoriesStore((state) => state.loadCategories)
  const loadBanners = useBannersStore((state) => state.loadBanners)

  useEffect(() => {
    const handler = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === 'k') {
        e.preventDefault()
        setSearchOpen(true)
      }
      if (e.key === 'Escape') setSearchOpen(false)
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [setSearchOpen])

  useEffect(() => {
    loadProducts()
    loadOrders()
    loadCategories()
    loadBanners()
  }, [loadProducts, loadOrders, loadCategories, loadBanners])

  return (
    <>
      <Helmet>
        <title>PrintX Admin Panel</title>
      </Helmet>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <AdminShell />
              </ProtectedRoute>
            }
          >
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="dashboard" element={<DashboardPage />} />
            <Route path="products" element={<ProductsPage />} />
            <Route path="products/add" element={<AddEditProductPage />} />
            <Route path="products/:id/edit" element={<AddEditProductPage />} />
            <Route path="categories" element={<CategoriesPage />} />
            <Route path="categories/:categoryId" element={<CategoryDetailsPage />} />
            <Route path="banners" element={<BannersPage />} />
            <Route path="banners/add" element={<AddEditBannerPage />} />
            <Route path="banners/:id/edit" element={<AddEditBannerPage />} />
            <Route path="orders" element={<OrdersPage />} />
            <Route path="orders/category/:categoryId" element={<OrdersByCategoryPage />} />
            <Route path="orders/category/:categoryId/product/:productId" element={<OrdersByProductPage />} />
            <Route path="orders/:id" element={<OrderDetailPage />} />
            <Route path="customers" element={<CustomersPage />} />
            <Route path="customers/:id" element={<CustomerDetailPage />} />
            <Route path="coupons" element={<CouponsPage />} />
            <Route path="reviews" element={<ReviewsPage />} />
            <Route path="notifications" element={<PushNotificationsPage />} />
            <Route path="delivery" element={<DeliverySettingsPage />} />
            <Route path="pricing" element={<PricingRulesPage />} />
            <Route path="admin-users" element={<AdminUsersPage />} />
            <Route path="settings" element={<GeneralSettingsPage />} />
          </Route>
          <Route path="*" element={<Navigate to="/dashboard" replace />} />
        </Routes>
      </BrowserRouter>
    </>
  )
}
