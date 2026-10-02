package com.abarrotes.app.ui.navigation

import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.toRoute
import com.abarrotes.app.di.AppContainer
import com.abarrotes.app.ui.auth.AuthViewModel
import com.abarrotes.app.ui.auth.LoginScreen
import com.abarrotes.app.ui.auth.RegisterScreen
import com.abarrotes.app.ui.cart.CartScreen
import com.abarrotes.app.ui.cart.CartViewModel
import com.abarrotes.app.ui.catalog.CatalogScreen
import com.abarrotes.app.ui.catalog.CatalogViewModel
import com.abarrotes.app.ui.order.MyOrdersScreen
import com.abarrotes.app.ui.order.MyOrdersViewModel
import com.abarrotes.app.ui.order.OrderPlacedScreen
import com.abarrotes.app.ui.product.ProductDetailScreen
import com.abarrotes.app.ui.product.ProductDetailViewModel
import kotlinx.serialization.Serializable
import java.math.BigDecimal

@Serializable
object CatalogRoute

@Serializable
data class ProductDetailRoute(val productId: String)

@Serializable
object CartRoute

@Serializable
object LoginRoute

@Serializable
object RegisterRoute

@Serializable
data class OrderPlacedRoute(val orderId: String, val total: String, val status: String)

@Serializable
object MyOrdersRoute

@Composable
fun AbarrotesNavHost(container: AppContainer) {
    val navController = rememberNavController()

    // Creado fuera del NavHost: queda asociado a la Activity y todas las pantallas
    // comparten el mismo carrito.
    val cartViewModel = viewModel {
        CartViewModel(container.orderRepository, container.authRepository)
    }

    NavHost(navController = navController, startDestination = CatalogRoute) {
        composable<CatalogRoute> {
            CatalogScreen(
                viewModel = viewModel { CatalogViewModel(container.catalogRepository) },
                cartViewModel = cartViewModel,
                onProductClick = { navController.navigate(ProductDetailRoute(it)) },
                onCartClick = { navController.navigate(CartRoute) },
                onMyOrdersClick = { navController.navigate(MyOrdersRoute) },
            )
        }
        composable<ProductDetailRoute> { entry ->
            val productId = entry.toRoute<ProductDetailRoute>().productId
            ProductDetailScreen(
                viewModel = viewModel { ProductDetailViewModel(productId, container.catalogRepository) },
                cartViewModel = cartViewModel,
                onBack = { navController.popBackStack() },
                onCartClick = { navController.navigate(CartRoute) },
            )
        }
        composable<CartRoute> {
            CartScreen(
                viewModel = cartViewModel,
                onBack = { navController.popBackStack() },
                onLoginRequired = { navController.navigate(LoginRoute) },
                onOrderPlaced = { order ->
                    navController.navigate(
                        OrderPlacedRoute(order.id, order.total.toPlainString(), order.status),
                    ) {
                        // Al volver desde la confirmación se llega al catálogo, no al carrito vacío.
                        popUpTo<CatalogRoute>()
                    }
                },
            )
        }
        composable<LoginRoute> {
            LoginScreen(
                viewModel = viewModel { AuthViewModel(container.authRepository) },
                onLoggedIn = { navController.popBackStack() },
                onRegisterClick = { navController.navigate(RegisterRoute) },
                onBack = { navController.popBackStack() },
            )
        }
        composable<RegisterRoute> {
            RegisterScreen(
                viewModel = viewModel { AuthViewModel(container.authRepository) },
                // Saca registro y login de la pila: vuelve a la pantalla que pidió la
                // sesión (carrito o "Mis pedidos"), sea cual sea.
                onRegistered = { navController.popBackStack<LoginRoute>(inclusive = true) },
                onBack = { navController.popBackStack() },
            )
        }
        composable<OrderPlacedRoute> { entry ->
            val route = entry.toRoute<OrderPlacedRoute>()
            OrderPlacedScreen(
                orderId = route.orderId,
                total = BigDecimal(route.total),
                status = route.status,
                onContinue = { navController.popBackStack<CatalogRoute>(inclusive = false) },
                onMyOrders = {
                    navController.navigate(MyOrdersRoute) { popUpTo<CatalogRoute>() }
                },
            )
        }
        composable<MyOrdersRoute> {
            MyOrdersScreen(
                viewModel = viewModel {
                    MyOrdersViewModel(container.orderRepository, container.authRepository)
                },
                onBack = { navController.popBackStack() },
                onLoginClick = { navController.navigate(LoginRoute) },
            )
        }
    }
}
