// CollectionDataSource Usage (Swift)
class ProductListViewModel: ObservableObject {
    @Published var data = ProductListData()

    func loadData() {
        let dataSource = CollectionDataSource()

        // Section 0: Featured items (with header)
        let featuredSection = dataSource.addSection()
        featuredSection.setHeader(viewName: "FeaturedHeader", data: ["title": "Featured"])
        featuredSection.setCells(viewName: "FeaturedCell", data: [
            ["name": "Featured 1", "image": "featured1"],
            ["name": "Featured 2", "image": "featured2"]
        ])

        // Section 1: Products (grid with 2 columns)
        let productsSection = dataSource.addSection()
        productsSection.setCells(viewName: "ProductCell", data: [
            ["name": "Product 1", "price": 100],
            ["name": "Product 2", "price": 200],
            ["name": "Product 3", "price": 300]
        ])

        // Section 2: With footer
        let moreSection = dataSource.addSection()
        moreSection.setCells(viewName: "MoreCell", data: [
            ["text": "See more..."]
        ])
        moreSection.setFooter(viewName: "LoadMoreFooter", data: ["loading": false])

        data.collectionData = dataSource
    }

    // Refresh/reload data
    func refreshData() {
        loadData()
    }

    // Load more (pagination)
    func loadMore() {
        guard let currentSource = data.collectionData else { return }

        // Add more items to existing section
        let newItems: [[String: Any]] = [
            ["name": "Product 4", "price": 400],
            ["name": "Product 5", "price": 500]
        ]

        // Append to section 1 (products)
        if currentSource.sections.count > 1 {
            let section = currentSource.sections[1]
            section.appendCells(data: newItems)
        }

        // Trigger update
        data.collectionData = currentSource
    }
}
