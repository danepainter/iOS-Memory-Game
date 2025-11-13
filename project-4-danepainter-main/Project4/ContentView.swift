//  ContentView.swift
//  Project4
//
//  Created by Dane Shaw on 10/17/25.
//

import SwiftUI

struct Card: Identifiable, Equatable {
    let id = UUID()
    let content: String
    var isFaceUp: Bool = false
    var isMatched: Bool = false
}

struct ContentView: View {
    @State private var pairCount: Int = 6
    @State private var cards: [Card] = ContentView.makeShuffledDeck(pairCount: 6)
    @State private var faceUpIndices: [Int] = []
    @State private var isEvaluatingPair: Bool = false

    // 3 columns → rows of 3
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 3)

    private static let allEmojis: [String] = [
        "🐶","🐱","🦊","🐻","🐼","🐨","🐯","🦁",
        "🐮","🐷","🐸","🐵","🐔","🦆","🦉","🦄"
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(.systemIndigo).opacity(0.25),
                         Color(.systemTeal).opacity(0.25)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 16) {
                // Centered header
                HStack {
                    Spacer()
                    Text("Memory")
                        .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                        .foregroundStyle(.primary)
                        .shadow(radius: 2)
                    Spacer()
                }
                .padding(.top, 8)
                .padding(.horizontal)

                // Size on left, reset on right
                HStack {
                    Menu {
                        Button("3 pairs") { setPairCount(3) }
                        Button("6 pairs") { setPairCount(6) }
                        Button("10 pairs") { setPairCount(10) }
                    } label: {
                        Label("Size: \(pairCount)", systemImage: "square.grid.3x2")
                            .font(.headline)
                    }
                    .buttonStyle(.bordered)
                    .tint(.indigo)

                    Spacer()

                    Button {
                        resetGame()
                    } label: {
                        Label("New Game", systemImage: "arrow.clockwise.circle.fill")
                            .font(.headline)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.pink)
                }
                .padding(.horizontal)

                ScrollView {
                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(cards.indices, id: \.self) { i in
                            let card = cards[i]
                            CardView(card: card)
                                .onTapGesture { handleTap(on: i) }
                                .opacity(card.isMatched ? 0 : 1)
                                .scaleEffect(card.isMatched ? 0.6 : 1)
                                .animation(.spring(response: 0.35, dampingFraction: 0.8), value: card.isMatched)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom)
                }
            }
        }
    }

    // MARK: - Game Logic

    private func handleTap(on index: Int) {
        guard !isEvaluatingPair else { return }
        guard cards.indices.contains(index), !cards[index].isMatched else { return }
        if faceUpIndices.count == 1, faceUpIndices.first == index { return }

        if !cards[index].isFaceUp {
            withAnimation(.easeInOut(duration: 0.25)) {
                cards[index].isFaceUp = true
            }
        }

        faceUpIndices.append(index)
        if faceUpIndices.count < 2 { return }

        isEvaluatingPair = true
        let first = faceUpIndices[0]
        let second = faceUpIndices[1]

        if cards[first].content == cards[second].content {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    cards[first].isMatched = true
                    cards[second].isMatched = true
                }
                faceUpIndices.removeAll()
                isEvaluatingPair = false
            }
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
                withAnimation(.easeInOut(duration: 0.25)) {
                    if cards.indices.contains(first) { cards[first].isFaceUp = false }
                    if cards.indices.contains(second) { cards[second].isFaceUp = false }
                }
                faceUpIndices.removeAll()
                isEvaluatingPair = false
            }
        }
    }

    private func setPairCount(_ n: Int) {
        pairCount = n
        cards = Self.makeShuffledDeck(pairCount: n)
        faceUpIndices.removeAll()
        isEvaluatingPair = false
    }

    private func resetGame() {
        cards = Self.makeShuffledDeck(pairCount: pairCount)
        faceUpIndices.removeAll()
        isEvaluatingPair = false
    }

    private static func makeShuffledDeck(pairCount: Int) -> [Card] {
        let clamped = max(1, min(pairCount, allEmojis.count))
        let chosen = Array(allEmojis.shuffled().prefix(clamped))
        let deck = (chosen + chosen).map { Card(content: String($0)) }
        return deck.shuffled()
    }
}

// MARK: - CardView

struct CardView: View {
    let card: Card

    private var rotation: Double { card.isFaceUp ? 0 : 180 }

    var body: some View {
        ZStack {
            cardFront.opacity(rotation < 90 ? 1 : 0)
            cardBack.opacity(rotation >= 90 ? 1 : 0)
        }
        .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
        .animation(.easeInOut(duration: 0.35), value: card.isFaceUp)
        .accessibilityLabel(card.isFaceUp ? card.content : "Card Back")
    }

    private var cardFront: some View {
        let shape = RoundedRectangle(cornerRadius: 12)
        return ZStack {
            shape
                .fill(.ultraThinMaterial) // iOS 15+; fallback handled by type context
                .overlay(
                    shape.strokeBorder(Color.gray.opacity(0.35), lineWidth: 1)
                )
                .aspectRatio(2/3, contentMode: .fit)
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)

            LinearGradient(
                colors: [Color.white.opacity(0.55), Color.white.opacity(0.05)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .clipShape(shape)
            .aspectRatio(2/3, contentMode: .fit)
            .padding(2)

            Text(card.content)
                .font(.system(size: 36))
                .minimumScaleFactor(0.5)
        }
    }

    private var cardBack: some View {
        let shape = RoundedRectangle(cornerRadius: 12)
        return ZStack {
            shape
                .fill(Color.blue)
                .overlay(
                    shape.strokeBorder(Color.blue.opacity(0.9), lineWidth: 1)
                )
                .aspectRatio(2/3, contentMode: .fit)
                .shadow(color: .black.opacity(0.15), radius: 3, x: 0, y: 2)

            Stripes()
                .stroke(Color.white.opacity(0.12), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .clipShape(shape)
                .aspectRatio(2/3, contentMode: .fit)
                .padding(8)

            LinearGradient(
                colors: [Color.white.opacity(0.18), .clear],
                startPoint: .topLeading,
                endPoint: .center
            )
            .blendMode(.plusLighter)
            .clipShape(shape)
            .aspectRatio(2/3, contentMode: .fit)
            .padding(3)
        }
    }
}

// MARK: - Back Pattern

struct Stripes: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let spacing: CGFloat = 18
        let extra: CGFloat = max(rect.width, rect.height) * 2
        var x: CGFloat = -extra
        while x < rect.width + extra {
            path.move(to: CGPoint(x: x, y: rect.minY - extra))
            path.addLine(to: CGPoint(x: x + extra, y: rect.maxY + extra))
            x += spacing
        }
        return path
    }
}

#Preview {
    ContentView()
}
