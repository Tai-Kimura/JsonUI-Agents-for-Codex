// Event Handler Wiring (Kotlin)
init {
    _data.update { it.copy(
        onLoginTap = ::onLoginTap,
        onItemTap = ::onItemTap
    )}
}

private fun onLoginTap() {
    // Implementation
}

private fun onItemTap(item: ItemData) {
    // Implementation
}
