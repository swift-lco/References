import DSL

public extension ReferenceProviding {
    /// The key a citation of this reference carries in `StructuredContent`.
    var citationKey: StructuredContent.CitationKey {
        .init(rawValue: public_name_or_id)
    }

    /// This reference cited inline, for prose:
    /// `"…\(Cynology.References.ader2019.citation(at: .page("12")))"`.
    func citation(
        at locators: ReferenceLocator...
    ) -> StructuredContent.Inline {
        .citation(
            key: citationKey,
            locators: locators
        )
    }
}

public extension ReferenceGroup {
    /// Every reference of the group cited at this point, in order.
    var citations: InlineText {
        InlineText(
            references.map { $0.citation() }
        )
    }
}

public extension InlineText.StringInterpolation {
    /// `\(cite: Cynology.References.ader2019, at: .init(.page, "12"))`.
    mutating func appendInterpolation(
        cite reference: some ReferenceProviding,
        at locators: ReferenceLocator...
    ) {
        appendInterpolation(
            .citation(
                key: reference.citationKey,
                locators: locators
            )
        )
    }
}

/// Bibliography entries from reference libraries, for the enumeration pass.
/// Keys it doesn't know print as the key.
public struct ReferenceBibliography:
    StructuredContentBibliographyProviding
{
    public var style: ReferenceFormatStyle
    private var references: [StructuredContent.CitationKey: any ReferenceProviding] = [:]

    public init(
        _ references: [any ReferenceProviding] = [],
        style: ReferenceFormatStyle = .compact
    ) {
        self.style = style

        for reference in references {
            self.references[reference.citationKey] = reference
        }
    }

    /// Adds every case of a reference library.
    public func adding<Library: ReferenceProviding>(
        _ library: Library.Type
    ) -> Self {
        var copy = self

        for reference in library.allCases {
            copy.references[reference.citationKey] = reference
        }

        return copy
    }

    public func entry(
        _ key: StructuredContent.CitationKey
    ) -> StructuredContent? {
        guard let reference = references[key] else {
            return nil
        }

        let text = StructuredContent.Inline.text(reference.formatted(style))

        guard !reference.url.isEmpty else {
            return .paragraph([text])
        }

        return .paragraph([
            .link(
                target: .external(reference.url),
                content: [text]
            ),
        ])
    }
}
