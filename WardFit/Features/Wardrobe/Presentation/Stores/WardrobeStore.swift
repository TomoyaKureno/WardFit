import Combine
import Foundation

final class WardrobeStore: ObservableObject {
    @Published var wardrobeItems: [ClothingItem] = []
    @Published var savedLaterItems: [ClothingItem] = []

    private let fetchWardrobeItems: FetchWardrobeItemsUseCase
    private let seedWardrobeIfNeeded: SeedWardrobeIfNeededUseCase
    private let addWardrobeItem: AddWardrobeItemUseCase
    private let updateWardrobeItem: UpdateWardrobeItemUseCase
    private let deleteWardrobeItem: DeleteWardrobeItemUseCase
    private let saveItemForLater: SaveItemForLaterUseCase
    private let removeSavedLaterItem: RemoveSavedLaterItemUseCase
    private let moveSavedLaterItemToWardrobe: MoveSavedLaterItemToWardrobeUseCase
    private let recomputeSingleItemPairs: RecomputeSingleWardrobeItemPairsUseCase
    private let lookupItem = WardrobeItemLookupUseCase()

    init(
        repository: WardrobeRepository,
        normalizeItem: NormalizeClothingItemUseCase = NormalizeClothingItemUseCase(),
        recomputePairs: RecomputeWardrobePairsUseCase = RecomputeWardrobePairsUseCase()
    ) {
        self.fetchWardrobeItems = FetchWardrobeItemsUseCase(repository: repository)
        self.seedWardrobeIfNeeded = SeedWardrobeIfNeededUseCase(
            repository: repository,
            recomputePairs: recomputePairs
        )
        self.addWardrobeItem = AddWardrobeItemUseCase(
            repository: repository,
            normalizeItem: normalizeItem,
            recomputePairs: recomputePairs
        )
        self.updateWardrobeItem = UpdateWardrobeItemUseCase(
            repository: repository,
            normalizeItem: normalizeItem,
            recomputePairs: recomputePairs
        )
        self.deleteWardrobeItem = DeleteWardrobeItemUseCase(repository: repository)
        self.saveItemForLater = SaveItemForLaterUseCase(repository: repository)
        self.removeSavedLaterItem = RemoveSavedLaterItemUseCase(repository: repository)
        self.moveSavedLaterItemToWardrobe = MoveSavedLaterItemToWardrobeUseCase(
            repository: repository,
            normalizeItem: normalizeItem,
            recomputePairs: recomputePairs
        )
        self.recomputeSingleItemPairs = RecomputeSingleWardrobeItemPairsUseCase(
            repository: repository,
            recomputePairs: recomputePairs
        )

        seedWardrobeIfNeeded.execute()
        fetchItems()
    }

    convenience init() {
        self.init(repository: InMemoryWardrobeRepository())
    }

    func fetchItems() {
        let snapshot = fetchWardrobeItems.execute()
        wardrobeItems = snapshot.wardrobeItems
        savedLaterItems = snapshot.savedLaterItems
    }

    func addItem(_ item: ClothingItem) {
        addWardrobeItem.execute(item, wardrobeItems: wardrobeItems)
        fetchItems()
    }

    func updateItem(_ item: ClothingItem, recomputePairs: Bool = false) {
        updateWardrobeItem.execute(
            item,
            wardrobeItems: wardrobeItems,
            shouldRecomputePairs: recomputePairs
        )
        fetchItems()
    }

    func deleteItem(_ item: ClothingItem) {
        deleteWardrobeItem.execute(item, wardrobeItems: wardrobeItems)
        fetchItems()
    }

    func saveLater(_ item: ClothingItem) {
        saveItemForLater.execute(item, savedLaterItems: savedLaterItems)
        fetchItems()
    }

    func removeSavedLater(_ item: ClothingItem) {
        removeSavedLaterItem.execute(item)
        fetchItems()
    }

    func saveSavedLaterToWardrobe(_ item: ClothingItem, customName: String) {
        moveSavedLaterItemToWardrobe.execute(
            item,
            customName: customName,
            wardrobeItems: wardrobeItems
        )
        fetchItems()
    }

    func pairedItems(for item: ClothingItem) -> [ClothingItem] {
        lookupItem.pairedItems(for: item, wardrobeItems: wardrobeItems)
    }

    func item(withID id: UUID) -> ClothingItem? {
        lookupItem.item(
            withID: id,
            wardrobeItems: wardrobeItems,
            savedLaterItems: savedLaterItems
        )
    }

    func isInWardrobe(_ item: ClothingItem) -> Bool {
        lookupItem.isInWardrobe(item, wardrobeItems: wardrobeItems)
    }

    func recomputePairs(for item: ClothingItem) {
        recomputeSingleItemPairs.execute(for: item, wardrobeItems: wardrobeItems)
        fetchItems()
    }
}
