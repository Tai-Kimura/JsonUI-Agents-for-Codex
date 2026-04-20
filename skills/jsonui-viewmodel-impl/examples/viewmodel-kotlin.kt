// Kotlin ViewModel Pattern (Compose)
class LoginViewModel : ViewModel() {
    private val _data = MutableStateFlow(LoginData())
    val data: StateFlow<LoginData> = _data.asStateFlow()

    // >>> GENERATED_CODE_START
    // ⛔ DO NOT EDIT between GENERATED_CODE markers - auto-updated by 'kjui build'
    fun updateData(updates: Map<String, Any>) {
        // ... auto-generated code
    }
    // >>> GENERATED_CODE_END

    init {
        _data.update { it.copy(
            onLoginTap = ::onLoginTap,
            onRegisterTap = ::onRegisterTap
        )}
    }

    private fun onLoginTap() {
        if (!validateInput()) return
        // TODO: Call login API
    }

    private fun onRegisterTap() {
        // TODO: Navigate to register
    }

    private fun validateInput(): Boolean {
        val currentData = _data.value
        if (currentData.email.isNullOrEmpty()) {
            // Show error
            return false
        }
        return true
    }
}
