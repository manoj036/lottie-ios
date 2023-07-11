// Created by Bryn Bodayle on 1/20/22.
// Copyright © 2022 Airbnb Inc. All rights reserved.

import SwiftUI

#if !os(macOS)

// MARK: - LottieView

/// A wrapper which exposes Lottie's `LottieAnimationView` to SwiftUI
@available(iOS 14.0, tvOS 14.0, *)
public struct LottieView: UIViewConfiguringSwiftUIView {

  // MARK: Lifecycle

    @State
    var position = 0

  public init(
    animation: LottieAnimation?,
    imageProvider: AnimationImageProvider? = nil,
    textProvider: AnimationTextProvider? = nil,
    fontProvider: AnimationFontProvider? = nil,
    configuration: LottieConfiguration = .shared,
    valueProviders: [String: AnyValueProvider] = [:],
    accessibilityLabel: String? = nil)
  {
    self.animation = animation
    self.imageProvider = imageProvider
    self.textProvider = textProvider
    self.fontProvider = fontProvider
    self.valueProviders = valueProviders
    self.configuration = configuration
    self.accessibilityLabel = accessibilityLabel
  }

  // MARK: Public

  public var body: some View {
    LottieAnimationView.swiftUIView {
      let view = LottieAnimationView(
        animation: animation,
        imageProvider: imageProvider,
        textProvider: textProvider ?? DefaultTextProvider(),
        fontProvider: fontProvider ?? DefaultFontProvider(),
        configuration: configuration
      )

        for (key, provider) in valueProviders {
            view.setValueProvider(provider, keypath: AnimationKeypath(keypath: key))
        }
        return view
    }
    .sizing(sizing)
    .configure { context in
      context.view.isAccessibilityElement = accessibilityLabel != nil
      context.view.accessibilityLabel = accessibilityLabel

      // We check referential equality of the animation before updating as updating the
      // animation has a side-effect of rebuilding the animation layer, and it would be
      // prohibitive to do so on every state update.
      if animation !== context.view.animation {
        context.view.animation = animation
      }

      // Technically the image provider, text provider, font provider, and Lottie configuration
      // could also need to be updated here, but there's no performant way to check their equality,
      // so we assume they are not.
    }
    .configurations(configurations)
    .onTapGesture {
        let markerCount = animation?.markers?.count ?? 0
        if position < markerCount - 1 {
            position += 1
        }
    }
    .onChange(of: position) { _ in
        playNextMarker()
    }
    .onAppear {
        playNextMarker()
    }
  }

  /// Returns a copy of this `LottieView` updated to have the given closure applied to its
  /// represented `LottieAnimationView` whenever it is updated via the `updateUIView(…)`
  /// or `updateNSView(…)` method.
  public func configure(_ configure: @escaping (LottieAnimationView) -> Void) -> Self {
    var copy = self
    copy.configurations.append { context in
      configure(context.view)
    }
    return copy
  }

  /// Returns a copy of this view that can be resized by scaling its animation to fit the size
  /// offered by its parent.
  public func resizable() -> Self {
    var copy = self
    copy.sizing = .proposed
    return copy
  }

    var next: String? {
        let markers = animation?.markers ?? []
        return position < markers.count ? markers[position].name : nil
    }

    func playNextMarker() {
        let markers = animation?.markers ?? []
        let current = markers[safe: position - 1]
        if let current {
            configurations.append { context in
                context.view.play(marker: current.name)
            }
        }
        else {
            configurations.append { context in
                context.view.play()
            }
        }
    }

    /// Returns a copy of this animation view with its `AnimationView` updated to have the provided
  /// background behavior.
  public func backgroundBehavior(_ value: LottieBackgroundBehavior) -> Self {
    configure { view in
      view.backgroundBehavior = value
    }
  }

  // MARK: Internal

    @State
  var configurations = [SwiftUIUIView<LottieAnimationView, Void>.Configuration]()

  // MARK: Private

  private let accessibilityLabel: String?
  private let animation: LottieAnimation?
  private let imageProvider: Lottie.AnimationImageProvider?
  private let textProvider: Lottie.AnimationTextProvider?
  private let fontProvider: Lottie.AnimationFontProvider?
  private let valueProviders: [String: AnyValueProvider]

  private let configuration: LottieConfiguration
  private var sizing = SwiftUIMeasurementContainerStrategy.automatic
}

#endif

extension Array {
    subscript(safe index: Index) -> Element? {
        if index < count, index >= 0 {
            return self[index]
        }
        return nil
    }
}
