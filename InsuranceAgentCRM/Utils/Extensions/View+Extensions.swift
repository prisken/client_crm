import SwiftUI

extension View {
    // MARK: - Conditional Modifiers
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func `if`<TrueContent: View, FalseContent: View>(
        _ condition: Bool,
        if trueTransform: (Self) -> TrueContent,
        else falseTransform: (Self) -> FalseContent
    ) -> some View {
        if condition {
            trueTransform(self)
        } else {
            falseTransform(self)
        }
    }
    
    // MARK: - Loading States
    func loadingOverlay(_ isLoading: Bool) -> some View {
        self.overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        )
                }
            }
        )
    }
    
    // MARK: - Error States
    func errorOverlay(_ error: String?) -> some View {
        self.overlay(
            Group {
                if let error = error {
                    VStack {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.title)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        )
    }
    
    // MARK: - Card Styles
    func cardStyle() -> some View {
        self
            .background(Color.backgroundSecondary)
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    func primaryCardStyle() -> some View {
        self
            .background(Color.backgroundPrimary)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Button Styles
    func primaryButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding()
            .background(Color.brandPrimary)
            .cornerRadius(8)
    }
    
    func secondaryButtonStyle() -> some View {
        self
            .foregroundColor(.brandPrimary)
            .padding()
            .background(Color.brandPrimary.opacity(0.1))
            .cornerRadius(8)
    }
    
    func destructiveButtonStyle() -> some View {
        self
            .foregroundColor(.white)
            .padding()
            .background(Color.statusError)
            .cornerRadius(8)
    }
    
    // MARK: - Animation Helpers
    func animateOnAppear() -> some View {
        self
            .opacity(0)
            .scaleEffect(0.9)
            .onAppear {
                withAnimation(.easeOut(duration: 0.3)) {
                    // Animation will be handled by the view itself
                }
            }
    }
    
    // MARK: - Accessibility
    func accessibilityLabel(_ label: String) -> some View {
        self.accessibility(label: Text(label))
    }
    
    func accessibilityHint(_ hint: String) -> some View {
        self.accessibility(hint: Text(hint))
    }
    
    // MARK: - Keyboard Handling
    func hideKeyboard() -> some View {
        self.onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }
    
    // MARK: - Safe Area
    func ignoreSafeArea(_ edges: Edge.Set = .all) -> some View {
        self.ignoresSafeArea(.container, edges: edges)
    }
    
    // MARK: - Navigation
    func navigationBarTitle(_ title: String, displayMode: NavigationBarItem.TitleDisplayMode = .large) -> some View {
        self.navigationTitle(title)
            .navigationBarTitleDisplayMode(displayMode)
    }
    
    // MARK: - Responsive Layout
    @ViewBuilder
    func adaptiveLayout<Compact: View, Regular: View>(
        @ViewBuilder compact: () -> Compact,
        @ViewBuilder regular: () -> Regular
    ) -> some View {
        if DeviceInfo.isCompactWidth {
            compact()
        } else {
            regular()
        }
    }
    
    @ViewBuilder
    func phoneOnly<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if DeviceInfo.isIPhone {
            content()
        }
    }
    
    @ViewBuilder
    func iPadOnly<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        if DeviceInfo.isIPad {
            content()
        }
    }
    
    // MARK: - Mobile Optimized Modifiers
    func mobilePadding() -> some View {
        self.padding(DeviceInfo.mobilePadding)
    }
    
    func mobileCardStyle() -> some View {
        self
            .padding(DeviceInfo.mobileCardPadding)
            .background(Color(.systemBackground))
            .cornerRadius(DeviceInfo.mobileCornerRadius)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    func mobileButtonStyle(_ style: MobileButtonStyle = .primary) -> some View {
        self
            .frame(height: DeviceInfo.mobileButtonHeight)
            .frame(maxWidth: .infinity)
            .background(style.backgroundColor)
            .foregroundColor(style.foregroundColor)
            .cornerRadius(DeviceInfo.mobileCornerRadius)
            .font(.system(size: 16 * DeviceInfo.mobileFontScale, weight: .medium))
    }
    
    func mobileTouchTarget() -> some View {
        self
            .frame(minHeight: DeviceInfo.mobileTouchTarget)
            .contentShape(Rectangle())
    }
    
    func mobileSpacing() -> some View {
        self.padding(.vertical, DeviceInfo.mobileSpacing / 2)
    }
    
    func mobileTitle() -> some View {
        self
            .font(.system(size: 24 * DeviceInfo.mobileFontScale, weight: .bold))
            .foregroundColor(.primary)
    }
    
    func mobileSubtitle() -> some View {
        self
            .font(.system(size: 18 * DeviceInfo.mobileFontScale, weight: .semibold))
            .foregroundColor(.secondary)
    }
    
    func mobileBody() -> some View {
        self
            .font(.system(size: 16 * DeviceInfo.mobileFontScale))
            .foregroundColor(.primary)
    }
    
    func mobileCaption() -> some View {
        self
            .font(.system(size: 14 * DeviceInfo.mobileFontScale))
            .foregroundColor(.secondary)
    }
}

// MARK: - Mobile Button Styles
enum MobileButtonStyle {
    case primary, secondary, destructive
    
    var backgroundColor: Color {
        switch self {
        case .primary: return .blue
        case .secondary: return Color(.systemGray5)
        case .destructive: return .red
        }
    }
    
    var foregroundColor: Color {
        switch self {
        case .primary: return .white
        case .secondary: return .primary
        case .destructive: return .white
        }
    }
}

// MARK: - View Modifiers
struct CardModifier: ViewModifier {
    let cornerRadius: CGFloat
    let shadowRadius: CGFloat
    let shadowOpacity: Double
    
    init(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 2, shadowOpacity: Double = 0.1) {
        self.cornerRadius = cornerRadius
        self.shadowRadius = shadowRadius
        self.shadowOpacity = shadowOpacity
    }
    
    func body(content: Content) -> some View {
        content
            .background(Color.backgroundSecondary)
            .cornerRadius(cornerRadius)
            .shadow(color: .black.opacity(shadowOpacity), radius: shadowRadius, x: 0, y: 1)
    }
}

struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    
    func body(content: Content) -> some View {
        content.overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.3)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(1.2)
                        )
                }
            }
        )
    }
}

// MARK: - View Extensions for Modifiers
extension View {
    func card(cornerRadius: CGFloat = 12, shadowRadius: CGFloat = 2, shadowOpacity: Double = 0.1) -> some View {
        self.modifier(CardModifier(cornerRadius: cornerRadius, shadowRadius: shadowRadius, shadowOpacity: shadowOpacity))
    }
    
    func loading(_ isLoading: Bool) -> some View {
        self.modifier(LoadingModifier(isLoading: isLoading))
    }
}
