//
//  EmojiArtDocumentView.swift
//  Emoji Art
//
//  Created by CS193p Instructor on 5/8/23.
//  Copyright (c) 2023 Stanford University
//

import SwiftUI

struct EmojiArtDocumentView: View {
  @ObservedObject var document: EmojiArtDocument
  
  @State private var zoom: CGFloat = 1
  @State private var pan: CGSize = .zero
  
  @GestureState private var gestureZoom: CGFloat = 1
  @GestureState private var gesturePan: CGSize = .zero
  
  @State private var selectedEmojisIds: Set<EmojiArtDocument.Emoji.ID> = []
  
  private let defaultEmojiFontSize: CGFloat = 40
  
  var body: some View {
    VStack(spacing: 0) {
      documentBody
      PaletteChooser()
        .font(.system(size: defaultEmojiFontSize))
        .padding(.horizontal)
        .scrollIndicators(.hidden)
    }
  }
  
  private var documentBody: some View {
    GeometryReader { geometry in
      ZStack {
        Color.white
        documentContents(in: geometry)
          .scaleEffect(zoom * gestureZoom)
          .offset(pan + gesturePan)
      }
      .gesture(panGesture.simultaneously(with: zoomGesture))
      .dropDestination(for: Sturldata.self) { sturldatas, location in
        return drop(sturldatas, at: location, in: geometry)
      }
    }
  }
  
  @ViewBuilder
  private func documentContents(in geometry: GeometryProxy) -> some View {
    AsyncImage(url: document.background)
      .position(EmojiArtDocument.Emoji.Position.zero.in(geometry))
    
    ForEach(document.emojis) { emoji in
      Text(emoji.string)
        .font(emoji.font)
        .position(emoji.position.in(geometry))
        .gesture(emojiDragGesture(for: emoji).simultaneously(with: emojiMagnificationGesture(for: emoji)))
      
        .onTapGesture {
          toggleEmojiSelection(emoji)
        }
        .onLongPressGesture {
          if isEmojiSelected(emoji) {
            document.removeEmoji(emoji)
          }
        }
        .opacity(isEmojiSelected(emoji) ? 0.5 : 1)
    }
  }
  
  private func isEmojiSelected(_ emoji: EmojiArtDocument.Emoji) -> Bool {
    selectedEmojisIds.contains(emoji.id)
  }
  
  private func toggleEmojiSelection(_ emoji: EmojiArtDocument.Emoji) {
    if selectedEmojisIds.contains(emoji.id) {
      selectedEmojisIds.remove(emoji.id)
    } else {
      selectedEmojisIds.insert(emoji.id)
    }
  }
  
  private func emojiDragGesture(for emoji: EmojiArtDocument.Emoji) -> some Gesture {
    DragGesture()
      .onChanged { value in
        document.move(emoji, by: value.translation)
      }
  }
  
  private func emojiMagnificationGesture(for emoji: EmojiArtDocument.Emoji) -> some Gesture {
    MagnificationGesture()
      .onChanged { scale in
        document.resize(emoji, by: scale)
      }
  }
  
  private var zoomGesture: some Gesture {
    MagnificationGesture()
      .updating($gestureZoom) { inMotionPinchScale, gestureZoom, _ in
        gestureZoom = inMotionPinchScale
      }
      .onEnded { endingPinchScale in
        zoom *= endingPinchScale
      }
  }
  
  private var panGesture: some Gesture {
    DragGesture()
      .updating($gesturePan) { inMotionDragGestureValue, gesturePan, _ in
        gesturePan = inMotionDragGestureValue.translation
      }
      .onEnded { endingDragGestureValue in
        pan += endingDragGestureValue.translation
      }
  }
  
  private func drop(_ sturldatas: [Sturldata], at location: CGPoint, in geometry: GeometryProxy) -> Bool {
    for sturldata in sturldatas {
      switch sturldata {
      case .url(let url):
        document.setBackground(url)
        return true
      case .string(let emoji):
        document.addEmoji(
          emoji,
          at: emojiPosition(at: location, in: geometry),
          size: defaultEmojiFontSize / zoom
        )
        return true
      default:
        break
      }
    }
    return false
  }

  private func emojiPosition(at location: CGPoint, in geometry: GeometryProxy) -> EmojiArtDocument.Emoji.Position {
    let center = geometry.frame(in: .local).center
    return EmojiArtDocument.Emoji.Position(
      x: Int((location.x - center.x - pan.width) / zoom),
      y: Int(-(location.y - center.y - pan.height) / zoom)
    )
  }
}

struct EmojiArtDocumentView_Previews: PreviewProvider {
  static var previews: some View {
    EmojiArtDocumentView(document: EmojiArtDocument())
      .environmentObject(PaletteStore(named: "Preview"))
  }
}
