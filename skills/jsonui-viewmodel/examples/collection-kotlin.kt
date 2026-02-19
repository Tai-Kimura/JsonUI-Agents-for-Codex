// CollectionDataSource Usage (Kotlin)
class ProductListViewModel : ViewModel() {
    private val _data = MutableStateFlow(ProductListData())
    val data: StateFlow<ProductListData> = _data.asStateFlow()

    fun loadData() {
        val dataSource = CollectionDataSource(
            sections = listOf(
                // Section 0: Featured items (with header)
                CollectionDataSection(
                    header = CollectionDataSection.HeaderFooterData(
                        viewName = "FeaturedHeader",
                        data = mapOf("title" to "Featured")
                    ),
                    cells = CollectionDataSection.CellData(
                        viewName = "FeaturedCell",
                        data = listOf(
                            mapOf("name" to "Featured 1", "image" to "featured1"),
                            mapOf("name" to "Featured 2", "image" to "featured2")
                        )
                    )
                ),
                // Section 1: Products
                CollectionDataSection(
                    cells = CollectionDataSection.CellData(
                        viewName = "ProductCell",
                        data = listOf(
                            mapOf("name" to "Product 1", "price" to 100),
                            mapOf("name" to "Product 2", "price" to 200),
                            mapOf("name" to "Product 3", "price" to 300)
                        )
                    ),
                    columns = 2  // Grid layout
                ),
                // Section 2: With footer
                CollectionDataSection(
                    cells = CollectionDataSection.CellData(
                        viewName = "MoreCell",
                        data = listOf(mapOf("text" to "See more..."))
                    ),
                    footer = CollectionDataSection.HeaderFooterData(
                        viewName = "LoadMoreFooter",
                        data = mapOf("loading" to false)
                    )
                )
            )
        )

        _data.update { it.copy(collectionData = dataSource) }
    }

    fun refreshData() {
        loadData()
    }

    fun loadMore() {
        val currentSource = _data.value.collectionData ?: return

        // Create new items
        val newItems = listOf(
            mapOf("name" to "Product 4", "price" to 400),
            mapOf("name" to "Product 5", "price" to 500)
        )

        // Update section 1 with appended items
        val updatedSections = currentSource.sections.mapIndexed { index, section ->
            if (index == 1) {
                section.copy(
                    cells = section.cells?.copy(
                        data = section.cells.data + newItems
                    )
                )
            } else {
                section
            }
        }

        _data.update { it.copy(collectionData = currentSource.copy(sections = updatedSections)) }
    }
}
