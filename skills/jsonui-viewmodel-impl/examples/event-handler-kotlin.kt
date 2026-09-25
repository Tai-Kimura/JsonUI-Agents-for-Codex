// Event Handler Wiring (Kotlin)
init {
    _data.update { it.copy(
        onLoginTap = ::onLoginTap,
        onItemTap = ::onItemTap
    )}
}

fun onLoginTap() {
    // Implementation
}

fun onItemTap(item: ItemData) {
    // Implementation
}
