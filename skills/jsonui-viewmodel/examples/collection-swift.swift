// CollectionDataSource Usage (Swift)
class ProductListViewModel: ObservableObject {
    @Published var data = ProductListData()

    func loadData() {
        var dataSource = CollectionDataSource()

        // Section 0: Featured items (with header)
        var featuredSection = CollectionDataSection()
        featuredSection.setHeader(viewName: "FeaturedHeader", data: ["title": "Featured"])
        featuredSection.setCells(viewName: "FeaturedCell", data: [
            ["name": "Featured 1", "image": "featured1"],
            ["name": "Featured 2", "image": "featured2"]
        ])
        dataSource.addSection(featuredSection)

        // Section 1: Products (grid with 2 columns)
        var productsSection = CollectionDataSection()
        productsSection.setCells(viewName: "ProductCell", data: [
            ["name": "Product 1", "price": 100],
            ["name": "Product 2", "price": 200],
            ["name": "Product 3", "price": 300]
        ])
        dataSource.addSection(productsSection)

        // Section 2: With footer
        var moreSection = CollectionDataSection()
        moreSection.setCells(viewName: "MoreCell", data: [
            ["text": "See more..."]
        ])
        moreSection.setFooter(viewName: "LoadMoreFooter", data: ["loading": false])
        dataSource.addSection(moreSection)

        data.collectionData = dataSource
    }

    // Refresh/reload data
    func refreshData() {
        loadData()
    }

    // Load more (pagination)
    func loadMore() {
        guard var currentSource = data.collectionData else { return }

        // Add more items to existing section
        let newItems: [[String: Any]] = [
            ["name": "Product 4", "price": 400],
            ["name": "Product 5", "price": 500]
        ]

        // Append to section 1 (products)
        if currentSource.sections.count > 1 {
            for item in newItems {
                currentSource.sections[1].addCellData(item)
            }
        }

        // Trigger update
        data.collectionData = currentSource
    }
}
