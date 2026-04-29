import SwiftUI

struct AboutInfoView: View {
    private let linkColor = Color.primary.opacity(0.75)
    private let authorURL = URL(string: "https://github.com/GrantBirki")

    var body: some View {
        HStack(spacing: 4) {
            Text("Made by")
            if let authorURL {
                Link("GrantBirki", destination: authorURL)
                    .foregroundStyle(linkColor)
                    .tint(linkColor)
                    .underline()
            } else {
                Text("GrantBirki")
            }
            Text("•")
            Text(BuildInfo.displayVersion)
            Text("•")
            if let sha = BuildInfo.gitSHA,
               let url = URL(string: "https://github.com/GrantBirki/shit/tree/\(sha)")
            {
                Text("commit")
                Link(BuildInfo.shortGitSHA, destination: url)
                    .foregroundStyle(linkColor)
                    .tint(linkColor)
                    .underline()
            } else {
                Text("commit \(BuildInfo.shortGitSHA)")
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct AboutView: View {
    private let linkColor = Color.primary.opacity(0.75)
    private let sourceURL = URL(string: "https://github.com/GrantBirki/shit")

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 36, weight: .regular))
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityLabel("Shit calendar icon")

            Text("Shit")
                .font(.title2)
                .fontWeight(.semibold)

            Text("A local Calendar alert app. Oh shit I missed another meeting!")
                .font(.footnote)
                .foregroundStyle(.secondary)

            AboutInfoView()

            if let sourceURL {
                Link("Source code", destination: sourceURL)
                    .font(.footnote)
                    .foregroundStyle(linkColor)
                    .tint(linkColor)
                    .underline()
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}
