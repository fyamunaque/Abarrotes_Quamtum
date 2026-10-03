package com.abarrotes.app.ui.catalog

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.abarrotes.app.data.CatalogRepository
import com.abarrotes.app.data.model.Category
import com.abarrotes.app.data.model.Product
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class CatalogUiState(
    val categories: List<Category> = emptyList(),
    val selectedCategoryId: String? = null,
    val query: String = "",
    val products: List<Product> = emptyList(),
    val isLoading: Boolean = true,
    val isLoadingMore: Boolean = false,
    val canLoadMore: Boolean = false,
    val error: String? = null,
)

@OptIn(FlowPreview::class)
class CatalogViewModel(private val repository: CatalogRepository) : ViewModel() {

    private val _state = MutableStateFlow(CatalogUiState())
    val state: StateFlow<CatalogUiState> = _state.asStateFlow()

    private val query = MutableStateFlow("")
    private val categoryId = MutableStateFlow<String?>(null)
    private val attempt = MutableStateFlow(0) // Sube con "Reintentar" para forzar la recarga.

    private var current: Filters? = null
    private var currentPage = 0
    private var loadMoreJob: Job? = null
    private var categoriesJob: Job? = null

    private data class Filters(val query: String, val categoryId: String?, val attempt: Int)

    init {
        loadCategories()
        viewModelScope.launch {
            combine(
                query.debounce(SEARCH_DEBOUNCE_MS).map { it.trim() }.distinctUntilChanged(),
                categoryId,
                attempt,
            ) { q, category, n -> Filters(q, category, n) }
                // collectLatest: si cambian los filtros, la carga anterior se cancela.
                .collectLatest { loadFirstPage(it) }
        }
    }

    fun onQueryChange(value: String) {
        _state.update { it.copy(query = value) }
        query.value = value
    }

    /** Tocar la categoría ya seleccionada la quita (vuelve a "Todas"). */
    fun onCategorySelected(id: String?) {
        val next = if (id == categoryId.value) null else id
        _state.update { it.copy(selectedCategoryId = next) }
        categoryId.value = next
    }

    fun retry() {
        if (_state.value.categories.isEmpty()) loadCategories()
        attempt.update { it + 1 }
    }

    fun loadMore() {
        val state = _state.value
        val filters = current ?: return
        if (state.isLoading || state.isLoadingMore || !state.canLoadMore) return

        loadMoreJob = viewModelScope.launch {
            _state.update { it.copy(isLoadingMore = true, error = null) }
            repository.getProducts(filters.categoryId, filters.query, currentPage + 1)
                .onSuccess { page ->
                    currentPage = page.page
                    _state.update {
                        it.copy(
                            products = (it.products + page.products).distinctBy { p -> p.id },
                            isLoadingMore = false,
                            canLoadMore = page.page < page.totalPages,
                        )
                    }
                }
                .onFailure { e -> _state.update { it.copy(isLoadingMore = false, error = e.message) } }
        }
    }

    private suspend fun loadFirstPage(filters: Filters) {
        loadMoreJob?.cancel()
        _state.update {
            it.copy(
                isLoading = true,
                isLoadingMore = false,
                canLoadMore = false,
                products = emptyList(),
                error = null,
            )
        }
        repository.getProducts(filters.categoryId, filters.query, page = 1)
            .onSuccess { page ->
                current = filters
                currentPage = page.page
                _state.update {
                    it.copy(
                        isLoading = false,
                        products = page.products,
                        canLoadMore = page.page < page.totalPages,
                    )
                }
                // La API ya responde: si las categorías fallaron antes (p. ej. con el
                // emulador recién encendido, cuando aún no había red), se vuelven a pedir.
                if (_state.value.categories.isEmpty()) loadCategories()
            }
            .onFailure { e -> _state.update { it.copy(isLoading = false, error = e.message) } }
    }

    private fun loadCategories() {
        if (categoriesJob?.isActive == true) return
        categoriesJob = viewModelScope.launch {
            // Sin categorías el catálogo igual funciona; solo no se muestran los filtros.
            repository.getCategories().onSuccess { categories ->
                _state.update { it.copy(categories = categories) }
            }
        }
    }

    private companion object {
        const val SEARCH_DEBOUNCE_MS = 300L
    }
}
